import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final ApiClient apiClient;
  final bool isMyReview;
  final String currentUserName;
  final VoidCallback? onEdit;

  const ReviewCard({
    Key? key,
    required this.review,
    required this.apiClient,
    required this.isMyReview,
    required this.currentUserName,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String baseDomain = apiClient.getDomain;

    // 프로필 이미지 URL 처리
    String? fullProfileImageUrl;
    if (isMyReview) {
      // 내가 작성한 리뷰인 경우 - 구매자(나)의 프로필 표시
      if (review.buyerProfileImageUrl != null &&
          review.buyerProfileImageUrl!.isNotEmpty) {
        fullProfileImageUrl =
            review.buyerProfileImageUrl!.startsWith('http')
                ? review.buyerProfileImageUrl
                : '$baseDomain${review.buyerProfileImageUrl}';
      }
    } else {
      // 받은 리뷰인 경우 - 구매자(리뷰 작성자)의 프로필 표시
      if (review.buyerProfileImageUrl != null &&
          review.buyerProfileImageUrl!.isNotEmpty) {
        fullProfileImageUrl =
            review.buyerProfileImageUrl!.startsWith('http')
                ? review.buyerProfileImageUrl
                : '$baseDomain${review.buyerProfileImageUrl}';
      }
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지 및 정보 헤더
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review.itemImageUrl.startsWith('http')
                          ? review.itemImageUrl
                          : '$baseDomain${review.itemImageUrl}',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text(
                              '이미지\n없음',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 상품 정보 및 사용자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.itemTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
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
                              '${review.satisfaction}/5',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 내가 작성한 리뷰일 경우 수정 버튼
                  if (isMyReview && onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4B70FD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        '수정',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 구분선
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // 리뷰 내용 및 이미지
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 작성자 정보
                  Row(
                    children: [
                      // 프로필 이미지
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              fullProfileImageUrl == null
                                  ? _getInitialColor(
                                    isMyReview
                                        ? review.buyerName
                                        : review.buyerName,
                                  )
                                  : null,
                          image:
                              fullProfileImageUrl != null
                                  ? DecorationImage(
                                    image: NetworkImage(fullProfileImageUrl),
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
                            fullProfileImageUrl == null
                                ? Center(
                                  child: Text(
                                    isMyReview
                                        ? (review.buyerName.isNotEmpty
                                            ? review.buyerName[0]
                                            : "?")
                                        : (review.buyerName.isNotEmpty
                                            ? review.buyerName[0]
                                            : "?"),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMyReview
                              ? '${review.buyerName}님이 작성한 리뷰'
                              : '${review.buyerName}님이 작성한 리뷰',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 리뷰 내용
                  Text(
                    review.content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey[800],
                    ),
                  ),

                  // 리뷰 이미지가 있을 경우 표시
                  if (review.imagesUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            review.imagesUrl.map((imageUrl) {
                              final fullImageUrl =
                                  imageUrl.startsWith('http')
                                      ? imageUrl
                                      : '$baseDomain$imageUrl';

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fullImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Text(
                                              '이미지 로드 오류',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
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
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
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
                                    ? Colors.green[600]
                                    : Colors.red[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.sellerEvaluation == 'Good' ? '좋아요' : '별로예요',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color:
                                  review.sellerEvaluation == 'Good'
                                      ? Colors.green[600]
                                      : Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
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
