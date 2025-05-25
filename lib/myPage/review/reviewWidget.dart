import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';

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
    if (review.sellerProfileImageUrl != null &&
        review.sellerProfileImageUrl!.isNotEmpty) {
      if (review.sellerProfileImageUrl!.startsWith('http')) {
        fullProfileImageUrl = review.sellerProfileImageUrl;
      } else {
        fullProfileImageUrl = '$baseDomain${review.sellerProfileImageUrl}';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      const SizedBox(height: 4),

                      // 리뷰 작성자/판매자 정보
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[300],
                            backgroundImage:
                                fullProfileImageUrl != null
                                    ? NetworkImage(fullProfileImageUrl)
                                    : null,
                            child:
                                fullProfileImageUrl == null
                                    ? Text(
                                      review.sellerName.isNotEmpty
                                          ? review.sellerName[0]
                                          : "?",
                                      style: TextStyle(color: Colors.grey[700]),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isMyReview
                                  ? '${review.sellerName}님에게 보낸 리뷰'
                                  : '${review.sellerName}님에게서 받은 리뷰',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // 만족도 표시
                      Row(
                        children: [
                          for (int i = 0; i < 5; i++)
                            Icon(
                              Icons.star,
                              size: 16,
                              color:
                                  i < review.satisfaction
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                            ),
                          const SizedBox(width: 4),
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
                        DateFormat('yyyy.MM.dd').format(review.writedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // 내가 작성한 리뷰일 경우 수정 버튼
                if (isMyReview && onEdit != null)
                  TextButton(
                    onPressed: onEdit,
                    child: const Text(
                      '수정하기',
                      style: TextStyle(color: Color(0xFF4B70FD), fontSize: 12),
                    ),
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
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imagesUrl.length,
                  itemBuilder: (context, index) {
                    final imageUrl = review.imagesUrl[index];
                    final fullImageUrl =
                        imageUrl.startsWith('http')
                            ? imageUrl
                            : '$baseDomain$imageUrl';

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fullImageUrl,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
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
                    size: 16,
                    color:
                        review.sellerEvaluation == 'Good'
                            ? Colors.green
                            : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.sellerEvaluation == 'Good' ? '추천해요' : '비추천해요',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          review.sellerEvaluation == 'Good'
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
