import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // 날짜 및 숫자 포맷팅을 위한 패키지
import 'dart:async';
import 'dart:convert';
import '../core/api_client.dart'; // API 클라이언트 추가
import '../chat/signalr_service.dart'; // SignalR 서비스 추가
import '../chat/trade_button_service.dart';

// 앱의 루트 위젯
class Chating extends StatefulWidget {
  const Chating({super.key});

  @override
  State<Chating> createState() => _ChatingState();
}

class _ChatingState extends State<Chating> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: const ChatScreen(chatRoomId: 0, roomName: "테스트계정"),
    );
  }
}

// 채팅 메시지 데이터 모델 클래스
class ChatMessage {
  final String text; // 메시지 내용
  final bool isMe; // 내가 보낸 메시지인지 여부
  final DateTime timestamp; // 메시지 전송 시간
  final String? senderName; // 발신자 이름 추가
  final String messageType; // 메시지 타입: 'text', 'product_update'
  final Map<String, dynamic>? productData; // 상품 정보 데이터
  final String? status; // 메시지 상태: 'sending', 'sent', 'error'

  // 생성자: 모든 필드가 필수값
  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.senderName, // 선택적 매개변수로 변경
    this.messageType = 'text', // 기본값은 일반 텍스트 메시지
    this.productData,
    this.status,
  });
}

// 상품 정보 데이터 모델
class Product {
  final String title;
  final String price;
  final String priceUnit;
  final String deposit;
  final String? imageUrl; // 새로 추가한 이미지 URL 필드

  Product({
    required this.title,
    required this.price,
    required this.priceUnit,
    required this.deposit,
    this.imageUrl, // 생성자에 imageUrl 추가
  });
}

// 검색 결과 항목을 나타내는 클래스
class SearchResult {
  final int messageIndex; // 메시지 인덱스
  final List<int> matchPositions; // 일치하는 위치들의 시작 인덱스
  final List<int> matchLengths; // 일치하는 부분의 길이들

  SearchResult({
    required this.messageIndex,
    required this.matchPositions,
    required this.matchLengths,
  });
}

// 채팅 화면 위젯 (상태 관리 필요)
class ChatScreen extends StatefulWidget {
  final int chatRoomId; // 채팅방 ID
  final String roomName; // 채팅방 이름(상대방 이름)
  final String? profileImageUrl; // 상대방 프로필 이미지 URL
  final Product? product; // 상품 정보 (선택적)
  final bool isBuyer; // 구매자 여부 추가 (true: 구매자, false: 판매자)

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.roomName,
    this.profileImageUrl,
    this.product,
    this.isBuyer = true, // 기본값은 구매자로 설정
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// 채팅 화면의 상태 관리 클래스
class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController =
      TextEditingController(); // 메시지 입력 컨트롤러
  List<ChatMessage> _messages = []; // 채팅 메시지 목록 저장
  final ScrollController _scrollController =
      ScrollController(); // 스크롤 위치 제어용 컨트롤러
  final ApiClient _apiClient = ApiClient(); // API 클라이언트 인스턴스
  final SignalRService _signalRService = SignalRService();
  StreamSubscription<ChatMessage>? _messageSubscription;

  // 채팅방 정보
  bool _isSeller = false; // 판매자 여부
  List<Map<String, dynamic>> _users = []; // 채팅방 참여자 정보
  String? _lastReadAt; // 마지막으로 읽은 시간
  bool _isLoading = true; // 로딩 상태
  String _callerName = ''; // 현재 발신자(본인) 이름 - 추가
  int _itemId = 0;
  String? _otherUserProfileImageUrl; // 상대방 프로필 이미지 URL
  DateTime? _productStartDate;
  DateTime? _productEndDate;
  OverlayState? _cachedOverlay;

  // 상품 정보 관리 변수
  late Product _product;

  // 검색 기능 관련 변수
  bool _isSearchMode = false; // 검색 모드 여부
  final TextEditingController _searchController =
      TextEditingController(); // 검색어 입력 컨트롤러
  List<SearchResult> _searchResults = []; // 검색 결과 (메시지 인덱스 목록)
  int _currentSearchIndex = -1; // 현재 선택된 검색 결과 인덱스
  String _lastSearchQuery = ''; // 마지막 검색어
  Timer? _searchDebounceTimer; // 검색 타이머

  // 검색 결과 알림 표시를 위한 OverlayEntry
  OverlayEntry? _overlayEntry;
  // 오버레이 애니메이션 컨트롤러
  AnimationController? _fadeAnimController;
  Animation<double>? _fadeAnimation;

  // 메시지 아이템 높이 (정확한 스크롤 위치 계산용)
  final double _messageItemHeight = 60.0;

  // 상품 정보 바 높이
  final double _productInfoHeight = 74.0; // 패딩 포함

  // 이미지 첨부 기능 관련 변수
  bool _isAttachmentOpen = false; // 이미지 첨부 영역 표시 여부

  // OverlayPortalController 추가
  late final OverlayPortalController _notificationController =
      OverlayPortalController();
  bool _isOverlayVisible = false;
  String _notificationMessage = '';
  Timer? _hideTimer;

  // 플래그 변수 추가 - 위젯이 제거되었는지 추적
  bool _isDisposed = false;
  double _screenHeight = 0.0;
  double _screenWidth = 0.0;

  int _tradeOfferVersion = 0; // tradeOfferVersion 변수 추가

  @override
  void initState() {
    super.initState();
    // 애니메이션 컨트롤러 초기화 - 페이드아웃 시간을 500ms로 설정
    _fadeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 0.5초 페이드아웃
    );

