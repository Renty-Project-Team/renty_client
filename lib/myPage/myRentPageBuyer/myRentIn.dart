import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/main.dart';
import '../../core/api_client.dart';
import 'package:renty_client/myPage/review/writeReview.dart';
import 'package:renty_client/myPage/review/editReview.dart'; // EditReviewScreen 추가
import 'package:renty_client/myPage/review/reviewModel.dart'; // ReviewModel 추가
import 'package:renty_client/myPage/review/reviewService.dart'; // ReviewService 추가
import 'myRentInService.dart';
import 'package:renty_client/mypage/myRentPage/myRantOutData.dart';
import 'RentInDetail.dart';
import 'package:renty_client/chat/chat.dart';

class MyRentInPage extends StatefulWidget {
  const MyRentInPage({super.key});

  @override
  State<MyRentInPage> createState() => _MyRentInPageState();
}

class _MyRentInPageState extends State<MyRentInPage> {
  List<RentOutItem> _items = [];
  bool _isLoading = true;
  // 리뷰 서비스 인스턴스 생성
  final ReviewService _reviewService = ReviewService();
  // 상품 ID별 리뷰 정보 저장
  final Map<int, ReviewModel?> _reviewsByItemId = {};

  @override
  void initState() {
    super.initState();
    fetchRentOutItems();
    fetchExistingReviews(); // 기존 리뷰 로드
  }

  // 기존 리뷰 데이터를 불러오는 함수
  Future<void> fetchExistingReviews() async {
    try {
      final reviews = await _reviewService.fetchAllReviews();
      setState(() {
        // 상품 ID별로 리뷰 정보 저장
        for (var review in reviews) {
          _reviewsByItemId[review.itemId] = review;
        }
      });
    } catch (e) {
      print('리뷰 불러오기 실패: $e');
    }
  }

  Future<void> fetchRentOutItems() async {
    setState(() => _isLoading = true);
    final items = await RentInService.fetchRentOutItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("대여중인 제품목록")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Text("대여중인 제품이 없습니다."))
              : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final step = getCurrentStep(item.state);
                  if (step == -1) return const SizedBox(); // 취소된 건 생략

                  final imageUrl = '${apiClient.getDomain}${item.imgUrl}';
                  // 이 상품에 대한 리뷰가 있는지 확인
                  final hasReview = _reviewsByItemId.containsKey(item.itemId);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step == 0)
                            Text(
                              '결제완료 | 대여시작일: ${DateFormat('yyyy.MM.dd').format(item.borrowStartAt)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (step == 1)
                            Text(
                              '대여중 | 반납일: ${DateFormat('yyyy.MM.dd').format(item.returnAt)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (step == 2)
                            const Text(
                              '보증금 환불 예정',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (step == 3)
                            const Text(
                              '거래 완료',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (step == -1)
                            const Text(
                              '판매자 문의',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이미지 (왼쪽)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 텍스트 (오른쪽)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "상품금액: ${NumberFormat("#,###").format((item.finalPrice).toInt())}원",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "보증금: ${NumberFormat("#,###").format((item.finalSecurityDeposit).toInt())}원",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          StepProgressBar(currentStep: step, state: item.state),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  int? chatRoomId = item.roomId;

                                  if (chatRoomId == null) {
                                    final chatRoom =
                                        await RentInService.createOrGetChatRoom(
                                          item.itemId,
                                        );
                                    if (chatRoom != null) {
                                      chatRoomId = chatRoom['chatRoomId'];
                                    }
                                  }

                                  if (chatRoomId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ChatScreen(
                                              chatRoomId: chatRoomId!,
                                              roomName: item.buyerName ?? '구매자',
                                              profileImageUrl: item.imgUrl,
                                              product: null,
                                              isBuyer: true,
                                            ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('채팅방에 입장할 수 없습니다.'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text("구매자 채팅"),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => RentInDetailPage(item: item),
                                    ),
                                  );
                                },
                                child: const Text("상세 내역"),
                              ),
                            ],
                          ),
                          // 리뷰 버튼을 아래로 이동
                          const SizedBox(height: 12),
                          // 리뷰 작성/수정 버튼 (항상 활성화 상태)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // 이미 리뷰가 있는지 확인하고 해당 리뷰 가져오기
                                final existingReview =
                                    _reviewsByItemId[item.itemId];

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            existingReview != null
                                                // 기존 리뷰가 있으면 수정 화면으로 이동
                                                ? EditReviewScreen(
                                                  review: existingReview,
                                                )
                                                // 없으면 새로운 리뷰 작성 화면으로 이동
                                                : ReviewWritePage(
                                                  itemId: item.itemId,
                                                  productTitle: item.title,
                                                  productImageUrl:
                                                      item.imgUrl != null
                                                          ? '${ApiClient().getDomain}${item.imgUrl}'
                                                          : null,
                                                  rentalDate: item.returnAt,
                                                  sellerName:
                                                      item.buyerName ??
                                                      '알 수 없음',
                                                  sellerProfileImageUrl:
                                                      item.profileImage,
                                                ),
                                  ),
                                );

                                // 리뷰 작성/수정이 완료된 경우
                                if (result == true) {
                                  // 리뷰 목록 새로고침
                                  fetchExistingReviews();
                                }
                              },
                              icon: const Icon(Icons.rate_review),
                              // 리뷰 상태에 따라 버튼 텍스트 변경
                              label: Text(hasReview ? "리뷰 수정하기" : "리뷰 작성하기"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B70FD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

// ✅ 진행 단계 바 + 현재 상태 텍스트 강조
Widget StepProgressBar({required int currentStep, required String state}) {
  const stepLabels = ['결제완료', '대여중', '반납', '보증금\n환불']; // 줄바꿈도 적용

  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final barWidth = width - 32; // 좌우 padding 고려
      return Column(
        children: [
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                // ✅ 상태바 배경
                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ✅ 상태바 진행
                Positioned(
                  top: 20,
                  left: 16,
                  child: Container(
                    height: 4,
                    width: barWidth * ((currentStep + 1) / 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ✅ 동그라미 + 라벨을 정확한 위치에 배치
                ...List.generate(4, (index) {
                  final isActive = index <= currentStep;
                  final isCurrent = index == currentStep;
                  final left = 16 + barWidth * (index / 3);

                  return Positioned(
                    top: 14,
                    left: left - 28, // 원 가운데 정렬
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.blue : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive ? Colors.blue : Colors.grey,
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 60, // 고정 너비 줘서 텍스트가 줄바꿈되어도 정렬됨
                          child: Text(
                            stepLabels[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: isCurrent ? Colors.blue : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    },
  );
}

// ✅ 상태에 따라 현재 단계 결정
int getCurrentStep(String state) {
  switch (state) {
    case "PaymentCompleted":
    case "ShippingToBuyer":
      return 0;
    case "RentalInProgress":
    case "RentalOverdue":
      return 1;
    case "ReturnPending":
    case "ReturnCompleted":
      return 2;
    case "Completed":
      return 3;
    default:
      return -1;
  }
}
