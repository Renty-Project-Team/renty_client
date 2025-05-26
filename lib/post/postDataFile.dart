import 'mainBoard.dart';
class Product {
  final int id;
  final String title;
  final double price;
  final double deposit;
  final List<String> categorys;
  final String priceUnit;
  final int viewCount;
  final int wishCount;
  final int chatCount;
  final DateTime createdAt;
  final String imageUrl;
  final String userName;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.deposit,
    required this.categorys,
    required this.priceUnit,
    required this.viewCount,
    required this.wishCount,
    required this.chatCount,
    required this.createdAt,
    required this.imageUrl,
    required this.userName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    const unitMap = {'Month': '월', 'Week': '주', 'Day': '일'};
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price'] ?? 0),
      deposit: (json['deposit'] ?? 0),
      categorys: List<String>.from(json['categorys'] ?? []),
      priceUnit: unitMap[json['priceUnit']] ?? json['priceUnit'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      wishCount: json['wishCount'] ?? 0,
      chatCount: json['chatCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
      userName: json['userName'] ?? '', // JSON에서 userName 파싱 추가
    );
  }
}

class BuyerPost implements PostUnion {
  final int id;
  final String userName;
  final String title;
  final String category;
  final int viewCount;
  final int commentCount;
  final DateTime createdAt;
  final String? imageUrl;

  BuyerPost({
    required this.id,
    required this.userName,
    required this.title,
    required this.category,
    required this.viewCount,
    required this.commentCount,
    required this.createdAt,
    this.imageUrl,
  });

  factory BuyerPost.fromJson(Map<String, dynamic> json) {
    return BuyerPost(
      id: json['id'],
      userName: json['userName'],
      title: json['title'],
      category: json['category'],
      viewCount: json['viewCount'],
      commentCount: json['commentCount'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'],
    );
  }
}
