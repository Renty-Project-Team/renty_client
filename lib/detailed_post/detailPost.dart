import 'package:flutter/material.dart';
import 'productDataFile.dart';
class DetailPage extends StatelessWidget {
  final Product product;
  const DetailPage({required this.product, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            Image.network(
              product.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 사용자 정보 (임시 고정값)
                  Row(
                    children: [
                      CircleAvatar(child: Icon(Icons.person)),
                      SizedBox(width: 8),
                      Text(product.username, style: TextStyle(fontWeight: FontWeight.bold)),
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
                          Text("대여 가격: ${product.Unit} ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17)),
                          Text(product.price,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Spacer(),
                          Text("보증금: ", style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17)),
                          Text(product.deposit,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17)),
                        ],
                      ),
                      SizedBox(height:4),
                      Row(
                        children: [
                          Spacer(),
                          Icon(Icons.visibility),
                          Text(" ${product.views}"),
                          Icon(Icons.favorite_border),
                          Text("${product.likes}")
                        ]
                      ),
                      Divider(height: 24, thickness: 1),
                    ]
                  ),
                  // 카테고리, 상태 (임시 고정값)
                  Row(
                    children: [
                      Text("카테고리: ${product.Category}",style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text("대여여부: 대여 가능",style: TextStyle(fontWeight: FontWeight.bold)),
                  Divider(height: 24, thickness: 1),
                  // 설명 (임시 고정값)
                  Text(product.Description,style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 24),
                  Center(

                  ),
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
                // 채팅 기능 연결
                },
                child: Text("채팅하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
