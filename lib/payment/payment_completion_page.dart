import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../myPage/rental_list_page.dart';
import '../chat/chat.dart';

class PaymentCompletionPage extends StatelessWidget {
  final Product product;
  final int itemId;
  final String buyerName;
  final String sellerName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final int deposit;

  const PaymentCompletionPage({
    Key? key,
    required this.product,
    required this.itemId,
    required this.buyerName,
    required this.sellerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deposit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('결제 완료'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // 성공 아이콘
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFEEFBF1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.check, size: 60, color: Color(0xFF4CD964)),
          ),

          const SizedBox(height: 24),

          const Text(
            '결제가 완료되었습니다',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 40),

          // 결제 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow('상품명', product.title),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    '대여 기간',
                    '${dateFormat.format(startDate)} ~ ${dateFormat.format(endDate)}',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('대여료', '${numberFormat.format(totalPrice)}원'),
                  const SizedBox(height: 12),
                  _buildInfoRow('보증금', '${numberFormat.format(deposit)}원'),
                  const Divider(height: 24),
                  _buildInfoRow(
                    '총 결제금액',
                    '${numberFormat.format(totalPrice + deposit)}원',
                    titleStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    valueStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3154FF),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 하단 버튼
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // 마이페이지의 대여중인 제품 화면으로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const RentalListPage(showActiveOnly: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3154FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '대여중인 제품 보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () {
                      // 채팅방 화면으로 돌아가기
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text(
                      '채팅으로 돌아가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
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
          style: titleStyle ?? TextStyle(fontSize: 16, color: Colors.grey),
        ),
        Text(
          value,
          style:
              valueStyle ??
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
