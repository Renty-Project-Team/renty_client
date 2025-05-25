import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';
import 'package:renty_client/myPage/review/reviewService.dart';

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

  @override
  void initState() {
    super.initState();
    _loadReviews();
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
    return FutureBuilder<List<ReviewModel>>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('리뷰를 불러오는 중 오류가 발생했습니다: ${snapshot.error}');
        }

        final reviews = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32, thickness: 8, color: Color(0xFFF5F5F5)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '상품 리뷰',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildReviewSummary(reviews),
                  const SizedBox(height: 24),
                  reviews.isEmpty
                      ? _buildNoReviews()
                      : _buildReviewsList(reviews),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewSummary(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return const Row(
        children: [
          Text(
            '평점 0.0',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Text('(0개의 리뷰)', style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      );
    }

    // 평균 평점 계산
    double averageRating =
        reviews.fold(0.0, (sum, review) => sum + review.satisfaction) /
        reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Row(
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < averageRating.floor()
                        ? Icons.star
                        : (i < averageRating.ceil() &&
                            averageRating.floor() != averageRating.ceil())
                        ? Icons.star_half
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              '${averageRating.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              '(${reviews.length}개의 리뷰)',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 만족도 분포
        _buildRatingDistribution(reviews),
      ],
    );
  }

  Widget _buildRatingDistribution(List<ReviewModel> reviews) {
    // 각 별점별 개수 계산
    Map<int, int> ratingCounts = {};
    for (int i = 5; i >= 1; i--) {
      ratingCounts[i] =
          reviews.where((review) => review.satisfaction == i).length;
    }

    return Column(
      children:
          ratingCounts.entries.map((entry) {
            final percentage =
                reviews.isEmpty ? 0.0 : entry.value / reviews.length;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: [
                  Text(
                    '${entry.key}점',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildNoReviews() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      width: double.infinity,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '아직 리뷰가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '첫 번째 리뷰를 작성해보세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<ReviewModel> reviews) {
    final String baseDomain = _apiClient.getDomain;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final review = reviews[index];

        // 구매자(리뷰 작성자) 이름
        final String buyerName = review.buyerName;

        // 구매자 프로필 이미지 URL 처리
        String? fullBuyerProfileImageUrl;
        if (review.buyerProfileImageUrl != null &&
            review.buyerProfileImageUrl!.isNotEmpty) {
          fullBuyerProfileImageUrl =
              review.buyerProfileImageUrl!.startsWith('http')
                  ? review.buyerProfileImageUrl
                  : '$baseDomain${review.buyerProfileImageUrl}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 리뷰 헤더 (작성자, 별점, 날짜)
            Row(
              children: [
                // 구매자 프로필 이미지 - 이미지가 있으면 사용, 없으면 이니셜 표시
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      fullBuyerProfileImageUrl == null
                          ? _getInitialColor(
                            buyerName.isNotEmpty ? buyerName[0] : "?",
                          )
                          : null,
                  backgroundImage:
                      fullBuyerProfileImageUrl != null
                          ? NetworkImage(fullBuyerProfileImageUrl)
                          : null,
                  child:
                      fullBuyerProfileImageUrl == null
                          ? Text(
                            buyerName.isNotEmpty ? buyerName[0] : "?",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),

                const SizedBox(width: 8),

                // 구매자 이름으로 변경
                Text(
                  buyerName, // buyerName 사용
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),

                const Spacer(),

                // 별점
                Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Icon(
                        i < review.satisfaction
                            ? Icons.star
                            : Icons.star_border,
                        color:
                            i < review.satisfaction
                                ? Colors.amber
                                : Colors.grey[300],
                        size: 16,
                      ),
                  ],
                ),

                const SizedBox(width: 8),

                // 날짜
                Text(
                  DateFormat('yyyy.MM.dd').format(review.writedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 리뷰 내용
            Text(review.content, style: const TextStyle(fontSize: 14)),

            // 리뷰 이미지가 있을 경우 표시
            if (review.imagesUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imagesUrl.length,
                  itemBuilder: (context, imgIndex) {
                    final imageUrl = review.imagesUrl[imgIndex];
                    final fullImageUrl =
                        imageUrl.startsWith('http')
                            ? imageUrl
                            : '$baseDomain$imageUrl';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          fullImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            // 판매자 평가 표시 (Good, Bad인 경우)
            if (review.sellerEvaluation != 'None') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    review.sellerEvaluation == 'Good'
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    size: 14,
                    color:
                        review.sellerEvaluation == 'Good'
                            ? Colors.blue
                            : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.sellerEvaluation == 'Good' ? '추천해요' : '비추천해요',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          review.sellerEvaluation == 'Good'
                              ? Colors.blue
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  // 이니셜에 따라 색상을 지정하는 함수 추가
  Color _getInitialColor(String initial) {
    final colors = [
      Colors.blue[700]!,
      Colors.red[700]!,
      Colors.green[700]!,
      Colors.orange[700]!,
      Colors.purple[700]!,
      Colors.teal[700]!,
      Colors.pink[700]!,
      Colors.indigo[700]!,
    ];

    // 이니셜 문자의 코드값을 기반으로 색상 선택
    final colorIndex = initial.codeUnitAt(0) % colors.length;
    return colors[colorIndex];
  }
}
