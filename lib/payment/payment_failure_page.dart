import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../chat/chat_list.dart';
import '../chat/chat.dart';

class PaymentFailurePage extends StatelessWidget {
  final Product product;
  final int itemId;
  final String buyerName;
  final String sellerName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final int deposit;
  final String errorMessage;

  const PaymentFailurePage({
    Key? key,
    required this.product,
    required this.itemId,
    required this.buyerName,
    required this.sellerName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.deposit,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy년 MM월 dd일');
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('결제 실패'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          // 실패 아이콘
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEB), // 연한 빨간색 배경
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.close,
              size: 60,
              color: Color(0xFFFF3B30),
            ), // 빨간 X 아이콘
          ),

          const SizedBox(height: 24),

          const Text(
            '결제에 실패했습니다',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // 오류 메시지 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 16, color: Color(0xFFFF3B30)),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 32),

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

                  // 시작일과 종료일 표시
                  _buildInfoRow(
                    '대여 시작일',
                    DateFormat('yyyy년 MM월 dd일').format(startDate),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    '대여 종료일',
                    DateFormat('yyyy년 MM월 dd일').format(endDate),
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
                      // 채팅방으로 돌아가기
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => ChatListPage()),
                        (route) => route.isFirst, // 홈 화면만 남기고 모든 화면 제거
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
                      '채팅 목록으로 돌아가기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
        Flexible(
          child: Text(
            value,
            style:
                valueStyle ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
