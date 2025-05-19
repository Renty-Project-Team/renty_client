class RentOutItem {
  final int itemId;
  final String title;
  final String priceUnit;
  final double price;
  final double finalPrice;
  final double finalSecurityDeposit;
  final DateTime createdAt;
  final DateTime borrowStartAt;
  final DateTime returnAt;
  final String? buyerName;
  final String state;
  final String? imgUrl;
  final int? roomId;

  RentOutItem({
    required this.roomId,
    required this.itemId,
    required this.title,
    required this.priceUnit,
    required this.price,
    required this.finalPrice,
    required this.finalSecurityDeposit,
    required this.createdAt,
    required this.borrowStartAt,
    required this.returnAt,
    required this.buyerName,
    required this.state,
    required this.imgUrl
  });

  factory RentOutItem.fromJson(Map<String, dynamic> json) {
    return RentOutItem(
      roomId: json['roomId'],
      itemId: json['itemId'],
      title: json['title'],
      priceUnit: json['priceUnit'],
      price: json['price'],
      finalPrice: json['finalPrice'],
      finalSecurityDeposit: json['finalSecurityDeposit'],
      createdAt: DateTime.parse(json['createdAt']),
      borrowStartAt: DateTime.parse(json['borrowStartAt']),
      returnAt: DateTime.parse(json['returnAt']),
      buyerName: json['name']??'',
      state: json['state'],
      imgUrl: json['itemImageUrl']??''
    );
  }
}


