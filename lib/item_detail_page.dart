import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'chat.dart'; // 기존 채팅 화면
import 'chat_list.dart'; // 채팅 목록 화면 import 추가
import 'login/login.dart';
import 'api_client.dart'; // ApiClient import 추가

// 테스트용 상품 데이터 모델 api
class ItemData {
  final int id;
  final String title;
  final String price;
  final String description;
  final String sellerName;
  final String? sellerProfileUrl;

  const ItemData({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.sellerName,
    this.sellerProfileUrl,
  });
}

class ItemDetailPage extends StatefulWidget {
  const ItemDetailPage({Key? key}) : super(key: key);

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  // 채팅 서비스 인스턴스
  final ChatService _chatService = ChatService();

  // API 클라이언트 인스턴스
  final ApiClient apiClient = ApiClient();

  // 채팅방 생성 중 로딩 상태
  bool _isCreatingChatRoom = false;

  // 테스트용 상품 데이터
  final ItemData _item = const ItemData(
    id: 1234,
    title: "애플 에어팟 프로 2세대",
    price: "180,000원",
    description:
        "애플 에어팟 프로 2세대 판매합니다. 구매한지 2개월 되었고, 상태 좋습니다. 직거래 가능하며 택배도 가능합니다.",
    sellerName: "테스트계정",
  );

  // 채팅방 생성 함수
  Future<void> _createChatRoom() async {
    // 디버깅을 위한 로그 추가
    print("채팅방 생성 시도: 상품 ID = ${_item.id}");

    // 로그인 상태 확인 추가
    if (!(await apiClient.hasTokenCookieLocally())) {
      // 로그인되지 않은 경우 로그인 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return; // 함수 종료
    }

    // 이미 채팅방 생성 중이면 중복 요청 방지
    if (_isCreatingChatRoom) return;

    setState(() {
      _isCreatingChatRoom = true;
    });

    try {
      // context 전달하여 자동 로그인 화면 이동 활성화
      final response = await _chatService.createChatRoom(_item.id, context);

      if (!mounted) return;

      if (response.isSuccess) {
        // 성공 메시지 표시
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));

        // 채팅 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  chatRoomId: response.chatRoomId ?? 0,
                  roomName: _item.sellerName,
                  profileImageUrl: _item.sellerProfileUrl,
                  product: Product(
                    title: _item.title,
                    price: _item.price.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ), // 숫자만 추출
                    priceUnit: '일',
                    deposit: '50000',
                  ),
                  isBuyer: true, // 상품 상세 페이지에서 채팅을 시작하는 사람은 구매자로 설정
                ),
          ),
        );
      } else if (response.needsLogin) {
        // 이미 서비스에서 로그인 화면으로 이동 시도했으므로
        // 추가 처리가 필요하면 여기에 작성
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      } else {
        // 기타 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 예외 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingChatRoom = false;
        });
      }
    }
  }

  // 채팅 목록 화면으로 이동하는 함수 추가
  void _navigateToChatList() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ChatList(), // 채팅 목록 화면으로 이동
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 상세'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          // 왼쪽 상단에 뒤로가기 버튼 추가
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToChatList, // 채팅 목록으로 이동하는 함수 연결
        ),
      ),
      body: Column(
        children: [
          // 상품 정보 영역
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 이미지 (테스트용 회색 컨테이너)
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: const Center(child: Text('상품 이미지')),
                  ),

                  // 상품 정보
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 판매자 정보
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(_item.sellerName[0]),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _item.sellerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 상품명
                        Text(
                          _item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 가격
                        Text(
                          _item.price,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3154FF),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 상품 설명
                        Text(
                          _item.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼 영역
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // 찜하기 버튼 (테스트용 더미 버튼)
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Icon(Icons.favorite_border),
                  ),
                ),

                const SizedBox(width: 10),

                // 채팅하기 버튼
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: _isCreatingChatRoom ? null : _createChatRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3154FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child:
                        _isCreatingChatRoom
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              '채팅하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
