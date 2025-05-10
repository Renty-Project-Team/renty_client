import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'chat.dart';

/// 채팅 메시지를 로컬 파일에 저장하고 불러오는 기능을 담당하는 클래스
class ChatMessageStorage {
  // 싱글톤 패턴 구현
  static final ChatMessageStorage _instance = ChatMessageStorage._internal();
  factory ChatMessageStorage() => _instance;
  ChatMessageStorage._internal();

  // 메시지 캐시 (채팅방 ID를 키로 사용)
  final Map<int, List<ChatMessage>> _messageCache = {};

  // 파일 저장 경로 생성
  Future<String> _getFilePath(int roomId) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/chat_room_${roomId}_messages.json';
  }

  /// 특정 채팅방의 메시지를 파일에서 로드
  Future<List<ChatMessage>> loadMessages(int roomId) async {
    try {
      // 이미 캐시에 있는 경우 캐시에서 반환
      if (_messageCache.containsKey(roomId)) {
        return _messageCache[roomId]!;
      }

      // 웹 환경은 파일 저장소를 사용할 수 없음
      if (kIsWeb) {
        _messageCache[roomId] = [];
        return [];
      }

      // 파일 경로 가져오기
      final filePath = await _getFilePath(roomId);
      final file = File(filePath);

      // 파일이 존재하지 않으면 빈 리스트 반환
      if (!await file.exists()) {
        _messageCache[roomId] = [];
        return [];
      }

      // 파일에서 데이터 읽기
      final String content = await file.readAsString();
      if (content.isEmpty) {
        _messageCache[roomId] = [];
        return [];
      }

      // JSON 파싱 및 메시지 객체로 변환
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

      // 캐시에 저장
      _messageCache[roomId] = messages;
      print('채팅방 $roomId: ${messages.length}개 메시지 로드 완료');

      return messages;
    } catch (e) {
      print('메시지 로드 오류: $e');
      // 오류 발생 시 빈 리스트 반환
      _messageCache[roomId] = [];
      return [];
    }
  }

  /// 특정 채팅방에 새 메시지 추가 및 저장
  Future<void> addMessage(int roomId, ChatMessage message) async {
    try {
      // 캐시에 채팅방이 없으면 초기화
      if (!_messageCache.containsKey(roomId)) {
        await loadMessages(roomId); // 파일에서 불러오기 시도
      }

      // 중복 체크 (같은 내용, 시간, 발신자인 메시지가 있는지)
      bool isDuplicate = _messageCache[roomId]!.any(
        (m) =>
            m.text == message.text &&
            m.timestamp.isAtSameMomentAs(message.timestamp) &&
            m.isMe == message.isMe,
      );

      if (!isDuplicate) {
        // 캐시에 메시지 추가
        _messageCache[roomId]!.add(message);

        // 시간순 정렬
        _messageCache[roomId]!.sort(
          (a, b) => a.timestamp.compareTo(b.timestamp),
        );

        // 파일에 저장
        await saveMessages(roomId);
      }
    } catch (e) {
      print('메시지 추가 오류: $e');
    }
  }

  /// 메시지 목록을 파일에 저장
  Future<void> saveMessages(int roomId) async {
    // 웹 환경이거나 해당 채팅방 캐시가 없으면 무시
    if (kIsWeb || !_messageCache.containsKey(roomId)) return;

    try {
      // 파일 경로 가져오기
      final filePath = await _getFilePath(roomId);
      final file = File(filePath);

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
      print('채팅방 $roomId: ${jsonList.length}개 메시지 저장 완료');
    } catch (e) {
      print('메시지 저장 오류: $e');
    }
  }

  /// 특정 채팅방의 메시지 목록 반환 (캐시 또는 파일에서)
  Future<List<ChatMessage>> getMessages(int roomId) async {
    // 캐시에 있으면 캐시에서 반환, 없으면 파일에서 로드
    if (_messageCache.containsKey(roomId)) {
      return _messageCache[roomId]!;
    } else {
      return await loadMessages(roomId);
    }
  }

  /// 특정 채팅방의 메시지 모두 삭제
  Future<void> clearMessages(int roomId) async {
    try {
      // 캐시에서 삭제
      _messageCache.remove(roomId);

      // 파일이 있으면 삭제
      if (!kIsWeb) {
        final filePath = await _getFilePath(roomId);
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print('채팅방 $roomId: 메시지 파일 삭제 완료');
        }
      }
    } catch (e) {
      print('메시지 삭제 오류: $e');
    }
  }

  /// 모든 채팅방 메시지 캐시 정리 (메모리에서만 제거, 파일은 유지)
  void clearCache() {
    _messageCache.clear();
    print('모든 채팅방 메시지 캐시 정리 완료');
  }
}
