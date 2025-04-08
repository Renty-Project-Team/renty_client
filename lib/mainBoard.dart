import 'package:flutter/material.dart';
import 'AdBoard.dart';

class Product {
  final String title;
  final String price;
  final String deposit;
  final int likes;
  final int views;
  final String imageUrl;

  Product({
    required this.title,
    required this.price,
    required this.deposit,
    required this.likes,
    required this.views,
    required this.imageUrl,
  });
}

class ProductListPage extends StatelessWidget {
  final List<Product> products = [
    Product(
      title: "1 상품 입니다",
      price: "일 2,000원",
      deposit: "보증금 10,000원",
      likes: 404,
      views: 404,
      imageUrl: "https://picsum.photos/200",
    ),
    Product(
      title: "2 번째 상품",
      price: "일 3,500원",
      deposit: "보증금 5,000원",
      likes: 123,
      views: 987,
      imageUrl: "https://picsum.photos/201",
    ),
    Product(
      title: "3 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "4 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "5 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "6 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "7 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "8 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "9 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "10 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "11 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "12 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "13 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
    Product(
      title: "14 번째 상품",
      price: "일 1,800원",
      deposit: "보증금 12,000원",
      likes: 56,
      views: 321,
      imageUrl: "https://picsum.photos/202",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 광고 포함해서 실제로 표시될 전체 항목 수 계산
    final totalItemCount = products.length + (products.length ~/ 4);

    return Scaffold(
      body: ListView.builder(
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          // 4번째마다 광고
          if (index!=0 && index % 5 == 0) {
            return AdCard();
          }

          // 광고가 들어간 만큼 인덱스 조정
          final productIndex = index - (index ~/ 5);
          final product = products[productIndex];

          return ProductCard(product: product);
        },
      ),
    );
  }
}
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network( //이미지 중앙 기준으로 설정된 해상도로 잘라서 보여줌
                product.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  height: 90,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 12),
            // 정보들
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    product.price,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.deposit,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // 좋아요/조회수 (세로 정렬)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.more_vert, size: 20, color: Colors.grey[600])
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${product.likes}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('${product.views}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



