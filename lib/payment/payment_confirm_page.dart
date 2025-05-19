import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat/chat.dart';
import '../chat/trade_button_service.dart';
import 'payment_method_page.dart';

class PaymentConfirmPage extends StatelessWidget {
  final Product product;
  final int itemId;
  final String buyerName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final int deposit;
  final int tradeOfferVersion; // 추가된 필드

  const PaymentConfirmPage({
    Key? key,
    required this.product,
    required this.itemId,
    required this.buyerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deposit,
    required this.tradeOfferVersion, // 필수 파라미터로 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    final numberFormat = NumberFormat('#,###');
    final int totalAmount = totalPrice + deposit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '결제 확인',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 상품 정보 카드
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // 상품 이미지
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
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
                                    : const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                    ),
                          ),
                          const SizedBox(width: 16),
                          // 상품 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '대여 비용: ${numberFormat.format(totalPrice)}원',
                                  style: const TextStyle(fontSize: 15),
                                ),
                                Text(
                                  '보증금: ${numberFormat.format(deposit)}원',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 결제 정보 섹션
                    const Text(
                      '결제 정보',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 결제 정보 내용
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPaymentInfoRow(
                                '대여 시작일',
                                dateFormat.format(startDate),
                              ),
                              const SizedBox(height: 8),
                              _buildPaymentInfoRow(
                                '대여 종료일',
                                dateFormat.format(endDate),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildPaymentInfoRow(
                            '대여 비용',
                            '${numberFormat.format(totalPrice)}원',
                          ),
                          const SizedBox(height: 8),
                          _buildPaymentInfoRow(
                            '보증금',
                            '${numberFormat.format(deposit)}원',
                          ),
                          const Divider(height: 24),
                          _buildPaymentInfoRow(
                            '총 결제 금액',
                            '${numberFormat.format(totalAmount)}원',
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            valueStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3154FF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 안내 사항
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Color(0xFF3154FF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '안내 사항',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• 대여 기간이 종료되면 보증금은 자동으로 환불됩니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 대여 물품 훼손 시 보증금에서 차감될 수 있습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• 상품 수령 후 취소는 불가능합니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 결제하기 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PaymentMethodPage(
                              product: product,
                              itemId: itemId,
                              buyerName: buyerName,
                              sellerName: "판매자", // 실제로는 API에서 받아온 판매자 정보 사용
                              startDate: startDate,
                              endDate: endDate,
                              totalPrice: totalPrice,
                              deposit: deposit,
                              tradeOfferVersion: tradeOfferVersion, // 버전 정보 추가
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3154FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${numberFormat.format(totalAmount)}원 결제하기',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 결제 정보 행 위젯
  Widget _buildPaymentInfoRow(
    String title,
    String value, {
    TextStyle? titleStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ?? TextStyle(fontSize: 15, color: Colors.grey[800]),
        ),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
