class Product {
  final int itemId;
  final String userName;
  final String? userProfileImage;
  final String title;
  final String createdAt;
  final double price;
  final String priceUnit;
  final double securityDeposit;
  final int viewCount;
  final int wishCount;
  final List<String> categories;
  final String state;
  final String description;
  final List<String> imagesUrl;

  Product({
    required this.itemId,
    required this.userName,
    this.userProfileImage,
    required this.title,
    required this.createdAt,
    required this.price,
    required this.priceUnit,
    required this.securityDeposit,
    required this.viewCount,
    required this.wishCount,
    required this.categories,
    required this.state,
    required this.description,
    required this.imagesUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    const unitMap = {
      'Month': '월',
      'Week': '주',
      'Day': '일',
    };
    return Product(
      itemId: json['itemId'],
      userName: json['userName'],
      userProfileImage: json['userProfileImage'],
      title: json['title'],
      createdAt: json['createdAt'],
      price: json['price'],
      priceUnit: unitMap[json['priceUnit']] ?? json['priceUnit'] ?? '',
      securityDeposit: json['securityDeposit'],
      viewCount: json['viewCount'],
      wishCount: json['wishCount'],
      categories: List<String>.from(json['categories']),
      state: json['state'],
      description: json['description'],
      imagesUrl: List<String>.from(json['imagesUrl']),
    );
  }
}
