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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    const unitMap = {
      'Month': '월',
      'Week': '주',
      'Day': '일',
    };
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: (json['price']?? 0),
      deposit: (json['deposit'] ?? 0),
      categorys: List<String>.from(json['categorys'] ?? []),
      priceUnit: unitMap[json['priceUnit']] ?? json['priceUnit'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      wishCount: json['wishCount'] ?? 0,
      chatCount: json['chatCount'] ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}