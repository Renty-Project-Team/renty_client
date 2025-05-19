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
  Future<void> addToWishlist(int itemId) async {
    final response = await ApiClient().client.post(
      '/My/wishlist',
      data: {'itemId': itemId},
    );

    if (response.statusCode != 200) {
      throw Exception('찜 등록 실패');
    }
  }
  Future<bool> isWished(int itemId) async {
    try {
      final response = await ApiClient().client.get('/My/wishlist');

      if (response.statusCode == 200) {
        final List<dynamic> wishlist = response.data;

        return wishlist.any((item) {
          // 서버에서 'id' 필드가 itemId에 해당됨
          return item['id'] == itemId;
        });
      }
    }
    catch (e) {
      return false;
    }
    return false;
  }
  Future<void> removeFromWishlist(int itemId) async {
    final response = await ApiClient().client.delete(
      '/My/wishlist',
      data: {'itemId': itemId},
    );

    if (response.statusCode != 200) {
      throw Exception('찜 해제 실패');
    }
  }

}

