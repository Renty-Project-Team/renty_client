import 'package:intl/intl.dart';

class ReviewModel {
  final int itemId;
  final String itemTitle;
  final String itemImageUrl;
  final String myName;
  final String sellerName;
  final String? sellerProfileImageUrl;
  final String buyerName;
  final String? buyerProfileImageUrl; // 구매자 프로필 이미지 추가
  final int satisfaction;
  final String content;
  final String sellerEvaluation;
  final List<String> imagesUrl;
  final DateTime writedAt;

  ReviewModel({
    required this.itemId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.myName,
    required this.sellerName,
    this.sellerProfileImageUrl,
    required this.buyerName,
    this.buyerProfileImageUrl, // 생성자에 추가
    required this.satisfaction,
    required this.content,
    required this.sellerEvaluation,
    required this.imagesUrl,
    required this.writedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      itemId: json['itemId'] as int,
      itemTitle: json['itemTitle'] as String,
      itemImageUrl: json['itemImageUrl'] as String,
      myName: json['myName'] as String,
      sellerName: json['sellerName'] as String,
      sellerProfileImageUrl: json['sellerProfileImageUrl'] as String?,
      buyerName: json['buyerName'] as String,
      buyerProfileImageUrl:
          json['buyerProfileImageUrl'] as String?, // JSON 파싱 추가
      satisfaction: json['satisfaction'] as int,
      content: json['content'] as String,
      sellerEvaluation: json['sellerEvaluation'] as String,
      imagesUrl: List<String>.from(json['imagesUrl'] ?? []),
      writedAt: DateTime.parse(json['writedAt'] as String),
    );
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd').format(writedAt);
  }

  // 이미지 URL이 상대 경로일 경우 전체 URL 반환하는 메소드
  String getFullImageUrl(String baseUrl, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return '$baseUrl$imageUrl';
  }

  // 현재 사용자가 작성한 리뷰인지 확인하는 메소드
  bool isWrittenByUser(String currentUserName) {
    return myName == currentUserName;
  }
}
