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
        print("리뷰 불러오기 실패");
        return [];
      }
    } catch (e) {
      print("리뷰 불러오기 실패");
      return [];
    }
  }

  // 상품 리뷰 가져오기 메서드 추가 (GET 방식)
  Future<List<ReviewModel>> fetchProductReviews(int itemId) async {
    try {
      final response = await _apiClient.client.get(
        '/Product/review',
        queryParameters: {'itemId': itemId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewsData = response.data;
        return reviewsData.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<ReviewModel>> fetchAllProductReviews(int itemId) async {
    try {
      final response = await ApiClient().client.get(
        '/My/reviews?itemId=$itemId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> reviewsData = response.data;
        return reviewsData.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        return [];
      }
    } on DioError catch (e) {
      print("리뷰 불러오기 실패: ${e.message}");
      return [];
    }
  }
}
