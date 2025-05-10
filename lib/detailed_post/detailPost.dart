import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import '../core/token_manager.dart'; // 토큰 관리자 import
import 'package:dio/dio.dart'; // Dio 추가
import '../chat/chat.dart' as chat;
import '../core/api_client.dart';
import 'productService.dart';
import 'productDataFile.dart';

class DetailPage extends StatelessWidget {
  final int itemId;
  const DetailPage({required this.itemId, Key? key}) : super(key: key);

  // 채팅방 생성 함수
  Future<Map<String, dynamic>?> _createChatRoom(
    BuildContext context,
    int itemId,
  ) async {
    // 로그인 확인
    if (await TokenManager.getToken() == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      Navigator.pushNamed(context, '/login');
      return null;
    }

    try {
      // 채팅방 생성 API 호출
      final response = await ApiClient().client.post(
        '/chat/Create',
        data: {'itemId': itemId},
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      return null;
    } on DioException catch (e) {
      String errorMessage = '채팅방 생성 중 오류가 발생했습니다';

      if (e.response?.statusCode == 400) {
        // 에러 메시지 확인
        final message = e.response?.data['message'];
        if (message != null) {
          errorMessage = message.toString();
        }
      } else if (e.response?.statusCode == 401) {
        errorMessage = '로그인이 필요합니다';
        Navigator.pushNamed(context, '/login');
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return null;
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
                                  "${product.price}",
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
                      onPressed: () async {
                        // 채팅방 생성 함수 호출
                        final result = await _createChatRoom(context, itemId);

                        if (result != null) {
                          // 채팅방 생성 성공
                          final chatRoomId = result['chatRoomId'];
                          final status = result['status'];

                          if (status == 'created' || status == 'exists') {
                            // Product 모델 생성 (채팅 화면에 전달할 상품 정보)
                            final chatProduct = chat.Product(
                              title: product.title,
                              price: product.price.toString(),
                              priceUnit: product.priceUnit,
                              deposit: product.securityDeposit.toString(),
                            );

                            // 채팅 화면으로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => chat.ChatScreen(
                                      chatRoomId: chatRoomId,
                                      roomName:
                                          product.userName, // 판매자 이름을 채팅방 이름으로
                                      product: chatProduct,
                                      isBuyer: true, // 구매자로 설정
                                    ),
                              ),
                            );
                          }
                        }
                      },
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
