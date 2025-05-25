import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';

class ReviewService {
  final ApiClient _apiClient = ApiClient();

  Future<List<ReviewModel>> fetchAllReviews() async {
    try {
      final response = await _apiClient.client.get('/My/review');

      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = response.data;
        return reviewsJson.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      throw Exception('Failed to load reviews');
    }
  }
}
