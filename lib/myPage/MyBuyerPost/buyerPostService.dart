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
      throw Exception('대여 요청 게시글 목록 불러오기 실패');
    }
  }
}
