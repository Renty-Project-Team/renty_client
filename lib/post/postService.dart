import 'postDataFile.dart';
import 'package:renty_client/core/api_client.dart';
import 'dart:convert';
import 'package:dio/dio.dart';

class PostService {
  Future<List<Product>> fetchProducts({
    List<String>? categorys,
    String? maxCreatedAt,
    List<String>? titleWords,
  }) async {
    final client = ApiClient().client;
    final queryParams = <String, dynamic>{};
    if (categorys != null) queryParams['Categorys'] = categorys;
    if (maxCreatedAt != null) queryParams['MaxCreatedAt'] = maxCreatedAt;
    if (titleWords != null) queryParams['TitleWords'] = titleWords;

    try {
      final response = await client.get('/Product/posts', queryParameters: queryParams);
      List data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // ❗ 조건 불일치 → 더 불러올 데이터 없음
      }
      rethrow;
    }
  }

  Future<List<BuyerPost>> fetchBuyerPosts({
    List<String>? categorys,
    String? maxCreatedAt,
    List<String>? titleWords,
  }) async {
    final client = ApiClient().client;
    final queryParams = <String, dynamic>{};
    if (categorys != null) queryParams['Categorys'] = categorys;
    if (maxCreatedAt != null) queryParams['MaxCreatedAt'] = maxCreatedAt;
    if (titleWords != null) queryParams['TitleWords'] = titleWords;

    try {
      final response = await client.get('/Post/posts', queryParameters: queryParams);
      List data = response.data;
      return data.map((json) => BuyerPost.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return []; // ❗ 조건 불일치 → 더 불러올 데이터 없음
      }
      rethrow;
    }
  }
}


