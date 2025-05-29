class BuyerPost {
  final int id;
  final String userName;
  final String title;
  final String category;
  final int viewCount;
  final int commentCount;
  final DateTime createdAt;
  final String? imageUrl;
  String state; // 상태 필드 추가 (final 제거하여 수정 가능하게)

  BuyerPost({
    required this.id,
    required this.userName,
    required this.title,
    required this.category,
    required this.viewCount,
    required this.commentCount,
    required this.createdAt,
    this.imageUrl,
    this.state = 'Active', // 기본값 설정
  });

  factory BuyerPost.fromJson(Map<String, dynamic> json) {
    return BuyerPost(
      id: json['id'] ?? 0,
      userName: json['userName'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      imageUrl: json['imageUrl'],
      state: json['state'] ?? 'Active', // JSON에서 state 파싱 추가
    );
  }

  // 카테고리 한글 변환
  String get categoryKorean {
    switch (category) {
      case 'ClothingAndFashion':
        return '의류 및 패션';
      case 'Electronics':
        return '전자제품';
      case 'FurnitureAndInterior':
        return '가구 및 인테리어';
      case 'Books':
        return '도서';
      case 'Sports':
        return '스포츠';
      case 'Travel':
        return '여행';
      case 'Baby':
        return '유아용품';
      case 'Others':
        return '기타';
      default:
        return category;
    }
  }
}
