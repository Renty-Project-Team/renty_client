import 'productDataFile.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/core/api_client.dart'; // ApiClient 가져오기

class ProductService {
  Future<Product> fetchProduct(int itemId) async {
    try {
      final response = await ApiClient().client.get('/Product/detail?itemId=$itemId'); // api_client의 dio 사용
      return Product.fromJson(response.data);
    } on DioError catch (e) {
      // 에러 로깅
      print("DioError: ${e.response?.statusCode} ${e.message}");
      throw Exception("상품 정보를 불러오는데 실패했습니다.");
    }
  }
}
