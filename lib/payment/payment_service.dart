import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// 결제 API 호출
  /// itemId: 상품 ID
  /// tradeOfferVersion: 상품 정보 버전 (버전 불일치 시 409 에러)
  Future<Map<String, dynamic>> completePayment({
    required int itemId,
    required int tradeOfferVersion,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      await _apiClient.initialize();

      print('==== 결제 요청 데이터 ====');
      print('itemId: $itemId');
      print('tradeOfferVersion: $tradeOfferVersion');

      // POST /api/Transaction/payments API 호출
      final response = await _apiClient.client.post(
        '/Transaction/payments',
        data: {"itemId": itemId, "tradeOfferVersion": tradeOfferVersion},
      );

      print('==== 결제 응답 ====');
      print('상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.data}');

      if (response.statusCode == 200) {
        onSuccess('결제가 성공적으로 완료되었습니다.');
        return response.data;
      } else {
        onError('결제 처리 중 오류가 발생했습니다. (${response.statusCode})');
        return {};
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // 버전 불일치 오류 - 판매자가 상품 정보를 최근에 수정함
        onError('판매자가 상품 정보를 변경했습니다. 최신 정보로 다시 시도해주세요.');
      } else {
        onError('결제 요청 중 오류가 발생했습니다: ${e.message}');
      }
      return {};
    } catch (e) {
      onError('결제 처리 중 예상치 못한 오류가 발생했습니다: $e');
      return {};
    }
  }
}
