import 'postDataFile.dart';
import 'package:renty_client/core/api_client.dart';
import 'dart:convert';

class PostService {
  Future<List<Product>> fetchProducts({
    List<String>? categorys,
    String? maxCreatedAt,
    List<String>? titleWords
  }) async {
    final client = ApiClient().client;

    final queryParams = <String, dynamic>{};
    if (categorys != null) queryParams['Categorys'] = categorys;
    if (maxCreatedAt != null) queryParams['MaxCreatedAt'] = maxCreatedAt;
    if (titleWords != null) queryParams['TitleWords'] = titleWords;

    try {
      final response = await client.get('/Product/posts', queryParameters: queryParams);
      List data = response.data;  // 이미 List<dynamic>임

      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('API error: $e');
      throw Exception('상품 목록 불러오기 실패');
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
    } catch (e) {
      print('API error (buyer posts): $e');
      throw Exception('구매자 게시글 불러오기 실패');
    }
  }
}


