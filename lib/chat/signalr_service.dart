import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../core/token_manager.dart';
import '../core/api_client.dart';
import 'chat.dart';

typedef TradeOfferUpdateHandler = void Function(Map<String, dynamic> data);

class SignalRService {
  // 싱글톤 패턴 구현
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  // 허브 연결 객체
  HubConnection? _hubConnection;

  // 메시지 스트림 컨트롤러 (여러 구독자를 위해 broadcast로 생성)
  final StreamController<ChatMessage> _messageStreamController =
      StreamController<ChatMessage>.broadcast();

  // 연결 상태
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // 메시지 스트림 getter
  Stream<ChatMessage> get messageStream => _messageStreamController.stream;

  // 현재 채팅방 ID
  int _currentRoomId = 0;

  // 현재 발신자(본인) 이름
  String _callerName = '';

  // 메시지 캐시 (채팅방 ID를 키로 사용)
  final Map<int, List<ChatMessage>> _messageCache = {};

  // 상품 정보 업데이트 알림 처리 함수 타입 정의

  // 상품 정보 업데이트 핸들러
  TradeOfferUpdateHandler? _tradeOfferUpdateHandler;

  // 상품 정보 업데이트 핸들러 등록 함수
  void registerTradeOfferUpdateHandler(TradeOfferUpdateHandler? handler) {
    _tradeOfferUpdateHandler = handler;
  }

  // 초기화 함수
  Future<void> initialize() async {
    if (_hubConnection != null) return;

    try {
      // API 클라이언트에서 서버 URL 가져오기
      final String baseUrl = ApiClient().getDomain;
      final String hubUrl = '$baseUrl/chathub';

      // 로깅 설정
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        print('SignalR (${record.level.name}): ${record.message}');
      });

      // 연결 옵션 설정
      final httpConnectionOptions = HttpConnectionOptions(
        logger: Logger("SignalRLogger"),
        logMessageContent: true,
        accessTokenFactory:
            () async => await TokenManager.getToken() ?? "", // 토큰을 가져오는 비동기 함수
      );

      // 허브 연결 객체 생성
      _hubConnection =
          HubConnectionBuilder()
              .withUrl(hubUrl, options: httpConnectionOptions)
              .withAutomaticReconnect()
              .build();

