import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import 'productService.dart';
import 'productDataFile.dart';
import '../chat/chat_service.dart';
import '../chat/chat.dart' as chat; // chat 접두사 추가
import '../login/login.dart';
import '../api_client.dart'; // ApiClient import 추가
import 'package:intl/intl.dart'; // NumberFormat 사용을 위한 import 추가

class DetailPage extends StatelessWidget {
  final int itemId;
  const DetailPage({required this.itemId, Key? key}) : super(key: key);

  // 채팅방 생성 함수 추가
  Future<void> _createChatRoom(BuildContext context, Product product) async {
    // 채팅 서비스 인스턴스
    final ChatService chatService = ChatService();

    // 디버깅을 위한 로그 추가
    print("채팅방 생성 시도: 상품 ID = $itemId");

    // 로그인 상태 확인
    if (!(await apiClient.hasTokenCookieLocally())) {
      // 로그인되지 않은 경우 로그인 화면으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return; // 함수 종료
    }

    // 채팅방 생성 중 표시
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('채팅방 생성 중...')),
    );

    try {
      // context 전달하여 자동 로그인 화면 이동 활성화
      final response = await chatService.createChatRoom(itemId, context);

      // 이전 스낵바 제거
      scaffoldMessenger.hideCurrentSnackBar();

      if (response.isSuccess) {
        // 성공 메시지 표시
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(response.message)),
        );

        // 채팅 화면으로 이동
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => chat.ChatScreen(
                  // chat 접두사 추가
                  chatRoomId: response.chatRoomId ?? 0,
                  roomName: product.userName,
                  // 프로필 이미지는 없으므로 null로 설정
                  profileImageUrl: null,
                  product: chat.Product(
                    // chat 접두사 추가
                    title: product.title,
                    price: product.price.toString(), // 필요시 형변환
                    priceUnit: product.priceUnit,
                    deposit: product.securityDeposit.toString(), // 필요시 형변환
                  ),
                  isBuyer: true,
                ),
          ),
        );
      } else if (response.needsLogin) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다')),
        );
      } else {
        // 기타 오류 처리
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 예외 처리
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: ProductService().fetchProduct(itemId), // 서버에서 상품 정보 가져오기
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(child: Text('에러 발생: ${snapshot.error}')),
          );
        } else if (snapshot.hasData) {
          final product = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(),
              actions: [Icon(Icons.lightbulb_outline), SizedBox(width: 16)],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이미지
                  SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: product.imagesUrl.length,
                      itemBuilder: (context, index) {
                        final imageUrl =
                            '${apiClient.getDomain}${product.imagesUrl[index]}';
                        return Image.network(imageUrl, fit: BoxFit.cover);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 정보
                        Row(
                          children: [
                            CircleAvatar(child: Icon(Icons.person)),
                            SizedBox(width: 8),
                            Text(
                              product.userName,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Divider(height: 24, thickness: 1),
                        SizedBox(height: 12),
                        // 제목
                        Text(
                          product.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        // 가격 정보
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Spacer(),
                                Text(
                                  "대여 가격: ${product.priceUnit} ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "${_formatPrice(product.price.toString())}원",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Spacer(),
                                Text(
                                  "보증금: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  "${product.securityDeposit}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Spacer(),
                                Icon(Icons.visibility),
                                Text(" ${product.viewCount}"),
                                Icon(Icons.favorite_border),
                                Text("${product.wishCount}"),
                              ],
                            ),
                            Divider(height: 24, thickness: 1),
                          ],
                        ),
                        // 카테고리, 상태
                        Row(
                          children: [
                            Text(
                              "카테고리: ${product.categories}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "대여여부: ${product.state == 'Active' ? '대여 가능' : '대여 불가'}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Divider(height: 24, thickness: 1),
                        // 설명
                        Text(
                          product.description,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border),
                    Spacer(),
                    ElevatedButton(
                      onPressed:
                          () => _createChatRoom(context, product), // 채팅 기능 추가
                      child: Text("채팅하기"),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(child: Text('데이터가 없습니다.')),
          );
        }
      },
    );
  }
}
