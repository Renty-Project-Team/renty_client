import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';

class ReviewService {
  final ApiClient _apiClient = ApiClient();

  // 모든 리뷰 가져오기
  Future<List<ReviewModel>> fetchAllReviews() async {
    try {
      final response = await _apiClient.client.get('/My/review');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        throw Exception('리뷰를 불러오는데 실패했습니다');
      }
    } catch (e) {
      throw Exception('리뷰를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 상품의 리뷰만 가져오기
  Future<List<ReviewModel>> fetchProductReviews(int itemId) async {
    try {
      final allReviews = await fetchAllReviews();
      return allReviews.where((review) => review.itemId == itemId).toList();
    } catch (e) {
      throw Exception('상품 리뷰를 불러오는 중 오류가 발생했습니다: $e');
    }
  }
}
