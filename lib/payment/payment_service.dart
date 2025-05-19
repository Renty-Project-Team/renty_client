import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../payment/payment_failure_page.dart'; // PaymentFailurePage import 추가
import '../chat/chat.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// 결제 API 호출
  /// itemId: 상품 ID
  /// tradeOfferVersion: 상품 정보 버전 (버전 불일치 시 409 에러)
  Future<Map<String, dynamic>> completePayment({
    required int itemId,
    required int tradeOfferVersion,
    required Product product, // Product 객체 추가
    required String buyerName,
    required String sellerName,
    required DateTime startDate,
    required DateTime endDate,
    required int totalPrice,
    required int deposit,
    required Function(String) onSuccess,
    required Function(String) onError,
    required BuildContext context, // BuildContext 추가
  }) async {
    try {
      await _apiClient.initialize();

      print('==== 결제 요청 상세 정보 ====');
      print('상품 ID: $itemId');
      print('결제 시도 버전: $tradeOfferVersion');
      print('상품 정보: ${product.title}');
      print('가격: $totalPrice, 보증금: $deposit');
      print('대여 기간: ${startDate.toString()} ~ ${endDate.toString()}');

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
        print('==== 버전 불일치 오류 (409) ====');
        print('요청한 버전: $tradeOfferVersion');
        onError('판매자가 상품 정보를 변경했습니다. 최신 정보로 다시 시도해주세요.');
      } else if (e.response?.statusCode == 400) {
        print('==== 버전 불일치 오류 (400) ====');
        print('요청한 버전: $tradeOfferVersion');
        print('서버 응답: ${e.response?.data}');
        // 기본 오류 메시지
        String errorMessage = '결제 요청 처리 중 문제가 발생했습니다.';

        try {
          if (e.response?.data != null && e.response?.data is Map) {
            // 서버에서 보내는 Detail 필드에서 더 구체적인 한글 오류 메시지 추출
            if (e.response?.data['detail'] != null) {
              String serverMessage = e.response?.data['detail'];

              // 서버 메시지에 따라 사용자 정의 메시지로 변환
              Map<String, String> customErrorMessages = {
                "거래 요청을 찾을 수 없습니다.": "대여 요청 정보를 찾을 수 없습니다.\n다시 시도해 주세요.",
                "거래 요청이 최신 정보와 일치하지 않습니다.":
                    "판매자가 최근에 정보를 변경했습니다.\n최신 정보로 다시 시도해 주세요.",
                "이미 결제한 상품입니다.": "이미 결제가 완료된 상품입니다.",
                "날짜가 유효하지 않습니다.": "대여 기간이 정해지지 않았습니다.\n판매자와 대여 기간을을 상의해주세요.",
              };

              // 서버 메시지에 해당하는 사용자 정의 메시지가 있으면 사용, 없으면 원본 메시지 사용
              errorMessage =
                  customErrorMessages[serverMessage] ?? serverMessage;
            } else if (e.response?.data['Detail'] != null) {
              String serverMessage = e.response?.data['Detail'];

              // 같은 맵핑 적용
              Map<String, String> customErrorMessages = {
                "거래 요청을 찾을 수 없습니다.": "대여 요청 정보를 찾을 수 없습니다.\n다시 시도해 주세요.",
                "거래 요청이 최신 정보와 일치하지 않습니다.":
                    "판매자가 최근에 정보를 변경했습니다.\n최신 정보로 다시 시도해 주세요.",
                "이미 결제한 상품입니다.": "이미 결제가 완료된 상품입니다.",
                "날짜가 유효하지 않습니다.": "대여 기간이 정해지지 않았습니다.\n판매자와 대여 기간을을 상의해주세요.",
              };

              errorMessage =
                  customErrorMessages[serverMessage] ?? serverMessage;
            } else if (e.response?.data['title'] != null) {
              errorMessage = e.response?.data['title'];
            }

            // 서버 응답 전체 로깅 (디버깅용)
            print('서버 오류 응답: ${e.response?.data}');
          }
        } catch (_) {
          // 오류 메시지 파싱 실패 시 기본 메시지 유지
        }

        // 결제 실패 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentFailurePage(
                  product: product,
                  itemId: itemId,
                  buyerName: buyerName,
                  sellerName: sellerName,
                  startDate: startDate,
                  endDate: endDate,
                  totalPrice: totalPrice,
                  deposit: deposit,
                  errorMessage: errorMessage,
                ),
          ),
        );
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