    // 애니메이션 정의 - Tween 방향을 명확히 함
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeAnimController!);

    // 위젯에서 전달받은 상품 정보가 있으면 사용, 없으면 기본값 사용
    _product =
        widget.product ??
        Product(
          title: "예제 상품 입니다",
          price: "2000",
          priceUnit: "일",
          deposit: "5000",
        );

    // 초기화는 addPostFrameCallback으로 안전하게 진행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _init();
      }
    });

    // 스크롤 리스너는 컨트롤러 생성 시점에 단 한 번만 추가
    _scrollController.addListener(_scrollListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedOverlay = Overlay.of(context);

    // 화면 크기 정보 저장
    _screenHeight = MediaQuery.of(context).size.height;
    _screenWidth = MediaQuery.of(context).size.width;
  }

  void _scrollListener() {
    // 위젯이 마운트되어 있는지 확인
    if (!mounted) return;

    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      // 저장된 화면 높이 사용
      final delta = _screenHeight * 0.2;

      // 상태 업데이트 전에도 mounted 확인
      if (mounted) {
        setState(() {
          // 여기서 스크롤 버튼 표시 여부 등의 상태 업데이트
        });
      }
    }
  }

  @override
  void deactivate() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
        _overlayEntry = null;
      } catch (e) {
        print('deactivate 중 오버레이 제거 실패: $e');
      }
    }
    super.deactivate();
  }

  // 안전한 setState 래퍼 함수 추가
  void _safeSetState(VoidCallback callback) {
    if (!_isDisposed && mounted) {
      setState(callback);
    }
  }

  Future<void> _init() async {
    // API 클라이언트 초기화
    await _initApiAndLoadMessages();

    // SignalR 연결 초기화
    await _initSignalRConnection();
  }

  // SignalR 연결 초기화 함수
  Future<void> _initSignalRConnection() async {
    try {
      // SignalR 연결 (callerName 전달)
      await _signalRService.initialize();
      await _signalRService.connect(
        widget.chatRoomId,
        callerName: _callerName,
      ); // _callerName = ''

      // 메시지 스트림 구독
      _messageSubscription = _signalRService.messageStream.listen(
        _onMessageReceived,
      );

      // 상품 정보 업데이트 핸들러 등록
      _signalRService.registerTradeOfferUpdateHandler(
        _handleTradeOfferUpdatedNotification,
      );
    } catch (e) {
      print('SignalR 연결 초기화 오류: $e');
      // 오류 처리 (예: 사용자에게 알림)
      _showNotification('채팅 연결에 실패했습니다. 다시 시도해주세요.');
    }
  }

  // 메시지 수신 처리
  void _onMessageReceived(ChatMessage message) {
    print('DEBUG: 메시지 수신 - 발신자: ${message.senderName}, 현재 사용자: $_callerName');

    // 상품 정보 업데이트 메시지인 경우 상단 상품 정보 업데이트
    if (message.messageType == 'product_update' &&
        message.productData != null) {
      print('DEBUG: 상품 정보 업데이트 메시지 수신, 상단 UI 업데이트 시도');

      // 날짜 정보 파싱 및 업데이트
      DateTime? startDate;
      DateTime? endDate;
      try {
        if (message.productData!['startDate'] != null) {
          startDate =
              DateTime.parse(message.productData!['startDate']).toLocal();
        }
        if (message.productData!['endDate'] != null) {
          endDate = DateTime.parse(message.productData!['endDate']).toLocal();
        }
      } catch (e) {
        print('DEBUG: 상품 업데이트 메시지 날짜 파싱 오류: $e');
      }

      _safeSetState(() {
        _product = Product(
          title: message.productData!['title'] ?? '상품 정보 없음',
          price: message.productData!['price'] ?? '0',
          priceUnit: '일',
          deposit: message.productData!['deposit'] ?? '0',
          imageUrl: _product.imageUrl, // 기존 상품의 이미지 URL 유지
        );
        _productStartDate = startDate;
        _productEndDate = endDate;
        print('DEBUG: 상단 상품 정보 업데이트 완료: ${_product.title}');
      });
    }

    setState(() {
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    // 검색 모드인 경우 현재 검색어로 다시 검색
    if (_isSearchMode && _lastSearchQuery.isNotEmpty) {
      _executeSearch(_lastSearchQuery);
    }

    // 스크롤을 맨 아래로 이동
    _scrollToBottom();
  }

  /// 상품 정보 업데이트 알림 처리 함수
  void _handleTradeOfferUpdatedNotification(Map<String, dynamic> data) {
    if (!mounted || _isDisposed) return;

    // roomId 확인 - 현재 채팅방의 업데이트만 처리
    final int roomId = data['roomId'] ?? 0;
    if (roomId != widget.chatRoomId) return;

    print('DEBUG: 상품 정보 업데이트 알림 수신 - 방ID: $roomId');

    // offer 데이터 추출
    final offerData = data['offer'];
    if (offerData == null) return;

    // 버전 정보 업데이트 - 서버에서 받은 버전으로 직접 업데이트
    final newVersion = offerData['version'] ?? 0;
    if (newVersion > _tradeOfferVersion) {
      _tradeOfferVersion = newVersion;
      print('DEBUG: 상품 정보 업데이트 알림 수신 - 새로운 버전: $_tradeOfferVersion');
    } else {
      print('DEBUG: 현재 버전이 더 높거나 같음 - 현재: $_tradeOfferVersion, 수신: $newVersion');
      return; // 현재 버전이 더 높거나 같으면 업데이트 중단
    }

    // 이미지 URL 처리
    String? fullImageUrl;
    final imageUrl = offerData['imageUrl'];
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != "string") {
      final ApiClient apiClient = ApiClient();
      fullImageUrl = '${apiClient.getDomain}$imageUrl';
      print('DEBUG: 업데이트된 이미지 URL: $fullImageUrl');
    }

    // 날짜 정보 처리
    DateTime? startDate;
    DateTime? endDate;

    if (offerData['borrowStartAt'] != null) {
      try {
        final String dateStr = offerData['borrowStartAt'];
        print('DEBUG: 서버에서 받은 시작 날짜 문자열: $dateStr');
        startDate = DateTime.parse(dateStr).toLocal();
        print('DEBUG: 파싱된 시작일: $startDate');
      } catch (e) {
        print('시작일 파싱 오류: $e');
      }
    }

    if (offerData['returnAt'] != null) {
      try {
        final String dateStr = offerData['returnAt'];
        print('DEBUG: 서버에서 받은 종료 날짜 문자열: $dateStr');
        endDate = DateTime.parse(dateStr).toLocal();
        print('DEBUG: 파싱된 종료일: $endDate');
      } catch (e) {
        print('종료일 파싱 오류: $e');
      }
    }

    // 상품 ID 업데이트
    _itemId = offerData['itemId'] ?? _itemId;

    // UI 업데이트
    if (!mounted || _isDisposed) return;

    _safeSetState(() {
      _product = Product(
        title: offerData['title'] ?? '상품 정보 없음',
        price: offerData['price']?.toString() ?? '0',
        priceUnit: offerData['priceUnit'] ?? '일',
        deposit: offerData['securityDeposit']?.toString() ?? '0',
        imageUrl: fullImageUrl,
      );

      // 날짜 정보 업데이트
      _productStartDate = startDate;
      _productEndDate = endDate;

      // 상품 정보 업데이트 카드 메시지 추가
      _messages.add(
        ChatMessage(
          text: "판매자가 상품 정보를 수정했습니다",
          isMe: false,
          timestamp: DateTime.now(),
          senderName: "", // 시스템 메시지
          messageType: 'product_update',
          productData: {
            'title': _product.title,
            'price': _formatPrice(_product.price),
            'priceUnit': _convertPriceUnitToKorean(_product.priceUnit),
            'deposit': _formatPrice(_product.deposit),
            'startDate': startDate != null ? DateFormat('yyyy-MM-dd').format(startDate) : null,
            'endDate': endDate != null ? DateFormat('yyyy-MM-dd').format(endDate) : null,
            'imageUrl': fullImageUrl,
          },
          status: 'sent',
        ),
      );
    });

    // 스크롤을 아래로 이동
    _scrollToBottom();
  }

  // API 클라이언트 초기화 및 메시지 로드
  Future<void> _initApiAndLoadMessages() async {
    // Future<void> <- 비동기 함수
    try {
      await _apiClient.initialize();
      await _loadMessages();
    } catch (e) {
      print('API 초기화 또는 메시지 로드 오류: $e');
      // 오류 처리
      setState(() {
        _isLoading = false;
      });
    }
  }

  // API를 통해 메시지 로드 (기존 _loadMessages 메서드 대체)
  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // API 요청 파라미터 설정
      final Map<String, dynamic> queryParams = {'roomId': widget.chatRoomId};

      if (_lastReadAt != null) {
        queryParams['lastReadAt'] = _lastReadAt;
      }

      // 채팅방 정보 요청
      final response = await _apiClient.client.get(
        '/chat/Room',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        print('DEBUG: 채팅방 정보 응답: ${response.data}'); // 디버그 로그

        // CallerName 저장
        _callerName = data['callerName'] ?? '';
        print('DEBUG: 발신자 이름(본인): $_callerName'); // 디버그 로그

        // isSeller 값을 가져와서 상태 변수에 저장 (추가된 부분)
        setState(() {
          _isSeller = data['isSeller'] ?? false;
        });
        print('DEBUG: 판매자 여부: $_isSeller'); // 디버그 로그 추가

        // 상품 정보 업데이트
        if (data['offer'] != null) {
          print('DEBUG: offer 데이터: ${data['offer']}'); // 디버그 로그

          _itemId = data['offer']['itemId'] ?? 0;
          print('DEBUG: 상품 ID: $_itemId');

          // 버전 정보 업데이트
          _tradeOfferVersion = data['offer']['version'] ?? 0;
          print('DEBUG: 초기 로딩된 tradeOfferVersion: $_tradeOfferVersion');

          // 이미지 URL 처리
          final imageUrl = data['offer']['imageUrl'];
          String? fullImageUrl;

          if (imageUrl is String &&
              imageUrl.isNotEmpty &&
              imageUrl != "string") {
            final ApiClient apiClient = ApiClient();
            fullImageUrl = '${apiClient.getDomain}$imageUrl';
            print('DEBUG: 변환된 이미지 URL: $fullImageUrl');

            // 이미지 URL을 SignalR 서비스에 설정 (추가)
            _signalRService.setProductImageUrl(fullImageUrl);
          }

          // 날짜 정보 추출 및 저장
          if (data['offer']['borrowStartAt'] != null) {
            try {
              final String dateStr = data['offer']['borrowStartAt'];
              print('DEBUG: 초기 로딩 - 서버에서 받은 시작 날짜: $dateStr');
              _productStartDate = DateTime.parse(dateStr).toLocal();
            } catch (e) {
              print('초기 시작일 파싱 오류: $e');
            }
          }

          if (data['offer']['returnAt'] != null) {
            try {
              final String dateStr = data['offer']['returnAt'];
              print('DEBUG: 초기 로딩 - 서버에서 받은 종료 날짜: $dateStr');
              _productEndDate = DateTime.parse(dateStr).toLocal();
            } catch (e) {
              print('초기 종료일 파싱 오류: $e');
            }
          }

          // 중요: 서버에서 받아온 상품 정보로 항상 업데이트
          setState(() {
            _product = Product(
              title: data['offer']['title'] ?? '상품 정보 없음',
              price: data['offer']['price']?.toString() ?? '0',
              priceUnit: data['offer']['priceUnit'] ?? '일',
              deposit: data['offer']['securityDeposit']?.toString() ?? '0',
              imageUrl: fullImageUrl, // 완전한 URL 사용
            );
          });
        } else {
          print('DEBUG: offer 데이터가 없습니다');
          // offer 데이터가 없을 때 기본값 설정
          setState(() {
            _product = Product(
              title: "상품 정보를 불러올 수 없습니다",
              price: "0",
              priceUnit: "일",
              deposit: "0",
            );
          });
        }

        // 사용자 정보 업데이트
        final List<dynamic> usersData = data['users'] ?? [];
        _users = usersData.map<Map<String, dynamic>>((userData) {
          String? profileImageUrl = userData['profileImageUrl'];
          // profileImageUrl이 상대 경로이면 전체 URL로 변환
          if (profileImageUrl != null &&
              profileImageUrl.isNotEmpty &&
              !profileImageUrl.startsWith('http') &&
              !profileImageUrl.startsWith('https')) {
            profileImageUrl = '${_apiClient.getDomain}$profileImageUrl';
          }
          return { ...userData, 'profileImageUrl': profileImageUrl };
        }).toList();

        // 상대방 프로필 이미지 URL 찾아서 저장
        if (_users.isNotEmpty && _callerName.isNotEmpty) {
          final otherUser = _users.firstWhere(
            (user) => user['name'] != _callerName,
            orElse: () => {}, // 해당하는 사용자가 없을 경우 빈 Map 반환
          );
          setState(() {
            _otherUserProfileImageUrl = otherUser['profileImageUrl'];
          });
        }

        // 메시지 처리
        final List<dynamic> messagesData = data['messages'] ?? [];
        if (messagesData.isNotEmpty) {
          // 새 메시지 추가
          final newMessages =
              messagesData.map<ChatMessage>((msg) {
                // 발신자 이름이 본인 이름과 같은지 비교하여 메시지 주인 구분
                final senderName = msg['senderName'] ?? '';
                final isSenderMe = senderName == _callerName;

                print(
                  'DEBUG: 메시지 로드 - 발신자: $senderName, 현재 사용자: $_callerName, 내 메시지 여부: $isSenderMe',
                );

                // 메시지 내용 확인
                String content = msg['content'] ?? '';
                String messageType = 'text';
                Map<String, dynamic>? productData;

                // JSON 형식인지 확인
                if (content.startsWith('{') && content.endsWith('}')) {
                  try {
                    final jsonData = jsonDecode(content);

                    // 상품 정보 메시지인지 확인 (Type: Request 형식)
                    if (jsonData['Type'] == 'Request' &&
                        jsonData['Data'] != null) {
                      messageType = 'product_update';

                      // 상품 정보 추출
                      productData = {
                        'title': jsonData['Data']['ProductName'] ?? '',
                        'price':
                            jsonData['Data']['RentalPrice']
                                ?.toString()
                                .replaceAll('일 ', '')
                                .replaceAll('원', '') ??
                            '0',
                        'deposit':
                            jsonData['Data']['Deposit']?.toString().replaceAll(
                              '원',
                              '',
                            ) ??
                            '0',
                        'startDate': jsonData['Data']['StartDate'],
                        'endDate': jsonData['Data']['EndDate'],
                        'messageId':
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        'imageUrl': _product.imageUrl, // 현재 로드된 상품의 이미지 URL 사용
                      };

                      // 메시지 텍스트 변경
                      content =
                          isSenderMe ? "상품 정보를 수정했습니다" : "판매자가 상품 정보를 수정했습니다";

                      print(
                        'DEBUG: JSON 메시지를 UI 카드로 변환 - ${productData['title']}',
                      );
                    }
                  } catch (e) {
                    print('JSON 메시지 파싱 실패: $e');
                  }
                }

                // 메시지 객체 생성 - 변환된 타입과 데이터로
                return ChatMessage(
                  text: content,
                  isMe: isSenderMe,
                  timestamp: DateTime.parse(msg['sendAt']),
                  senderName: senderName,
                  messageType: messageType,
                  productData: productData,
                  status: 'sent',
                );
              }).toList();

          setState(() {
            _messages.addAll(newMessages);
            _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          });
          // 메시지 로드 및 상태 업데이트 후 스크롤을 맨 아래로 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        // 로딩 상태 업데이트
        setState(() {
          _isLoading = false;
        });

        // 스크롤을 맨 아래로 이동
        _scrollToBottom();
      } else {
        print('API 오류: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('메시지 로드 중 오류 발생: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 스크롤을 맨 아래로 이동
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // 레이아웃이 완전히 계산될 시간을 주기 위해 작은 지연 시간을 추가
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      });
    }
  }

  // 검색 모드 토글 함수
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        // 검색 모드 종료 시 관련 상태 초기화
        _searchController.clear();
        _searchResults.clear();
        _currentSearchIndex = -1;
        _lastSearchQuery = '';
      }
    });
  }

  // 검색 실행 함수 - 디바운스 적용
  void _performSearch(String query) {
    // 이전 타이머가 있으면 취소
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _currentSearchIndex = -1;
        _lastSearchQuery = '';
      });
      return;
    }

    _lastSearchQuery = query;

    // 실제 검색은 즉시 수행
    _executeSearch(query);
  }

  // 실제 검색 수행 함수 - 개선된 검색 결과 저장
  void _executeSearch(String query) {
    final List<SearchResult> results = [];

    // 모든 메시지에서 검색어 포함 여부 확인 (대소문자 구분 없이)
    for (int i = 0; i < _messages.length; i++) {
      final text = _messages[i].text.toLowerCase();
      final searchQuery = query.toLowerCase();

      // 한 메시지 내에서 모든 일치하는 위치 찾기
      List<int> positions = [];
      List<int> lengths = [];

      int startIndex = 0;
      while (true) {
        final index = text.indexOf(searchQuery, startIndex);
        if (index == -1) break;

        positions.add(index);
        lengths.add(searchQuery.length);
        startIndex = index + searchQuery.length;
      }

      // 일치하는 부분이 있으면 검색 결과에 추가
      if (positions.isNotEmpty) {
        results.add(
          SearchResult(
            messageIndex: i,
            matchPositions: positions,
            matchLengths: lengths,
          ),
        );
      }
    }

    setState(() {
      _searchResults = results;
      _currentSearchIndex = _searchResults.isNotEmpty ? 0 : -1;

      // 검색 결과가 없을 경우 알림 표시
      if (_searchResults.isEmpty) {
        // 기존 타이머 취소
        _searchDebounceTimer?.cancel();

        // 정확히 1초 후에 알림 표시
        _searchDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _showNotification('검색 결과가 없습니다');

            // 2초 동안 알림 표시 후 페이드아웃
            Future.delayed(const Duration(milliseconds: 2000), () {
              if (mounted) {
                _fadeOutOverlay();
              }
            });
          }
        });
      } else {
        // 검색 결과가 있으면 해당 메시지로 스크롤
        _scrollToCurrentSearchResult();
      }
    });
  }

  // 다음 검색 결과로 이동 (아래 방향 화살표 - 더 최신 메시지)
  void _goToNextSearchResult() {
    if (_searchResults.isEmpty || _searchResults.length == 1) return;

    setState(() {
      // 현재 인덱스가 첫 번째(0)면 이동할 다음 결과가 없음
      if (_currentSearchIndex <= 0) {
        return; // 더 이상 다음(최신) 메시지 없음
      } else {
        _currentSearchIndex--; // 배열 인덱스 감소 (검색 결과는 최신순으로 정렬됨)
      }
      _scrollToCurrentSearchResult();

      // 이동 시 현재 검색된 단어 정보 표시
      _showCurrentSearchTermInfo();
    });
  }

  // 이전 검색 결과로 이동 (위 방향 화살표 - 더 과거 메시지)
  void _goToPreviousSearchResult() {
    if (_searchResults.isEmpty || _searchResults.length == 1) return;

    setState(() {
      // 현재 인덱스가 마지막이면 이전 결과가 없음
      if (_currentSearchIndex >= _searchResults.length - 1) {
        return; // 더 이상 이전(과거) 메시지 없음
      } else {
        _currentSearchIndex++; // 배열 인덱스 증가 (검색 결과는 최신순으로 정렬됨)
      }
      _scrollToCurrentSearchResult();

      // 이동 시 현재 검색된 단어 정보 표시
      _showCurrentSearchTermInfo();
    });
  }

  // 현재 선택된 검색 결과의 단어 정보 표시
  void _showCurrentSearchTermInfo() {
    if (_currentSearchIndex == -1 || _searchResults.isEmpty) return;

    final result = _searchResults[_currentSearchIndex];
    final message = _messages[result.messageIndex];

    // 검색된 단어 추출 (첫 번째 일치 부분만 사용)
    final int startPos = result.matchPositions.first;
    final int length = result.matchLengths.first;
    final String foundWord = message.text.substring(
      startPos,
      startPos + length,
    );
  }

  // 현재 검색 결과로 스크롤 이동 - 입력창 위에 표시되도록 수정
  void _scrollToCurrentSearchResult() {
    if (_currentSearchIndex == -1 || _searchResults.isEmpty) return;

    final int messageIndex = _searchResults[_currentSearchIndex].messageIndex;

    // 해당 메시지로 스크롤 위치 이동 (WidgetsBinding을 사용하여 레이아웃 완료 후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // 컨텍스트가 마운트되어 있는지 확인
        if (!mounted) return;

        // 스크롤 가능한 최대 높이 확인
        final maxScroll = _scrollController.position.maxScrollExtent;

        // 메시지 항목의 예상 위치 계산
        // (각 메시지마다 일정한 높이를 가정)
        final estimatedItemPosition = messageIndex * _messageItemHeight;

        // 화면의 높이 구하기
        final screenHeight = MediaQuery.of(context).size.height;

        // 앱 바, 상품 정보, 입력창 높이 계산
        final double appBarHeight =
            AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

        // 입력창 위에 메시지가 오도록 스크롤 위치 계산
        // 메시지가 입력창 바로 위에 표시되도록 조정
        final targetPosition =
            estimatedItemPosition -
            (screenHeight -
                (appBarHeight + _productInfoHeight + _messageItemHeight - 200));

        // 유효한 스크롤 범위 내로 제한
        final clampedPosition = targetPosition.clamp(0.0, maxScroll);

        // 애니메이션으로 스크롤 이동
        _scrollController.animateTo(
          clampedPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );

        // 검색 결과 정보 표시
        _showCurrentSearchTermInfo();
      } catch (e) {
        // 스크롤 에러 처리 (컨텍스트가 사라진 경우 등)
        print('스크롤 에러: $e');
      }
    });
  }

  // 검색 결과 없음 알림 표시
  void _showNoResultsNotification() {
    _showNotification('검색 결과가 없습니다');

    // 2초 후 알림 숨기기
    Future.delayed(const Duration(seconds: 2), () {
      _fadeOutOverlay();
    });
  }

  // 알림 표시 메서드 수정
  void _showNotification(String message) {
    if (!mounted) return;

    // 기존 타이머 취소
    _searchDebounceTimer?.cancel();

    setState(() {
      _isOverlayVisible = true;
      _notificationMessage = message;
    });

    // 애니메이션 컨트롤러 초기화 및 시작
    _fadeAnimController?.reset();

    // 3초 후 자동 숨김
    _searchDebounceTimer = Timer(const Duration(seconds: 3), () {
      _fadeOutOverlay();
    });
  }

  // 페이드아웃 메서드 수정
  void _fadeOutOverlay() {
    if (!mounted) return;

    _fadeAnimController?.forward().then((_) {
      if (mounted) {
        setState(() {
          _isOverlayVisible = false;
        });
      }
    });
  }

  // 상품 수정 모달 표시 함수
  void _showProductEditModal() {
    // 현재 상품 정보를 수정할 임시 변수
    String title = _product.title;
    String price = _product.price;
    String deposit = _product.deposit;

    // 버전 증가
    // _tradeOfferVersion += 1;
    // print('==== 상품 수정 시작 ====');
    // print('수정 전 버전: ${_tradeOfferVersion - 1}');
    // print('수정 후 버전: $_tradeOfferVersion');

    // 영어 단위를 한글로 매핑
    String priceUnit = _product.priceUnit;

    // 날짜 정보 추가
    DateTime startDate = DateTime.now();
    DateTime endDate = startDate.add(const Duration(days: 6));

    // API에서 가져온 기존 날짜 정보가 있으면 사용
    if (_productStartDate != null) {
      startDate = _productStartDate!;
    }

    if (_productEndDate != null) {
      endDate = _productEndDate!;
    }

    // 날짜 포맷터
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    // 영어 단위를 한글로 변환하는 매핑 로직 추가
    Map<String, String> unitMapping = {
      'Day': '일',
      'Week': '주',
      'Month': '월',
      'Year': '년',
    };

    // 서버에서 받은 영어 단위를 한글로 변환
    if (unitMapping.containsKey(priceUnit)) {
      priceUnit = unitMapping[priceUnit]!;
    } else if (!['일', '주', '월', '년'].contains(priceUnit)) {
      // 매핑에 없고 기본 한글 단위도 아니면 기본값 '일'로 설정
      priceUnit = '일';
    }

    // 유효성 검사 상태 변수
    bool isPriceValid = price.isNotEmpty;
    bool isDepositValid = deposit.isNotEmpty;

    // 드롭다운 아이템 목록
    final List<String> priceUnits = ['일', '주', '월', '년'];

    // 텍스트 필드 컨트롤러 설정
    final TextEditingController priceController = TextEditingController(
      text: price.split('.')[0], // 소수점 이하 제거
    );
    final TextEditingController depositController = TextEditingController(
      text: deposit.split('.')[0], // 소수점 이하 제거
    );

    // 입력값 유효성 검증 함수
    bool isFormValid() {
      return isPriceValid && isDepositValid;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상품 정보 영역
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 상품 이미지 - 채팅방 상단 상품 정보의 이미지 사용
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child:
                                  _product.imageUrl != null &&
                                          _product.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          _product.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            print('상품 수정 모달 이미지 로드 오류: $error');
                                            print(
                                              '이미지 URL: ${_product.imageUrl}',
                                            );
                                            return Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[500],
                                            );
                                          },
                                        ),
                                      )
                                      : Icon(
                                        Icons.image,
                                        color: Colors.grey[500],
                                      ),
                            ),
                            const SizedBox(width: 24),
                            // 상품 제목 (수정 불가 - 표시만 함)
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 대여 가격 설정 영역
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '대여 가격',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // 단위 선택 드롭다운 - 더 넓게 설정
                                Container(
                                  width: 120,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE2E2E2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: priceUnit,
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                      ),
                                      isDense: true,
                                      isExpanded: true,
                                      hint: const Text("단위"),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setDialogState(() {
                                            priceUnit = newValue;
                                          });
                                        }
                                      },
                                      items:
                                          priceUnits
                                              .map<DropdownMenuItem<String>>((
                                                String value,
                                              ) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              })
                                              .toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // 가격 입력 필드 - 아래 선만 있는 스타일로 변경
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color:
                                              isPriceValid
                                                  ? const Color(0xFFE2E2E2)
                                                  : Colors.red,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: priceController,
                                            keyboardType: TextInputType.number,
                                            // 숫자만 입력되도록 필터 추가
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            textAlign: TextAlign.right,
                                            onChanged: (value) {
                                              price = value;
                                              // 유효성 검사 상태 업데이트
                                              setDialogState(() {
                                                isPriceValid = value.isNotEmpty;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                              hintText: '가격 입력',
                                            ),
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const Text(
                                          '원',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // 가격 오류 메시지
                            if (!isPriceValid)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '가격을 입력해주세요',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 구분선
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                      // 보증금 설정 영역 - 아래 선만 있는 동일한 디자인
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '보증금',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:
                                        isDepositValid
                                            ? const Color(0xFFE2E2E2)
                                            : Colors.red,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: depositController,
                                      keyboardType: TextInputType.number,
                                      // 숫자만 입력되도록 필터 추가
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      textAlign: TextAlign.right,
                                      onChanged: (value) {
                                        deposit = value;
                                        // 유효성 검사 상태 업데이트
                                        setDialogState(() {
                                          isDepositValid = value.isNotEmpty;
                                        });
                                      },
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                        isDense: true,
                                        hintText: '보증금 입력',
                                      ),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const Text(
                                    '원',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            // 보증금 오류 메시지
                            if (!isDepositValid)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  '보증금을 입력해주세요',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '대여 가능 기간',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 시작일 선택 - 수정된 코드
                            GestureDetector(
                              onTap: () async {
                                print('시작일 선택 버튼 탭됨');

                                // 오류 수정: initialDate가 firstDate보다 이전인 경우 firstDate로 설정
                                DateTime now = DateTime.now();
                                DateTime initialPickDate = startDate;

                                // 시작일이 현재 날짜보다 이전이면, 현재 날짜를 initialDate로 설정
                                if (initialPickDate.isBefore(now)) {
                                  initialPickDate = now;
                                }

                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialPickDate,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                  builder: (
                                    BuildContext context,
                                    Widget? child,
                                  ) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF3154FF),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  print('선택된 시작일: $picked');
                                  setDialogState(() {
                                    startDate = picked;
                                    // 시작일이 종료일보다 이후인 경우 종료일 자동 조정
                                    if (startDate.isAfter(endDate)) {
                                      endDate = startDate.add(
                                        const Duration(days: 1),
                                      );
                                    }
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      Colors
                                          .grey[50], // 배경색 추가하여 탭 가능한 영역임을 시각적으로 강조
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(startDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      // 탭 가능함을 더 명확히 표시
                                      children: [
                                        const Text(
                                          '부터',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 종료일 선택 - 수정
                            GestureDetector(
                              onTap: () async {
                                print('종료일 선택 버튼 탭됨');

                                // 종료일은 시작일 이후여야 함
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      endDate.isBefore(startDate)
                                          ? startDate
                                          : endDate,
                                  firstDate: startDate, // 시작일 이후만 선택 가능하도록
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                  builder: (
                                    BuildContext context,
                                    Widget? child,
                                  ) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(0xFF3154FF),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null) {
                                  print('선택된 종료일: $picked');
                                  setDialogState(() {
                                    endDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50], // 배경색 추가
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateFormat.format(endDate),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        const Text(
                                          '까지',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 하단 버튼 영역 (우측 배치)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // 취소 버튼
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // 모달 닫기
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                '취소',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // 수정하기 버튼 - 그림자 제거
                            ElevatedButton(
                              onPressed:
                                  isFormValid()
                                      ? () {
                                        // 한글 단위를 영어로 다시 변환
                                        Map<String, String> reverseUnitMapping =
                                            {
                                              '일': 'Day',
                                              '주': 'Week',
                                              '월': 'Month',
                                              '년': 'Year',
                                            };

                                        // 저장할 단위 값
                                        String serverPriceUnit = priceUnit;
                                        if (reverseUnitMapping.containsKey(
                                          priceUnit,
                                        )) {
                                          serverPriceUnit =
                                              reverseUnitMapping[priceUnit]!;
                                        }

                                        // 날짜 포맷팅
                                        String startDateStr = DateFormat(
                                          'yyyy-MM-ddT12:00:00.000Z',
                                        ).format(
                                          DateTime(
                                            startDate.year,
                                            startDate.month,
                                            startDate.day,
                                            12,
                                            0,
                                            0,
                                          ).toUtc(),
                                        );

                                        String endDateStr = DateFormat(
                                          'yyyy-MM-ddT12:00:00.000Z',
                                        ).format(
                                          DateTime(
                                            endDate.year,
                                            endDate.month,
                                            endDate.day,
                                            12,
                                            0,
                                            0,
                                          ).toUtc(),
                                        );

                                        Navigator.of(context).pop(); // 먼저 모달 닫기

                                        // 디버깅: 전송될 버전과 현재 채팅방 버전 출력
                                        print('DEBUG: 상품 수정 - 전송될 버전: $_tradeOfferVersion');
                                        print('DEBUG: 상품 수정 - 현재 채팅방 버전: $_tradeOfferVersion');

                                        // 구매자 이름 찾기 (채팅방의 상대방)
                                        String buyerName = '';
                                        for (var user in _users) {
                                          if (user['name'] != _callerName) {
                                            buyerName = user['name'];
                                            break;
                                          }
                                        }

                                        // 메시지 상태 관리를 위한 고유 ID 생성
                                        final String messageId =
                                            DateTime.now()
                                                .millisecondsSinceEpoch
                                                .toString();

                                        // 상품 정보 데이터 준비
                                        final productData = {
                                          'title': title,
                                          'price': _formatPrice(price),
                                          'priceUnit':
                                              _convertPriceUnitToKorean(
                                                serverPriceUnit,
                                              ),
                                          'deposit': _formatPrice(deposit),
                                          'startDate': DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(startDate),
                                          'endDate': DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(endDate),
                                          'imageUrl': _product.imageUrl,
                                          'messageId': messageId,
                                        };

                                        // 카드 형태의 메시지를 UI에 즉시 추가 (전송 중 상태)
                                        _safeSetState(() {
                                          _messages.add(
                                            ChatMessage(
                                              text: "상품 정보를 수정했습니다",
                                              isMe: true,
                                              timestamp: DateTime.now(),
                                              senderName: _callerName,
                                              messageType: 'product_update',
                                              productData: productData,
                                              status: 'sending', // 전송 중 상태로 표시
                                            ),
                                          );
                                        });

                                        // 스크롤을 아래로 이동
                                        _scrollToBottom();

                                        // 상품 데이터 JSON 생성
                                        final requestData = {
                                          'Type': 'Request',
                                          'Sender': _callerName,
                                          'Data': {
                                            'ProductName': title,
                                            'RentalPrice':
                                                "${_convertPriceUnitToKorean(serverPriceUnit)} ${_formatPrice(price)}원",
                                            'Deposit':
                                                "${_formatPrice(deposit)}원",
                                            'StartDate': DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(startDate),
                                            'EndDate': DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(endDate),
                                          },
                                        };

                                        // TradeButtonService의 updateProductOffer 함수로 API 호출
                                        final tradeButtonService =
                                            TradeButtonService();
                                        tradeButtonService.updateProductOffer(
                                          itemId: _itemId,
                                          title: title,
                                          price: price,
                                          priceUnit: serverPriceUnit,
                                          deposit: deposit,
                                          buyerName: buyerName,
                                          borrowStartAt: startDateStr,
                                          returnAt: endDateStr,
                                          tradeOfferVersion: _tradeOfferVersion, // '수정하기' 버튼 클릭 시점의 최신 버전 사용
                                          onSuccess: (message) {
                                            if (!mounted || _isDisposed) return;

                                            // 콤마 제거하고 순수 숫자값만 저장
                                            final cleanPrice = price.replaceAll(
                                              ',',
                                              '',
                                            );
                                            final cleanDeposit = deposit
                                                .replaceAll(',', '');

                                            // 서버로 메시지 전송 (Type: Request)
                                            _signalRService
                                                .sendProductUpdateMessage(
                                                  widget.chatRoomId,
                                                  jsonEncode(requestData),
                                                )
                                                .then((_) {
                                                  // 성공적으로 전송된 경우 메시지 상태 업데이트
                                                  _safeSetState(() {
                                                    // 메시지 찾아서 상태 업데이트
                                                    final index = _messages
                                                        .indexWhere(
                                                          (msg) =>
                                                              msg.productData !=
                                                                  null &&
                                                              msg.productData!['messageId'] ==
                                                                  messageId,
                                                        );

                                                    if (index != -1) {
                                                      _messages[index] = ChatMessage(
                                                        text:
                                                            _messages[index]
                                                                .text,
                                                        isMe:
                                                            _messages[index]
                                                                .isMe,
                                                        timestamp:
                                                            _messages[index]
                                                                .timestamp,
                                                        senderName:
                                                            _messages[index]
                                                                .senderName,
                                                        messageType:
                                                            _messages[index]
                                                                .messageType,
                                                        productData:
                                                            _messages[index]
                                                                .productData,
                                                        status:
                                                            'sent', // 성공적으로 전송됨
                                                      );
                                                    }

                                                    // 상품 정보도 업데이트
                                                    _product = Product(
                                                      title: title,
                                                      price: cleanPrice,
                                                      priceUnit:
                                                          serverPriceUnit,
                                                      deposit: cleanDeposit,
                                                      imageUrl:
                                                          _product.imageUrl,
                                                    );

                                                    _productStartDate =
                                                        startDate;
                                                    _productEndDate = endDate;
                                                  });
                                                })
                                                .catchError((e) {
                                                  // 전송 실패 시 메시지 상태 업데이트
                                                  _safeSetState(() {
                                                    final index = _messages
                                                        .indexWhere(
                                                          (msg) =>
                                                              msg.productData !=
                                                                  null &&
                                                              msg.productData!['messageId'] ==
                                                                  messageId,
                                                        );

                                                    if (index != -1) {
                                                      _messages[index] =
                                                          ChatMessage(
                                                            text:
                                                                _messages[index]
                                                                    .text,
                                                            isMe:
                                                                _messages[index]
                                                                    .isMe,
                                                            timestamp:
                                                                _messages[index]
                                                                    .timestamp,
                                                            senderName:
                                                                _messages[index]
                                                                    .senderName,
                                                            messageType:
                                                                _messages[index]
                                                                    .messageType,
                                                            productData:
                                                                _messages[index]
                                                                    .productData,
                                                            status:
                                                                'error', // 전송 실패
                                                          );
                                                    }
                                                  });

                                                  _showNotification(
                                                    '메시지 전송에 실패했습니다.',
                                                  );
                                                });
                                          },
                                          onError: (errorMessage) {
                                            if (!mounted || _isDisposed) return;

                                            // API 호출 실패 시 메시지 상태 업데이트
                                            _safeSetState(() {
                                              final index = _messages.indexWhere(
                                                (msg) =>
                                                    msg.productData != null &&
                                                    msg.productData!['messageId'] ==
                                                        messageId,
                                              );

                                              if (index != -1) {
                                                _messages[index] = ChatMessage(
                                                  text: _messages[index].text,
                                                  isMe: _messages[index].isMe,
                                                  timestamp:
                                                      _messages[index]
                                                          .timestamp,
                                                  senderName:
                                                      _messages[index]
                                                          .senderName,
                                                  messageType:
                                                      _messages[index]
                                                          .messageType,
                                                  productData:
                                                      _messages[index]
                                                          .productData,
                                                  status: 'error', // 전송 실패
                                                );
                                              }
                                            });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(errorMessage),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                      : null, // 유효하지 않으면 버튼 비활성화
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3154FF),
                                foregroundColor: Colors.white,
                                // 비활성화된 버튼의 스타일
                                disabledBackgroundColor: Colors.grey[300],
                                disabledForegroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                elevation: 0, // 기본 그림자 제거
                                shadowColor: Colors.transparent, // 그림자 색상 투명하게
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ).copyWith(
                                overlayColor: MaterialStateProperty.resolveWith<
                                  Color?
                                >((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return const Color(
                                      0xFF3154FF,
                                    ).withOpacity(0.8); // 호버 시 배경색만 약간 변경
                                  }
                                  return null;
                                }),
                              ),
                              child: const Text(
                                '수정하기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        appBar: _buildAppBar(),
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 기존 화면 내용
            Column(
              children: [
                _buildProductInfo(),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSwatch().copyWith(
                        secondary: Colors.white,
                      ),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final showTimestamp =
                              index == _messages.length - 1 ||
                              _messages[index].timestamp.minute !=
                                  _messages[index + 1].timestamp.minute;

                          bool showProfile = false;
                          if (!_messages[index].isMe) {
                            if (index == 0) {
                              showProfile = true;
                            } else {
                              final prevMessage = _messages[index - 1];
                              if (prevMessage.timestamp.minute !=
                                      _messages[index].timestamp.minute ||
                                  prevMessage.isMe) {
                                showProfile = true;
                              }
                            }
                          }

                          int? matchPosition;
                          int? matchLength;
                          bool isCurrentSearchResult = false;

                          if (_isSearchMode &&
                              _currentSearchIndex != -1 &&
                              _searchResults.isNotEmpty) {
                            final currentResult =
                                _searchResults[_currentSearchIndex];
                            if (currentResult.messageIndex == index) {
                              isCurrentSearchResult = true;
                              matchPosition =
                                  currentResult.matchPositions.first;
                              matchLength = currentResult.matchLengths.first;
                            }
                          }

                          return _buildMessage(
                            _messages[index],
                            showTimestamp: showTimestamp,
                            isCurrentSearchResult: isCurrentSearchResult,
                            matchPosition: matchPosition,
                            matchLength: matchLength,
                            showProfile: showProfile,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_isAttachmentOpen)
                        Container(
                          height: 100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  // TODO: 이미지 첨부 기능 구현
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.image,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '이미지',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isAttachmentOpen ? Icons.close : Icons.add,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _isAttachmentOpen = !_isAttachmentOpen;
                                });
                              },
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _textController,
                                  decoration: InputDecoration(
                                    hintText: '메시지 입력',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3154FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _handleSubmitted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 알림을 위한 오버레이 포털
            if (_isOverlayVisible)
              Positioned(
                top:
                    AppBar().preferredSize.height +
                    MediaQuery.of(context).padding.top +
                    10,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation!,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1.0 - _fadeAnimation!.value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _notificationMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // AppBar 구성 함수
  PreferredSizeWidget _buildAppBar() {
    // 상대방 프로필 이미지 URL 찾기
    String? otherUserProfileImageUrl;
    if (_users.isNotEmpty && _callerName.isNotEmpty) {
      final otherUser = _users.firstWhere(
        (user) => user['name'] != _callerName,
        orElse: () => {}, // 해당하는 사용자가 없을 경우 빈 Map 반환
      );
      otherUserProfileImageUrl = otherUser?['profileImageUrl'];
    }

    // 검색 모드일 때 검색 AppBar 표시
    if (_isSearchMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: .2,
        titleSpacing: 0,
        // 뒤로가기 버튼
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _toggleSearchMode, // 검색 모드 종료
        ),
        // 검색 입력 필드
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            border: InputBorder.none,
          ),
          onChanged: _performSearch, // 텍스트 변경 시 검색 실행 (디바운스 포함)
          autofocus: true, // 검색 모드 진입 시 자동 포커스
        ),
        // 검색 관련 액션 버튼
        actions: [
          // 검색 결과 정보 표시
          if (_searchResults.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('${_currentSearchIndex + 1}/${_searchResults.length}',
                    style: const TextStyle(color: Colors.black, fontSize: 14)),
              ),
            ),
          // 위 화살표 버튼 (이전/과거 메시지)
            IconButton(
              icon: Icon(
                Icons.arrow_downward,
                color:
                    (_searchResults.length > 1 &&
                            _currentSearchIndex < _searchResults.length - 1)
                        ? Colors.black
                        : Colors.grey[400],
              ),
              onPressed:
                  (_searchResults.length > 1 &&
                          _currentSearchIndex < _searchResults.length - 1)
                      ? _goToPreviousSearchResult
                      : null,
              tooltip: '이전 메시지로 이동',
            ),

          // 아래 화살표 버튼 (다음/최신 메시지)
            IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color:
                    (_searchResults.length > 1 && _currentSearchIndex > 0)
                        ? Colors.black
                        : Colors.grey[400],
              ),
              onPressed:
                  (_searchResults.length > 1 && _currentSearchIndex > 0)
                      ? _goToNextSearchResult
                      : null,
              tooltip: '다음 메시지로 이동',
            ),

          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      );
    }
    // 일반 AppBar
    return AppBar(
      backgroundColor: Colors.white, // 앱바 배경색
      elevation: 0, // 그림자 제거
      // 뒤로가기 버튼
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아가기
          }),
      // 채팅 상대방 정보 표시
      title: Row(
        children: [
          // 프로필 아바타
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage: otherUserProfileImageUrl != null
                    ? NetworkImage(otherUserProfileImageUrl)
                    : null,
            child:
                widget.roomName.isNotEmpty && otherUserProfileImageUrl == null // 이미지가 없을 경우 이니셜 표시
                    ? Text(
                      widget.roomName.isNotEmpty
                          ? widget.roomName[0]
                          : "?", // 상대방 이니셜
                      style: TextStyle(color: Colors.grey[700]),
                    )
                    : null,
          ),
          const SizedBox(width: 10), // 간격
          // 상대방 이름
          Text(
            widget.roomName,
            style: const TextStyle(color: Colors.black, fontSize: 16),
          ),
        ],
      ),
      // 앱바 우측 액션 버튼들
      actions: [
        // 검색 버튼
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black),
          onPressed: _toggleSearchMode, // 검색 모드 켜기
        ),
        // 더보기 버튼
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {}, // 추가 옵션 메뉴 (미구현)
        ),
      ],
    );
  }

  // 상품 정보 UI 함수 수정
  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 상품 이미지 - 수정된 이미지 로드 로직
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child:
                _product.imageUrl != null && _product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('이미지 로드 오류: $error');
                          print('이미지 URL: ${_product.imageUrl}');
                          return Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[500],
                          );
                        },
                      ),
                    )
                    : Icon(Icons.image, color: Colors.grey[500]),
          ),
          const SizedBox(width: 12),

          // 상품 정보 텍스트 영역 - 기존 코드에서 날짜 정보 추가한 부분 유지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                // 대여 가격
                Text(
                  '${_convertPriceUnitToKorean(_product.priceUnit)} ${_formatPrice(_product.price)}원',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                // 보증금
                Text(
                  '보증금 ${_formatPrice(_product.deposit)}원',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                // 대여 기간 표시
                if (_productStartDate != null && _productEndDate != null)
                  Text(
                    '${DateFormat('yyyy.MM.dd').format(_productStartDate!)} ~ ${DateFormat('yyyy.MM.dd').format(_productEndDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),

          // 버튼 부분 - 기존 코드 유지
          TextButton(
            onPressed:
                _isSeller
                    ? _showProductEditModal // 판매자는 상품 수정 모달 표시
                    : () async { // 구매자는 '구매하기' 버튼 기능
                        // 구매하기 버튼 클릭 시 최신 버전 정보 가져오기
                        try {
                          final response = await _apiClient.client.get(
                            '/chat/Room',
                            queryParameters: {'roomId': widget.chatRoomId},
                          );

                          if (response.statusCode == 200) {
                            final data = response.data;
                            if (data['offer'] != null) {
                              final serverVersion = data['offer']['version'] ?? 0;
                              _tradeOfferVersion = serverVersion;
                              print('DEBUG: 구매하기 버튼 클릭 - 최신 버전 정보 업데이트: $_tradeOfferVersion');
                            }
                          }
                        } catch (e) {
                          print('DEBUG: 버전 정보 업데이트 실패: $e');
                        }

                        // 구매하기 버튼 클릭 시 버전 정보 로깅
                        print('==== 구매하기 버튼 클릭 ====');
                        print('현재 상품 버전: $_tradeOfferVersion');

                        final tradeButtonService = TradeButtonService();
                        tradeButtonService.showPurchaseModal(
                          context,
                          _product,
                          _callerName,
                          _itemId,
                          startDate: _productStartDate,
                          endDate: _productEndDate,
                          tradeOfferVersion: _tradeOfferVersion, // 업데이트된 버전 사용
                        );
                      },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3154FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              fixedSize: const Size(90, 30),
            ),
            child: Text(_isSeller ? '상품수정' : '구매하기'),
          ),
        ],
      ),
    );
  }

  // 영어 단위를 한글로 변환하는 함수
  String _convertPriceUnitToKorean(String unit) {
    switch (unit.toLowerCase()) {
      case 'day':
        return '일';
      case 'week':
        return '주';
      case 'month':
        return '월';
      case 'year':
        return '년';
      default:
        return unit; // 변환할 수 없는 경우 원본 반환
    }
  }

  // 안전하게 가격을 포맷팅하는 도움 함수
  String _formatPrice(String price) {
    if (price.isEmpty) return '0';

    try {
      // 쉼표가 있는 경우 제거
      String cleanPrice = price.replaceAll(',', '');

      // 소수점이 있는 경우 처리
      if (cleanPrice.contains('.')) {
        double value = double.parse(cleanPrice);
        return NumberFormat('#,###').format(value.toInt());
      } else {
        int value = int.parse(cleanPrice);
        return NumberFormat('#,###').format(value);
      }
    } catch (e) {
      print('가격 파싱 오류: $e, 원본 가격: $price');
      return price; // 파싱 실패 시 원본 문자열 반환
    }
  }

  // 채팅 메시지 UI 구성 함수 - 개선된 검색어 강조 표시
  Widget _buildMessage(
    ChatMessage message, {
    bool showTimestamp = false,
    bool isCurrentSearchResult = false,
    int? matchPosition,
    int? matchLength,
    bool showProfile = true,
  }) {
    final timestamp = formatTime(message.timestamp); // 시간 포맷팅

    // 상품 카드 메시지 타입인 경우
    if (message.messageType == 'product_update' &&
        message.productData != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 시간 표시
            if (showTimestamp)
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  timestamp,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ),

            // 상품 카드 UI
            Align(
              alignment:
                  message.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 헤더 영역 (파란색 배경)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3154FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/gift_icon.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '이 가격은 어떠세요?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 상품 정보 영역
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상품 이미지
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                message.productData!['imageUrl'] != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        message.productData!['imageUrl']!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey[400],
                                                  size: 30,
                                                ),
                                      ),
                                    )
                                    : Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                      size: 30,
                                    ),
                          ),
                          const SizedBox(width: 12),

                          // 상품 정보 텍스트
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.productData!['title'] ?? '예시 상품',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // 가격
                                Row(
                                  children: [
                                    Text(
                                      '대여 가격 :',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '일 ${message.productData!['price'] ?? '0'} 원',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 보증금
                                Row(
                                  children: [
                                    Text(
                                      '보증금 :',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${message.productData!['deposit'] ?? '0'} 원',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 대여 기간 표시 (있는 경우에만)
                    if (message.productData!['startDate'] != null &&
                        message.productData!['endDate'] != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '대여 기간',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${message.productData!['startDate']} ~ ${message.productData!['endDate']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    // 하단 텍스트 (누가 수정했는지)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 메시지 상태 표시
                          if (message.status != null)
                            _buildMessageStatusIcon(message.status!),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 검색어가 포함된 텍스트를 강조 표시로 변환
    Widget messageText;

    if (_isSearchMode && _lastSearchQuery.isNotEmpty) {
      // 1. 기본 스타일 정의
      final baseStyle = TextStyle(
        color: message.isMe ? Colors.white : Colors.black,
      );

      // 2. 일반 검색어 강조 스타일
      final highlightStyle = TextStyle(
        color: message.isMe ? Colors.white : Colors.black,
        backgroundColor: Colors.yellow.withOpacity(0.4), // 검색어는 노란색 배경으로 강조
      );

      // 3. 현재 선택된 검색어 강조 스타일 (더 강한 강조)
      final currentHighlightStyle = TextStyle(
        color: message.isMe ? Colors.black : Colors.white,
        backgroundColor: Colors.orange.withOpacity(
          0.8,
        ), // 현재 선택된 검색어는 주황색 배경으로 강조
        fontWeight: FontWeight.bold,
      );

      // 텍스트를 RichText로 변환하여 선택된 검색어와 일반 검색어 다르게 강조
      if (isCurrentSearchResult &&
          matchPosition != null &&
          matchLength != null) {
        // 현재 선택된 메시지는 특정 위치의 단어를 강하게 강조
        messageText = _buildSelectionHighlightedText(
          message.text,
          _lastSearchQuery,
          matchPosition,
          matchLength,
          baseStyle: baseStyle,
          highlightStyle: highlightStyle,
          currentHighlightStyle: currentHighlightStyle,
        );
      } else {
        // 일반 검색 결과는 모든 검색어를 일반적으로 강조
        messageText = _buildHighlightedText(
          message.text,
          _lastSearchQuery,
          baseStyle: baseStyle,
          highlightStyle: highlightStyle,
        );
      }
    } else {
      // 일반 텍스트
      messageText = Text(
        message.text,
        style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
      );
    }

    // 현재 선택된 검색 결과인 경우 메시지 컨테이너에 특별한 테두리 추가
    final messageContainer = Container(
      // 메시지 최대 너비 제한 (화면 너비의 70%)
      constraints: BoxConstraints(
        maxWidth:
            MediaQuery.of(context).size.width * (message.isMe ? 0.7 : 0.6),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 10,
      ), // 내부 패딩
      decoration: BoxDecoration(
        // 내 메시지는 #3154FF, 상대방 메시지는 흰색 배경
        color: message.isMe ? const Color(0xFF3154FF) : Colors.white,
        borderRadius: BorderRadius.circular(20), // 둥근 모서리
        // 상대방 메시지는 #D9D9D9 색상의 테두리 표시
        border:
            message.isMe
                ? (isCurrentSearchResult
                    ? Border.all(color: Colors.orange, width: 2) // 현재 선택된 내 메시지
                    : null)
                : Border.all(
                  color:
                      isCurrentSearchResult
                          ? Colors
                              .orange // 현재 선택된 상대방 메시지
                          : const Color(0xFFD9D9D9),
                  width: isCurrentSearchResult ? 2 : 1,
                ),
        // 현재 선택된 메시지는 그림자 효과 추가
        boxShadow:
            isCurrentSearchResult
                ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: messageText,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // 메시지 간 간격
      child: Row(
        // 메시지 정렬 방향 (내 메시지는 오른쪽, 상대방 메시지는 왼쪽)
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // 하단 정렬
        children: [
          // 상대방 메시지인 경우 프로필 아바타 또는 빈 공간
          if (!message.isMe) ...[
            if (showProfile) ...[ // 프로필 이미지를 표시하는 첫 메시지인 경우
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: 15, // 작은 크기로 설정 (지름 30)
                // _otherUserProfileImageUrl이 있으면 NetworkImage 사용, 없으면 이니셜 사용
                backgroundImage: _otherUserProfileImageUrl != null ? NetworkImage(_otherUserProfileImageUrl!) : null,
                child: _otherUserProfileImageUrl == null && widget.roomName.isNotEmpty ? Text(widget.roomName[0], style: TextStyle(color: Colors.grey[700], fontSize: 12)) : null,
              ), // CircleAvatar 닫는 괄호
              const SizedBox(width: 4), // 프로필 이미지와 메시지 사이의 간격 (4픽셀로 줄임)
            ] else ...[ // 프로필 이미지를 표시하지 않는 나머지 메시지인 경우
              // 프로필 이미지 (30) + 간격 (4) 만큼의 공간 확보
              const SizedBox(width: 34),
            ],
          ],

          // 내 메시지의 경우 왼쪽에 시간 표시 (상대방 메시지에는 표시되지 않음)
          // 내 메시지의 경우 왼쪽에 시간 표시
          if (message.isMe && showTimestamp)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                timestamp,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10, // 작은 글씨
                ),
              ),
            ),

          // 메시지 내용 컨테이너
          messageContainer,

          // 상대방 메시지의 경우 오른쪽에 시간 표시
          if (!message.isMe && showTimestamp)
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                timestamp,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10, // 작은 글씨
                ),
              ),
            ),

          // 내 메시지인 경우 오른쪽 여백 추가
          if (message.isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // 검색어를 강조하는 텍스트 위젯 생성 (일반 검색 결과)
  Widget _buildHighlightedText(
    String text,
    String query, {
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;

      // 일치하기 전 텍스트 추가
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      // 일치하는 텍스트를 강조 스타일로 추가
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );

      // 다음 검색 위치 설정
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  // 현재 선택된 검색어만 특별히 강조하는 텍스트 위젯 생성
  Widget _buildSelectionHighlightedText(
    String text,
    String query,
    int currentMatchPosition,
    int currentMatchLength, {
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
    required TextStyle currentHighlightStyle,
  }) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        // 남은 텍스트 추가
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }

      // 일치하기 전 텍스트 추가
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      // 현재 선택된 위치인지 확인하여 적절한 스타일 적용
      final bool isCurrentPosition = (index == currentMatchPosition);

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: isCurrentPosition ? currentHighlightStyle : highlightStyle,
        ),
      );

      // 다음 검색 위치 설정
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  // 메시지 전송 처리 함수
  void _handleSubmitted() {
    // 빈 메시지는 전송하지 않음
    if (_textController.text.isEmpty) return;

    final messageText = _textController.text;
    _textController.clear();

    print('DEBUG: 메시지 전송 - 발신자: $_callerName');

    // 메시지 ID 생성
    final String messageId = DateTime.now().millisecondsSinceEpoch.toString();

    // UI에 메시지 추가 (전송 중 상태)
    final newMessage = ChatMessage(
      text: messageText,
      isMe: true,
      timestamp: DateTime.now(),
      senderName: _callerName,
      status: 'sending', // 전송 중 상태
    );

    _safeSetState(() {
      _messages.add(newMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    // 스크롤 아래로 이동
    _scrollToBottom();

    // 서버로 메시지 전송
    _signalRService
        .sendMessage(widget.chatRoomId, messageText)
        .then((_) {
          // 전송 성공 처리
          _safeSetState(() {
            final index = _messages.indexWhere(
              (msg) =>
                  msg.text == messageText &&
                  msg.timestamp == newMessage.timestamp,
            );

            if (index != -1) {
              _messages[index] = ChatMessage(
                text: messageText,
                isMe: true,
                timestamp: newMessage.timestamp,
                senderName: _callerName,
                status: 'sent', // 성공적으로 전송됨
              );
            }
          });
        })
        .catchError((e) {
          print('메시지 전송 오류: $e');

          // 전송 실패 처리
          _safeSetState(() {
            final index = _messages.indexWhere(
              (msg) =>
                  msg.text == messageText &&
                  msg.timestamp == newMessage.timestamp,
            );

            if (index != -1) {
              _messages[index] = ChatMessage(
                text: messageText,
                isMe: true,
                timestamp: newMessage.timestamp,
                senderName: _callerName,
                status: 'error', // 전송 실패
              );
            }
          });

          _showNotification('메시지 전송에 실패했습니다.');
        });

    // 검색 모드인 경우 검색 업데이트
    if (_isSearchMode && _lastSearchQuery.isNotEmpty) {
      _executeSearch(_lastSearchQuery);
    }
  }

  // 메시지 상태 아이콘 생성 함수
  Widget _buildMessageStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case 'sent':
        return const Icon(Icons.check, size: 12, color: Colors.white);
      case 'error':
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // 타이머 정리
    _hideTimer?.cancel();
    _searchDebounceTimer?.cancel();

    // SignalR 관련 자원 해제
    _messageSubscription?.cancel();
    _signalRService.registerTradeOfferUpdateHandler(null);

    // 스크롤 리스너 제거
    _scrollController.removeListener(_scrollListener);

    // 컨트롤러 정리
    _fadeAnimController?.dispose();
    _searchController.dispose();
    _textController.dispose();
    _scrollController.dispose();

    // 오버레이 관련 변수 정리 (제거 로직은 deactivate에 있음)
    _cachedOverlay = null; // 캐시된 오버레이 참조만 정리

    super.dispose();
  }
}

// 시간 포맷팅 함수 (오전/오후 표시)
String formatTime(DateTime time) {
  final isAfternoon = time.hour >= 12; // 오후 여부 확인
  final hour = isAfternoon ? time.hour - 12 : time.hour; // 12시간제로 변환
  final minute = time.minute.toString().padLeft(2, '0'); // 분을 2자리로 표시
  final period = isAfternoon ? '오후' : '오전'; // 오전/오후 표시
  return '$period $hour:$minute'; // 예: 오후 3:05
}
