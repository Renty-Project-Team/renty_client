import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/mypage/myRentPage/myRantOutData.dart';
import 'package:renty_client/mypage/myRentPage/postCard.dart';

class RentInDetailPage extends StatelessWidget {
  final RentOutItem item;
  const RentInDetailPage({super.key, required this.item});

  String formatDate(DateTime dateTime) {
    return DateFormat('yyyy. M. d').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("상세 내역")),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주문일 & 상품카드
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${formatDate(item.createdAt)} 주문",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ProductCardByItemId(item: item), // ✅ 상품 카드 위젯
                ],
              ),
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: "결제 정보",
              children: [
                _infoRow("상품 가격", "${item.finalPrice.toInt()}원"),
                _infoRow("보증금", "${item.finalSecurityDeposit.toInt()}원"),
                const Divider(),
                _infoRow("총 결제금액", "${item.finalPrice + item.finalSecurityDeposit.toInt()}원", isBold: true),
              ],
            ),

            _sectionCard(
              title: "판매자 정보",
              children: [
                Text("${item.buyerName} 님", style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                //const Text("주소/전화번호는 서버에서 제공되지 않음", style: TextStyle(color: Colors.black54)),
              ],
            ),

            _sectionCard(
              title: "대여 정보",
              children: [
                _infoRow("대여 시작일", formatDate(item.borrowStartAt)),
                _infoRow("반납 예정일", formatDate(item.returnAt)),
                _infoRow("현재 상태", _getKoreanState(item.state)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 상품 카드 위젯


  String _getKoreanState(String state) {
    switch (state) {
      case "PaymentCompleted":
        return "결제 완료";
      case "ShippingToBuyer":
        return "배송 중";
      case "RentalInProgress":
        return "대여 중";
      case "RentalOverdue":
        return "연체 중";
      case "ReturnPending":
        return "반납 대기";
      case "ReturnCompleted":
        return "반납 완료";
      case "Completed":
        return "보증금 환불 완료";
      case "CanceledBySeller":
        return "판매자 취소";
      case "CanceledByBuyer":
        return "구매자 취소";
      case "Disputed":
        return "분쟁 발생";
      case "Failed":
        return "결제 실패";
      default:
        return "알 수 없음";
    }
  }
}


