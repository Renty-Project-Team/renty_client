import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';
import 'package:renty_client/myPage/review/reviewService.dart';
import 'package:renty_client/myPage/review/reviewWidget.dart';

class ReceivedReviewsPage extends StatefulWidget {
  final String currentUserName;

  const ReceivedReviewsPage({Key? key, required this.currentUserName})
    : super(key: key);

  @override
  State<ReceivedReviewsPage> createState() => _ReceivedReviewsPageState();
}

class _ReceivedReviewsPageState extends State<ReceivedReviewsPage> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<ReviewModel>> _reviewsFuture;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  void _loadReviews() {
    _reviewsFuture = _reviewService.fetchAllReviews().then((reviews) {
      // 받은 리뷰만 필터링 (내가 판매자인 경우)
      return reviews
          .where((review) => review.sellerName == widget.currentUserName)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '받은 리뷰',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<ReviewModel>>(
        future: _reviewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '받은 리뷰가 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final reviews = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ReviewCard(
                review: review,
                apiClient: _apiClient,
                isMyReview: false,
                currentUserName: widget.currentUserName,
                // 구매자 프로필 이미지 관련 로직은 ReviewCard 내에서 처리
              );
            },
          );
        },
      ),
    );
  }
}
