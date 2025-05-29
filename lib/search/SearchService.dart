import 'package:dio/dio.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/post/postDataFile.dart';

class SearchService {
  final Dio _dio = ApiClient().client;

  Future<List<Product>> searchProducts({
    required String query,
    String? category,
    String? maxCreatedAt,
  }) async {
    final queryParameters = <String, dynamic>{};

    // 카테고리 배열로 전달 (API에서 []로 받는지 확인 필요)
    if (category != null && category.isNotEmpty) {
      print('카테고리 ${category}');
      queryParameters['Categorys'] = [category];
    }

    // 제목 키워드 배열로 전달
    if (query.isNotEmpty) {
      queryParameters['TitleWords'] = [query];
    }

    // maxCreatedAt (페이징용)
    if (maxCreatedAt != null) {
      queryParameters['MaxCreatedAt'] = maxCreatedAt;
    }

    final response = await _dio.get('/Product/posts', queryParameters: queryParameters);
    final List<dynamic> data = response.data;
    return data.map((json) => Product.fromJson(json)).toList();
  }

  Future<List<BuyerPost>> searchBuyerPosts({
    List<String>? category,
    String? maxCreatedAt,
    List<String>? titleWords,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (category != null) queryParameters['Category'] = category;
    if (maxCreatedAt != null) queryParameters['MaxCreatedAt'] = maxCreatedAt;
    if (titleWords != null && titleWords.isNotEmpty) {
      for (var word in titleWords) {
        queryParameters.putIfAbsent('TitleWords', () => []).add(word);
      }
    }

    final response = await ApiClient().dio.get(
      '/Post/posts',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data is List) {
      return (response.data as List).map((e) => BuyerPost.fromJson(e)).toList();
    } else {
      return [];
    }
  }
}
