import 'package:flutter/material.dart';
import 'productService.dart';
import 'productDataFile.dart';

class DetailPage extends StatelessWidget {
  final int itemId;
  const DetailPage({required this.itemId, Key? key}) : super(key: key);

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
              actions: [
                Icon(Icons.lightbulb_outline),
                SizedBox(width: 16),
              ],
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
                        final imageUrl = 'https://deciding-silkworm-set.ngrok-free.app${product.imagesUrl[index]}';
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
                            Text(product.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Divider(height: 24, thickness: 1),
                        SizedBox(height: 12),
                        // 제목
                        Text(
                          product.title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        // 가격 정보
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Spacer(),
                                Text("대여 가격: ${product.priceUnit} ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text("${product.price}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Spacer(),
                                Text("보증금: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text("${product.securityDeposit}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                                children: [
                                  Spacer(),
                                  Icon(Icons.visibility),
                                  Text(" ${product.viewCount}"),
                                  Icon(Icons.favorite_border),
                                  Text("${product.wishCount}")
                                ]
                            ),
                            Divider(height: 24, thickness: 1),
                          ],
                        ),
                        // 카테고리, 상태
                        Row(
                          children: [
                            Text(
                              "카테고리: ${product.categories.isNotEmpty ? product.categories.first : '없음'}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text("대여여부: ${product.state == 'Active' ? '대여 가능' : '대여 불가'}", style: TextStyle(fontWeight: FontWeight.bold)),
                        Divider(height: 24, thickness: 1),
                        // 설명
                        Text(product.description, style: TextStyle(fontWeight: FontWeight.bold)),
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
                      onPressed: () {
                        // 채팅 기능
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
