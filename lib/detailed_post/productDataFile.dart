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
    const categoryMap = {
      'ClothingAndFashion': '의류/패션',
      'Electronics': '전자제품',
      'FurnitureAndInterior': '가구/인테리어',
      'Beauty': '뷰티/미용',
      'Books': '도서',
      'Stationery': '문구',
      'CarAccessories': '자동차 용품',
      'Sports': '스포츠/레저',
      'InfantsAndChildren': '유아/아동',
      'PetSupplies': '반려동물 용품',
      'HealthAndMedical': '건강/의료',
      'Hobbies': '취미/여가',
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
      categories: List<String>.from(json['categories'].map((cat) => categoryMap[cat] ?? cat)),
      state: json['state'],
      description: json['description'],
      imagesUrl: List<String>.from(json['imagesUrl']),
    );
  }
}
