import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import 'chat.dart';
import '../payment/payment_confirm_page.dart';

class TradeOfferRequest {
  final int itemId;
  final String? buyerName;
  final num price;
  final String priceUnit;
  final num securityDeposit;
  final String? borrowStartAt;
  final String? returnAt;

  TradeOfferRequest({
    required this.itemId,
    this.buyerName,
    required this.price,
    required this.priceUnit,
    required this.securityDeposit,
    this.borrowStartAt,
    this.returnAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'buyerName': buyerName,
      'price': price,
      'priceUnit': priceUnit,
      'securityDeposit': securityDeposit,
      'borrowStartAt': borrowStartAt,
      'returnAt': returnAt,
    };
  }
}

class TradeButtonService {
  final ApiClient _apiClient = ApiClient();

  // 판매자/구매자에 따라 적절한 버튼 반환
  Widget buildTradeButton({
    required bool isSeller,
    required Product product,
    required VoidCallback onProductEdit,
    required Function(BuildContext) onPurchase,
    required BuildContext context,
    required String callerName,
    required int itemId,
  }) {
    return TextButton(
      onPressed:
          isSeller
              ? onProductEdit
              : () => showPurchaseModal(context, product, callerName, itemId),
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF3154FF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        fixedSize: const Size(90, 30),
      ),
      child: Text(isSeller ? '상품수정' : '구매하기'),
    );
  }

  // 구매하기 모달 표시 함수
  void showPurchaseModal(
    BuildContext context,
    Product product,
    String callerName,
    int itemId, {
    DateTime? startDate, // 판매자가 설정한 시작일
    DateTime? endDate, // 판매자가 설정한 종료일
  }) {
    // 가격 문자열을 적절하게 숫자로 변환하는 부분 수정
    int price;
    int deposit;

    try {
      // 가격에서 콤마 제거
      String cleanPrice = product.price.replaceAll(',', '');
      // 소수점이 있는 경우 적절하게 처리
      if (cleanPrice.contains('.')) {
        double doublePrice = double.parse(cleanPrice);
        price = doublePrice.toInt();
      } else {
        // 소수점이 없는 경우 기존 방식대로 숫자만 추출
        price = int.tryParse(cleanPrice.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }

      // 보증금도 같은 방식으로 처리
      String cleanDeposit = product.deposit.replaceAll(',', '');
      if (cleanDeposit.contains('.')) {
        double doubleDeposit = double.parse(cleanDeposit);
        deposit = doubleDeposit.toInt();
      } else {
        deposit =
            int.tryParse(cleanDeposit.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      }
    } catch (e) {
      // 변환 오류 시 기본값 사용
      price = 0;
      deposit = 0;
    }

    // 대여 시작일/종료일 - 판매자가 설정한 날짜를 사용하거나 기본값 설정
    DateTime borrowStartDate = startDate ?? DateTime.now();
    DateTime returnDate =
        endDate ?? borrowStartDate.add(const Duration(days: 6));

    // 총 대여일수
    int totalDays = returnDate.difference(borrowStartDate).inDays + 1;

    // 총 가격 계산
    int totalPrice = _calculateTotalPrice(price, product.priceUnit, totalDays);

    // 날짜 포맷
    final dateFormat = DateFormat('yyyy년 MM월 dd일');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 상품 제목
                    Row(
                      children: [
                        // 상품 이미지
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child:
                              product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      product.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[500],
                                          ),
                                    ),
                                  )
                                  : Center(
                                    child: Text(
                                      '예제\n상품',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 가격 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '대여 가격 :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_convertPriceUnitToKorean(product.priceUnit)} ${_formatPrice(product.price)}원',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 보증금 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '보증금 :',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatPrice(product.deposit)}원',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 대여 기간 표시 - 수정 불가능하게 변경
                    const Text(
                      '대여 기간',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 시작일 - 읽기 전용으로 변경
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // 배경색 변경으로 읽기 전용 표시
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(borrowStartDate),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800], // 약간 더 어두운 색상
                            ),
                          ),
                          const Text('부터', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 종료일 - 읽기 전용으로 변경
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100], // 배경색 변경으로 읽기 전용 표시
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(returnDate),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800], // 약간 더 어두운 색상
                            ),
                          ),
                          const Text('까지', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 총 가격 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '총 가격 :',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(totalPrice)}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 버튼 영역
                    Row(
                      children: [
                        // 취소 버튼
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('취소'),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // 결제하기 버튼
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              // 모달 닫기
                              Navigator.pop(context);

                              // 결제 확인 페이지로 이동
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PaymentConfirmPage(
                                        product: product,
                                        itemId: itemId,
                                        buyerName: callerName,
                                        startDate: borrowStartDate,
                                        endDate: returnDate,
                                        totalPrice: totalPrice,
                                        deposit: deposit,
                                      ),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF3154FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('결제하기'),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 영어 단위를 한글로 변환하는 함수
  String _convertPriceUnitToKorean(String unit) {
    switch (unit.toLowerCase()) {
      case 'day':
        return '일';
      case 'week':
        return '주';
      case 'month':
        return '월';
      case 'year':
        return '년';
      default:
        return unit;
    }
  }

  // 한글 단위를 영어로 변환하는 함수
  String _convertToServerPriceUnit(String unit) {
    Map<String, String> reverseUnitMapping = {
      '일': 'Day',
      '주': 'Week',
      '월': 'Month',
      '년': 'Year',
    };

    return reverseUnitMapping[unit] ?? unit;
  }

  // 가격 포맷팅 함수
  String _formatPrice(String price) {
    if (price.isEmpty) return '0';

    try {
      String cleanPrice = price.replaceAll(',', '');
      if (cleanPrice.contains('.')) {
        double value = double.parse(cleanPrice);
        return NumberFormat('#,###').format(value.toInt());
      } else {
        int value = int.parse(cleanPrice);
        return NumberFormat('#,###').format(value);
      }
    } catch (e) {
      return price;
    }
  }

  // 총 가격 계산 함수
  int _calculateTotalPrice(int basePrice, String priceUnit, int days) {
    switch (priceUnit.toLowerCase()) {
      case 'day':
        return basePrice * days;
      case 'week':
        return basePrice * ((days + 6) ~/ 7); // 일주일로 올림 계산
      case 'month':
        return basePrice * ((days + 29) ~/ 30); // 한 달로 올림 계산
      default:
        return basePrice * days;
    }
  }

  // 대여 요청 보내기
  Future<void> sendTradeOffer({
    required int itemId,
    required String buyerName,
    required String price,
    required String priceUnit,
    required String deposit,
    required String borrowStartAt,
    required String returnAt,
    required Function(String) onError,
  }) async {
    try {
      // 숫자 값 변환
      num priceValue;
      num depositValue;

      try {
        priceValue = num.parse(price);
        depositValue = num.parse(deposit);
      } catch (e) {
        onError('가격 또는 보증금 값이 올바르지 않습니다.');
        return;
      }

      // API 요청 데이터 준비
      final request = TradeOfferRequest(
        itemId: itemId,
        buyerName: buyerName,
        price: priceValue,
        priceUnit: priceUnit,
        securityDeposit: depositValue,
        borrowStartAt: borrowStartAt,
        returnAt: returnAt,
      );

      // API 요청 실행
      final response = await _apiClient.client.post(
        '/chat/TradeOffer',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        onError('서버 응답 오류: ${response.statusCode}');
      }
    } catch (e) {
      // 에러 타입에 따른 처리
      if (e.toString().contains('400')) {
        if (e.toString().contains('거래 오퍼를 찾을 수 없습니다')) {
          onError('거래 오퍼를 찾을 수 없습니다.');
        } else if (e.toString().contains('잘못된 거래 오퍼입니다')) {
          onError('잘못된 거래 오퍼입니다.');
        } else {
          onError('요청을 처리할 수 없습니다: ${e.toString()}');
        }
      } else {
        onError('네트워크 오류가 발생했습니다: ${e.toString()}');
      }
    }
  }

  // 상품 정보 업데이트 함수
  Future<bool> updateProductOffer({
    required int itemId,
    required String title,
    required String price,
    required String priceUnit,
    required String deposit,
    required String buyerName,
    String? borrowStartAt, // 시작 날짜 추가
    String? returnAt, // 종료 날짜 추가
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // 숫자 값 변환
      num priceValue;
      num depositValue;

      try {
        String cleanPrice = price.replaceAll(',', '');
        priceValue = num.parse(cleanPrice);

        String cleanDeposit = deposit.replaceAll(',', '');
        depositValue = num.parse(cleanDeposit);
      } catch (e) {
        // onError 호출 전에 이벤트 루프를 사용하여 현재 실행 컨텍스트 벗어나기
        Future.microtask(() => onError('가격 또는 보증금 값이 올바르지 않습니다.'));
        return false;
      }

      // API 요청 데이터 준비
      final request = TradeOfferRequest(
        itemId: itemId,
        buyerName: buyerName,
        price: priceValue,
        priceUnit: priceUnit,
        securityDeposit: depositValue,
        borrowStartAt: borrowStartAt, // 시작 날짜 추가
        returnAt: returnAt, // 종료 날짜 추가
      );

      // API 호출
      final response = await _apiClient.client.post(
        '/chat/TradeOffer',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // 콜백을 microtask로 예약하여 현재 실행 컨텍스트 벗어나기
        Future.microtask(() => onSuccess('상품 정보가 성공적으로 수정되었습니다.'));
        return true;
      } else {
        Future.microtask(() => onError('서버 응답 오류: ${response.statusCode}'));
        return false;
      }
    } catch (e) {
      // 에러 처리도 microtask로 전환
      String errorMessage = '네트워크 오류가 발생했습니다: ${e.toString()}';

      if (e.toString().contains('400')) {
        if (e.toString().contains('거래 오퍼를 찾을 수 없습니다')) {
          errorMessage = '거래 오퍼를 찾을 수 없습니다.';
        } else if (e.toString().contains('잘못된 거래 오퍼입니다')) {
          errorMessage = '잘못된 거래 오퍼입니다.';
        } else if (e.toString().contains('거래 오퍼를 수정할 수 없습니다')) {
          errorMessage = '거래 오퍼를 수정할 수 없습니다.';
        } else {
          errorMessage = '요청을 처리할 수 없습니다: ${e.toString()}';
        }
      }

      Future.microtask(() => onError(errorMessage));
      return false;
    }
  }

  // API 응답에서 Product 객체 생성
  Product createProductFromApiResponse(
    dynamic data,
    String callerName,
    bool isSeller,
  ) {
    // offer 데이터가 있는 경우
    if (data['offer'] != null) {
      final imageUrl = data['offer']['imageUrl'];
      String? fullImageUrl;

      if (imageUrl is String && imageUrl.isNotEmpty && imageUrl != "string") {
        fullImageUrl = '${_apiClient.getDomain}$imageUrl';
      }

      return Product(
        title: data['offer']['title'] ?? '상품 정보 없음',
        price: data['offer']['price']?.toString() ?? '0',
        priceUnit: data['offer']['priceUnit'] ?? '일',
        deposit: data['offer']['securityDeposit']?.toString() ?? '0',
        imageUrl: fullImageUrl,
      );
    } else {
      // 기본 값 반환
      return Product(
        title: "상품 정보를 불러올 수 없습니다",
        price: "0",
        priceUnit: "일",
        deposit: "0",
      );
    }
  }
}
