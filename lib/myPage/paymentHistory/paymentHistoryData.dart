class PaymentHistoryItem {
  final int paymentId;
  final int itemId;
  final String title;
  final String imgUrl;
  final double price;
  final double securityDeposit;
  final DateTime paymentDate;
  final DateTime borrowStartAt;
  final DateTime returnAt;
  final String sellerName;
  final String? sellerProfileImage;
  final String paymentMethod;
  final String paymentStatus;

  PaymentHistoryItem({
    required this.paymentId,
    required this.itemId,
    required this.title,
    required this.imgUrl,
    required this.price,
    required this.securityDeposit,
    required this.paymentDate,
    required this.borrowStartAt,
    required this.returnAt,
    required this.sellerName,
    this.sellerProfileImage,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  factory PaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItem(
      paymentId: json['paymentId'],
      itemId: json['itemId'],
      title: json['title'],
      imgUrl: json['imgUrl'] ?? '',
      price:
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : json['price'],
      securityDeposit:
          (json['securityDeposit'] is int)
              ? (json['securityDeposit'] as int).toDouble()
              : json['securityDeposit'],
      paymentDate: DateTime.parse(json['paymentDate']),
      borrowStartAt: DateTime.parse(json['borrowStartAt']),
      returnAt: DateTime.parse(json['returnAt']),
      sellerName: json['sellerName'],
      sellerProfileImage: json['sellerProfileImage'],
      paymentMethod: json['paymentMethod'] ?? '카드결제',
      paymentStatus: json['paymentStatus'] ?? '결제완료',
    );
  }
}
