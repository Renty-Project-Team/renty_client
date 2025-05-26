import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';
import 'package:renty_client/myPage/review/reviewService.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:renty_client/core/token_manager.dart'; // TokenManager 추가

class ProductReviewsSection extends StatefulWidget {
  final int itemId;
  final String sellerName;

  const ProductReviewsSection({
    Key? key,
    required this.itemId,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<ReviewModel>> _reviewsFuture;
  final ApiClient _apiClient = ApiClient();
  bool _isLoggedIn = false; // 로그인 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 로그인 상태 확인
    _loadReviews();
  }

  // 로그인 상태 확인 함수
  Future<void> _checkLoginStatus() async {
    final token = await TokenManager.getToken();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null;
      });
    }
  }

  void _loadReviews() {
    _reviewsFuture = _reviewService.fetchAllReviews().then<List<ReviewModel>>((
      reviews,
    ) {
      // 이 상품의 리뷰만 필터링
      return reviews.where((review) => review.itemId == widget.itemId).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 여부에 따른 분기 처리
    if (!_isLoggedIn) {
      // 로그인하지 않은 경우 로그인 안내 UI 표시
      return _buildLoginPromptUI();
    }

    // 로그인한 경우 기존 리뷰 UI 표시
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        // 기존 코드는 그대로 유지...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              '리뷰를 불러오는 중 오류가 발생했습니다: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReviewHeader(reviews),
                    const SizedBox(height: 20),
                    _buildReviewSummary(reviews),
                    const Divider(height: 40, color: Color(0xFFEEEEEE)),
                    reviews.isEmpty
                        ? _buildNoReviews()
                        : _buildReviewsList(reviews),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 로그인 안내 UI - 기존 디자인 유지하면서 로그인 안내 메시지 표시
  Widget _buildLoginPromptUI() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 기존 리뷰 섹션 헤더와 동일한 디자인
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4B70FD), Color(0xFF6A8DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '상품 리뷰',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // 로그인 안내 메시지
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 40,
                          color: const Color(0xFF4B70FD),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '로그인하여 리뷰를 확인해보세요',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '다른 고객님들의 생생한 상품 리뷰를 확인하려면\n로그인이 필요합니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B70FD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '로그인하기',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHeader(List<ReviewModel> reviews) {
    // 평균 평점 계산
    double averageRating =
        reviews.isEmpty
            ? 0.0
            : reviews.fold(0.0, (sum, review) => sum + review.satisfaction) /
                reviews.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4B70FD), Color(0xFF6A8DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                '상품 리뷰',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${reviews.length}개의 리뷰',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          averageRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4B70FD),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSummary(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            RatingBarIndicator(
              rating: 0,
              itemBuilder:
                  (context, _) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 24.0,
              unratedColor: Colors.grey[300],
            ),
            const SizedBox(width: 12),
            Text(
              '아직 평가가 없습니다',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 평균 평점 계산
    double averageRating =
        reviews.fold(0.0, (sum, review) => sum + review.satisfaction) /
        reviews.length;

    // 각 별점별 개수 계산
    Map<int, int> ratingCounts = {};
    for (int i = 5; i >= 1; i--) {
      ratingCounts[i] =
          reviews.where((review) => review.satisfaction == i).length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 평균 별점 표시
        Row(
          children: [
            RatingBarIndicator(
              rating: averageRating,
              itemBuilder:
                  (context, _) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 28.0,
              unratedColor: Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 별점 분포 그래프
        ...ratingCounts.entries.map((entry) {
          final percentage =
              reviews.isEmpty ? 0.0 : entry.value / reviews.length;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.key}점',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNoReviews() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '아직 리뷰가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    final String baseDomain = _apiClient.getDomain;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '고객 리뷰',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            // 리뷰 정렬 필터 버튼 추가 가능
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: reviews.length,
          separatorBuilder:
              (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Color(0xFFEEEEEE)),
              ),
          itemBuilder: (context, index) {
            final review = reviews[index];

            // 구매자 프로필 이미지 URL 처리
            String? buyerProfileUrl;
            if (review.buyerProfileImageUrl != null &&
                review.buyerProfileImageUrl!.isNotEmpty) {
              buyerProfileUrl =
                  review.buyerProfileImageUrl!.startsWith('http')
                      ? review.buyerProfileImageUrl
                      : '$baseDomain${review.buyerProfileImageUrl}';
            }

            // 리뷰 작성 후 경과 시간
            final duration = DateTime.now().difference(review.writedAt);
            String timeAgo;
            if (duration.inDays > 30) {
              timeAgo = DateFormat('yyyy.MM.dd').format(review.writedAt);
            } else if (duration.inDays > 0) {
              timeAgo = '${duration.inDays}일 전';
            } else if (duration.inHours > 0) {
              timeAgo = '${duration.inHours}시간 전';
            } else if (duration.inMinutes > 0) {
              timeAgo = '${duration.inMinutes}분 전';
            } else {
              timeAgo = '방금 전';
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 리뷰 헤더 (작성자, 별점, 날짜)
                  Row(
                    children: [
                      // 구매자 프로필 이미지
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              buyerProfileUrl == null
                                  ? _getInitialColor(review.buyerName)
                                  : null,
                          image:
                              buyerProfileUrl != null
                                  ? DecorationImage(
                                    image: NetworkImage(buyerProfileUrl),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child:
                            buyerProfileUrl == null
                                ? Center(
                                  child: Text(
                                    review.buyerName.isNotEmpty
                                        ? review.buyerName[0]
                                        : "?",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 12),

                      // 작성자 정보 및 별점
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.buyerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: review.satisfaction.toDouble(),
                                itemBuilder:
                                    (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                itemCount: 5,
                                itemSize: 16.0,
                                unratedColor: Colors.grey[300],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 리뷰 내용
                  Text(
                    review.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey[800],
                    ),
                  ),

                  // 리뷰 이미지가 있을 경우 표시
                  if (review.imagesUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildReviewImages(review.imagesUrl, baseDomain),
                  ],

                  // 판매자 평가 표시 (Good, Bad인 경우)
                  if (review.sellerEvaluation != 'None') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            review.sellerEvaluation == 'Good'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            review.sellerEvaluation == 'Good'
                                ? Icons.thumb_up_alt
                                : Icons.thumb_down_alt,
                            size: 16,
                            color:
                                review.sellerEvaluation == 'Good'
                                    ? Colors.blue[600]
                                    : Colors.red[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.sellerEvaluation == 'Good'
                                ? '구매자 추천해요'
                                : '구매자 비추천해요',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  review.sellerEvaluation == 'Good'
                                      ? Colors.blue[600]
                                      : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewImages(List<String> imageUrls, String baseDomain) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            imageUrls.map((imageUrl) {
              final fullImageUrl =
                  imageUrl.startsWith('http')
                      ? imageUrl
                      : '$baseDomain$imageUrl';

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    // 이미지 확대 보기 기능 추가 가능
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(fullImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: null,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Color _getInitialColor(String name) {
    final List<Color> colors = [
      const Color(0xFF5E7CE2), // 파란색 계열
      const Color(0xFFE85F5C), // 붉은색 계열
      const Color(0xFF4ECDC4), // 청록색 계열
      const Color(0xFFFF922B), // 주황색 계열
      const Color(0xFFAA6DA3), // 보라색 계열
      const Color(0xFF61B136), // 초록색 계열
      const Color(0xFFFFB400), // 노란색 계열
    ];

    // 이름 첫 글자 기준으로 색상 선택
    final int hashCode = name.isEmpty ? 0 : name.codeUnitAt(0);
    return colors[hashCode % colors.length];
  }
}
