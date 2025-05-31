import 'package:renty_client/core/api_client.dart';
import 'buyerPostDataFile.dart';

class BuyerPostService {
  Future<List<BuyerPost>> fetchBuyerPosts({String? maxCreatedAt}) async {
    final client = ApiClient().client;

    final queryParams = <String, dynamic>{};
    if (maxCreatedAt != null) queryParams['MaxCreatedAt'] = maxCreatedAt;

    try {
      final response = await client.get(
        '/My/buyer-posts',
        queryParameters: queryParams,
      );
      List data = response.data;

      return data.map((json) => BuyerPost.fromJson(json)).toList();
    } catch (e) {
      print('API error: $e');
      // 예외를 던지는 대신 빈 리스트 반환하거나, 더 구체적인 에러 처리
      return []; // 또는 rethrow; 를 사용하여 예외를 다시 던짐
    }
  }
}