      // 이벤트 핸들러 등록
      _registerEventHandlers();
    } catch (e) {
      print('SignalR 초기화 오류: $e');
      rethrow;
    }
  }

  // 이벤트 핸들러 등록
  void _registerEventHandlers() {
    // 메시지 수신 핸들러 - example_signalr_test_page.dart의 이벤트 이름 사용
    _hubConnection?.on("_handleIncomingMessage", (arguments) {
      if (arguments == null || arguments.isEmpty) return;
      try {
        final messageData = arguments[0] as Map<String, dynamic>;
        print('메시지 수신: $messageData'); // 디버깅용

        // 채팅방 ID 확인 (서버 응답에 맞게 조정 필요)
        final int roomId = messageData['roomId'] ?? _currentRoomId;

        // 발신자 이름 가져오기
        final String senderName = messageData['senderId'] ?? '';

        // 발신자가 자신인지 확인 (CallerName과 비교)
        final bool isMe = senderName == _callerName;

        // 채팅 메시지 객체 생성
        final message = ChatMessage(
          text: messageData['content'] ?? '',
          isMe: isMe,
          timestamp: DateTime.parse(
            messageData['sendAt'] ?? DateTime.now().toIso8601String(),
          ),
        );

        // 메시지 캐시에 추가
        _addMessageToCache(roomId, message);

        // 메시지 파일 저장
        _saveMessagesToFile(roomId);

        // 메시지 스트림에 추가 (현재 방의 메시지만)
        if (roomId == _currentRoomId) {
          _messageStreamController.add(message);
        }
      } catch (e) {
        print('메시지 처리 오류: $e');
      }
    });

    // 연결 상태 변경 핸들러 등록
    _hubConnection?.onreconnecting(({error}) {
      _isConnected = false;
      print('SignalR 재연결 시도 중...');
    });

    _hubConnection?.onreconnected(({connectionId}) {
      _isConnected = true;
      print('SignalR 재연결 성공: $connectionId');
    });

    _hubConnection?.onclose(({error}) {
      _isConnected = false;
      print('SignalR 연결 종료: ${error?.toString() ?? "정상 종료"}');
    });

    // 상품 정보 업데이트 알림 처리
    _hubConnection?.on("ReceiveTradeOfferUpdate", (arguments) {
      if (arguments == null || arguments.isEmpty) return;

      try {
        final data = arguments[0] as Map<String, dynamic>;
        print('상품 정보 업데이트 알림 수신: $data');

        // 등록된 핸들러가 있으면 호출
        if (_tradeOfferUpdateHandler != null) {
          _tradeOfferUpdateHandler!(data);
        }
      } catch (e) {
        print('상품 정보 업데이트 알림 처리 오류: $e');
      }
    });
  }

  // 메시지를 캐시에 추가
  void _addMessageToCache(int roomId, ChatMessage message) {
    if (!_messageCache.containsKey(roomId)) {
      _messageCache[roomId] = [];
    }

    // 중복 방지
    if (!_messageCache[roomId]!.any(
      (m) =>
          m.text == message.text &&
          m.timestamp == message.timestamp &&
          m.isMe == message.isMe,
    )) {
      _messageCache[roomId]!.add(message);
      // 시간순 정렬
      _messageCache[roomId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
  }

  // SignalR 서버 연결
  Future<void> connect(int chatRoomId, {String callerName = ''}) async {
    if (_isConnected && _currentRoomId == chatRoomId) return;

    try {
      // 토큰 가져오기
      final String? token = await TokenManager.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('인증 토큰이 없습니다. 로그인이 필요합니다.');
      }

      // 발신자 이름 설정
      _callerName = callerName;

      // 기존 연결 종료
      await disconnect();

      // 서버 URL 가져오기
      final String baseUrl = ApiClient().getDomain;
      final String hubUrl = '$baseUrl/chathub';

      // 토큰 인증을 위한 연결 옵션 설정
      final httpConnectionOptions = HttpConnectionOptions(
        logger: Logger("SignalRLogger"),
        logMessageContent: true,
        accessTokenFactory: () => Future.value(token),
      );

      // 허브 연결 객체 생성
      _hubConnection =
          HubConnectionBuilder()
              .withUrl(hubUrl, options: httpConnectionOptions)
              .withAutomaticReconnect()
              .build();

      // 이벤트 핸들러 등록
      _registerEventHandlers();

      // 연결 시작
      await _hubConnection?.start();

      if (_hubConnection?.state == HubConnectionState.Connected) {
        _isConnected = true;
        _currentRoomId = chatRoomId;
        print('SignalR 연결 성공: ${_hubConnection?.connectionId}, 방: $chatRoomId');

        // 저장된 메시지 로드
        await loadMessages(chatRoomId);
      }
    } catch (e) {
      _isConnected = false;
      print('SignalR 연결 오류: $e');
      rethrow;
    }
  }

  // 메시지 전송
  Future<void> sendMessage(int roomId, String message) async {
    if (!_isConnected || _hubConnection == null) {
      throw Exception('SignalR 연결이 되어있지 않습니다.');
    }

    try {
      // example_signalr_test_page.dart의 메서드 호출 방식 참고
      // roomId: 채팅방 ID
      // message: 메시지 내용
      // 0: 메시지 타입 (Text는 0으로 가정)
      await _hubConnection?.invoke('SendMessage', args: [roomId, message, 0]);
      print('메시지 전송 성공: $message');
    } catch (e) {
      print('메시지 전송 오류: $e');
      rethrow;
    }
  }

  // 저장된 메시지 로드
  Future<List<ChatMessage>> loadMessages(int roomId) async {
    try {
      // 이미 캐시에 있는 경우
      if (_messageCache.containsKey(roomId)) {
        return _messageCache[roomId]!;
      }

      // 캐시에 없는 경우 파일에서 로드
      if (kIsWeb) {
        // 웹 환경은 구현 생략
        _messageCache[roomId] = [];
        return [];
      } else {
        return await _loadMessagesFromFile(roomId);
      }
    } catch (e) {
      print('메시지 로드 오류: $e');
      _messageCache[roomId] = [];
      return [];
    }
  }

  // 파일에서 메시지 로드
  Future<List<ChatMessage>> _loadMessagesFromFile(int roomId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_room_${roomId}_messages.json');

      if (!await file.exists()) {
        _messageCache[roomId] = [];
        return [];
      }

      final String content = await file.readAsString();
      if (content.isEmpty) {
        _messageCache[roomId] = [];
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(content);
      final List<ChatMessage> messages =
          jsonList
              .map<ChatMessage>(
                (json) => ChatMessage(
                  text: json['text'],
                  isMe: json['isMe'],
                  timestamp: DateTime.parse(json['timestamp']),
                ),
              )
              .toList();

      // 시간순 정렬 (오래된 메시지가 먼저 오도록)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // 캐시에 저장
      _messageCache[roomId] = messages;

      return messages;
    } catch (e) {
      print('파일에서 메시지 로드 오류: $e');
      _messageCache[roomId] = [];
      return [];
    }
  }

  // 메시지를 파일에 저장
  Future<void> _saveMessagesToFile(int roomId) async {
    if (kIsWeb || !_messageCache.containsKey(roomId)) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_room_${roomId}_messages.json');

      // 메시지 리스트를 JSON으로 변환
      final List<Map<String, dynamic>> jsonList =
          _messageCache[roomId]!
              .map(
                (message) => {
                  'text': message.text,
                  'isMe': message.isMe,
                  'timestamp': message.timestamp.toIso8601String(),
                },
              )
              .toList();

      // 파일에 저장
      await file.writeAsString(jsonEncode(jsonList));
      print('${jsonList.length}개 메시지 저장 완료 (방ID: $roomId)');
    } catch (e) {
      print('파일에 메시지 저장 오류: $e');
    }
  }

  // 연결 종료
  Future<void> disconnect() async {
    if (!_isConnected || _hubConnection == null) return;

    try {
      await _hubConnection?.stop();
      _isConnected = false;
      _currentRoomId = 0;
      print('SignalR 연결 종료');
    } catch (e) {
      print('SignalR 연결 종료 오류: $e');
    }
  }

  // 자원 해제
  void dispose() {
    disconnect();
    _messageStreamController.close();
    _tradeOfferUpdateHandler = null; // 핸들러 참조 제거
  }
}
