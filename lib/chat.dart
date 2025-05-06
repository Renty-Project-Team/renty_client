import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // 날짜 및 숫자 포맷팅을 위한 패키지
import 'dart:async'; // Timer 사용을 위한 추가

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

  // 생성자: 모든 필드가 필수값
  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

// 상품 정보 데이터 모델
class Product {
  String title; // 상품명
  String price; // 가격
  String priceUnit; // 가격 단위 (일, 두, 월, 년)
  String deposit; // 보증금

  Product({
    required this.title,
    required this.price,
    required this.priceUnit,
    required this.deposit,
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
  final List<ChatMessage> _messages = []; // 채팅 메시지 목록 저장
  final ScrollController _scrollController =
      ScrollController(); // 스크롤 위치 제어용 컨트롤러

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

    // 예시 메시지 삭제 - 기존 _addInitialMessages() 호출 제거
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _removeOverlay();
    _fadeAnimController?.dispose();
    super.dispose();
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

    // 최신 메시지부터 표시하기 위해 역순 정렬
    results.sort((a, b) => b.messageIndex.compareTo(a.messageIndex));

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
        final double inputAreaHeight = 56.0; // 메시지 입력 영역 높이 (대략적인 값)

        // 입력창 위에 메시지가 오도록 스크롤 위치 계산
        // 메시지가 입력창 바로 위에 표시되도록 조정
        final targetPosition =
            estimatedItemPosition -
            (screenHeight -
                (appBarHeight +
                    _productInfoHeight +
                    inputAreaHeight +
                    _messageItemHeight));

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

  // 간결한 알림 표시 - 수정
  void _showNotification(String message) {
    // 기존 오버레이 제거
    _removeOverlay();

    // 애니메이션 컨트롤러 리셋
    _fadeAnimController?.reset();

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
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
                  // 수정: 페이드아웃 애니메이션 적용
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
                    // 강조선 제거 - 테두리 속성 완전히 제거
                  ),
                  child: Text(
                    message,
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
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  // 오버레이 페이드아웃 효과와 함께 제거 - 수정
  void _fadeOutOverlay() {
    if (_overlayEntry != null && mounted) {
      // 페이드아웃 애니메이션 시작
      _fadeAnimController?.forward().then((_) {
        // 애니메이션 완료 후에만 오버레이 제거
        _removeOverlay();
      });
    }
  }

  // 오버레이 즉시 제거
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _fadeAnimController?.reset();
  }

  // 상품 수정 모달 표시 함수
  void _showProductEditModal() {
    // 현재 상품 정보를 수정할 임시 변수
    String title = _product.title;
    String price = _product.price;
    String priceUnit = _product.priceUnit;
    String deposit = _product.deposit;

    // 유효성 검사 상태 변수
    bool isPriceValid = price.isNotEmpty;
    bool isDepositValid = deposit.isNotEmpty;

    // 드롭다운 아이템 목록
    final List<String> priceUnits = ['일', '주', '월', '년'];

    // 텍스트 필드 컨트롤러 설정
    final TextEditingController priceController = TextEditingController(
      text: price,
    );
    final TextEditingController depositController = TextEditingController(
      text: deposit,
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
              backgroundColor: Colors.white, // 배경색 흰색으로 명시적 설정
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                ), // 전체 컨테이너에 상하 패딩 추가
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품 정보 영역
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        20,
                      ), // 패딩 증가
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 상품 이미지
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(width: 24), // 간격 증가
                          // 상품 제목 (수정 불가 - 표시만 함)
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 대여 가격 설정 영역
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        14,
                        24,
                        14,
                      ), // 패딩 증가
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
                          const SizedBox(height: 20), // 간격 증가
                          Row(
                            children: [
                              // 단위 선택 드롭다운 - 더 넓게 설정
                              Container(
                                width: 120, // 날짜 선택 영역 너비 명시적 설정
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
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    isDense: true,
                                    isExpanded: true, // 드롭다운이 컨테이너 너비를 채우도록 설정
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
                              const SizedBox(width: 20), // 간격 증가
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
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        20,
                      ), // 패딩 증가
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
                          const SizedBox(height: 20), // 간격 증가
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                const Text('원', style: TextStyle(fontSize: 16)),
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

                    // 하단 버튼 영역 (우측 배치)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        14,
                        24,
                        24,
                      ), // 패딩 증가
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
                          const SizedBox(width: 10), // 간격 증가
                          // 수정하기 버튼 - 그림자 제거
                          ElevatedButton(
                            onPressed:
                                isFormValid()
                                    ? () {
                                      // 상품 정보 업데이트 후, 부모 위젯 상태 갱신을 위해 setState 호출
                                      Navigator.of(context).pop(); // 먼저 모달 닫기

                                      setState(() {
                                        _product = Product(
                                          title: title,
                                          price: price,
                                          priceUnit: priceUnit,
                                          deposit: deposit,
                                        );

                                        // 상품 수정 완료 메시지 추가
                                        _messages.add(
                                          ChatMessage(
                                            text:
                                                "상품 정보를 수정했습니다.\n가격 : $priceUnit $price원\n보증금 : $deposit원",
                                            isMe: true,
                                            timestamp: DateTime.now(),
                                          ),
                                        );
                                      });

                                      // 스크롤을 맨 아래로 이동
                                      Future.delayed(
                                        const Duration(milliseconds: 100),
                                        () {
                                          _scrollController.animateTo(
                                            _scrollController
                                                .position
                                                .maxScrollExtent,
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeOut,
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // 최상위 컨테이너 배경을 흰색으로 설정
      child: Scaffold(
        // 앱바 (상단 네비게이션 바)
        appBar: _buildAppBar(),
        // 화면 본문 - 배경색을 흰색으로 설정
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // 1. 상품 정보 영역 (중고거래 채팅 등에서 사용)
            _buildProductInfo(),

            // 2. 채팅 메시지 목록 영역
            Expanded(
              child: Theme(
                // 리스트뷰의 오버스크롤 색상을 흰색으로 설정
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSwatch().copyWith(
                    secondary: Colors.white,
                  ),
                ),
                child: Container(
                  color: Colors.white, // 스크롤해도 배경색 흰색 유지
                  child: ListView.builder(
                    controller: _scrollController, // 스크롤 컨트롤러 연결
                    padding: const EdgeInsets.all(8.0), // 패딩 설정
                    itemCount: _messages.length, // 메시지 개수만큼 항목 생성
                    itemBuilder: (context, index) {
                      // 시간 표시 여부 결정: 마지막 메시지이거나 다음 메시지와 분 단위가 다를 때만 표시
                      final showTimestamp =
                          index == _messages.length - 1 ||
                          _messages[index].timestamp.minute !=
                              _messages[index + 1].timestamp.minute;

                      // 현재 검색된 메시지인지 확인
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
                          // 첫 번째 일치 위치 정보를 가져옴 (여러 위치가 있을 수 있음)
                          matchPosition = currentResult.matchPositions.first;
                          matchLength = currentResult.matchLengths.first;
                        }
                      }

                      // 각 메시지 아이템 빌드
                      return _buildMessage(
                        _messages[index],
                        showTimestamp: showTimestamp,
                        isCurrentSearchResult: isCurrentSearchResult,
                        matchPosition: matchPosition,
                        matchLength: matchLength,
                      );
                    },
                  ),
                ),
              ),
            ),

            // 3. 메시지 입력 영역
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!), // 상단 구분선
                ),
              ),
              child: Row(
                children: [
                  // 추가 기능 버튼 (이미지, 파일 첨부 등)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {}, // 첨부 기능 (미구현)
                  ),
                  // 메시지 입력 필드
                  Expanded(
                    child: TextField(
                      controller: _textController, // 텍스트 컨트롤러 연결
                      decoration: const InputDecoration(
                        hintText: '메시지 입력', // 힌트 텍스트
                        border: InputBorder.none, // 테두리 제거
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ), // 내부 패딩
                      ),
                    ),
                  ),
                  // 전송 버튼
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _handleSubmitted, // 메시지 전송 함수 연결
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar 구성 함수
  PreferredSizeWidget _buildAppBar() {
    // 검색 모드일 때 검색 AppBar 표시
    if (_isSearchMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: .2,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _toggleSearchMode, // 검색 모드 종료
        ),
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            border: InputBorder.none,
          ),
          onChanged: _performSearch, // 텍스트 변경 시 검색 실행
          autofocus: true, // 검색 모드 진입 시 자동 포커스
        ),
        actions: [
          // 검색 결과 정보 표시
          if (_searchResults.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${_currentSearchIndex + 1}/${_searchResults.length}',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),
            ),

          // 위 화살표 버튼 (이전/과거 메시지)
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.arrow_upward,
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
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.arrow_downward,
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

          // 검색어 지우기 버튼
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
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () {
          Navigator.pop(context); // 이전 화면으로 돌아가기
        },
      ),
      // 채팅 상대방 정보 표시
      title: Row(
        children: [
          // 프로필 아바타
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage:
                widget.profileImageUrl != null
                    ? NetworkImage(widget.profileImageUrl!)
                    : null,
            child:
                widget.profileImageUrl == null
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

  // 상품 정보 UI 함수 수정 - 구매자/판매자에 따라 버튼 다르게 표시
  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)), // 하단 구분선
      ),
      child: Row(
        children: [
          // 상품 이미지 (여기서는 플레이스홀더로 회색 박스 사용)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4), // 모서리 둥글게
            ),
          ),
          const SizedBox(width: 12), // 간격
          // 상품 정보 (제목 및 가격)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품명
                Text(
                  _product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                // 상품 가격 (천 단위 콤마 포맷 적용)
                Text(
                  '${_product.priceUnit} ${NumberFormat('#,###').format(int.parse(_product.price))}원',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          // 사용자 역할에 따라 다른 버튼 표시
          TextButton(
            onPressed:
                widget.isBuyer ? null : _showProductEditModal, // 판매자만 상품 수정 가능
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF3154FF), // #3154FF로 변경
              foregroundColor: Colors.white, // 버튼 텍스트 색상
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // 둥근 모서리
              ),
              fixedSize: const Size(90, 30), // 버튼 크기 고정
            ),
            child: Text(widget.isBuyer ? '구매하기' : '상품수정'),
          ),
        ],
      ),
    );
  }

  // 채팅 메시지 UI 구성 함수 - 개선된 검색어 강조 표시
  Widget _buildMessage(
    ChatMessage message, {
    bool showTimestamp = false,
    bool isCurrentSearchResult = false,
    int? matchPosition,
    int? matchLength,
  }) {
    final timestamp = formatTime(message.timestamp); // 시간 포맷팅

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
        maxWidth: MediaQuery.of(context).size.width * 0.7,
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
          // 상대방 메시지인 경우 프로필 아바타 표시
          if (!message.isMe) ...[
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 15, // 작은 크기로 설정
              child: Text(
                widget.roomName.isNotEmpty
                    ? widget.roomName[0]
                    : "?", // 상대방 이니셜
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
            const SizedBox(width: 8), // 아바타와 메시지 사이 간격
          ],

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

    setState(() {
      // 메시지 목록에 새 메시지 추가
      _messages.add(
        ChatMessage(
          text: _textController.text, // 입력된 텍스트
          isMe: true, // 내가 보낸 메시지
          timestamp: DateTime.now(), // 현재 시간
        ),
      );
      _textController.clear(); // 입력 필드 초기화
    });

    // 검색 모드인 경우 현재 검색어로 다시 검색 실행
    if (_isSearchMode && _lastSearchQuery.isNotEmpty) {
      _executeSearch(_lastSearchQuery);
    }

    // 메시지 추가 후 스크롤을 맨 아래로 이동
    // 약간의 지연을 두어 UI 업데이트 후 스크롤이 이동하도록 함
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent, // 스크롤 최하단 위치
        duration: const Duration(milliseconds: 300), // 애니메이션 시간
        curve: Curves.easeOut, // 애니메이션 곡선
      );
    });
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
