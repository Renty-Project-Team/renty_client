import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RentalItem {
  final int itemId;
  final String title;
  final String lenderName;
  final int price;
  final String priceUnit;
  final int deposit;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'completed', 'cancelled'
  final String? imageUrl;

  RentalItem({
    required this.itemId,
    required this.title,
    required this.lenderName,
    required this.price,
    required this.priceUnit,
    required this.deposit,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.imageUrl,
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    return RentalItem(
      itemId: json['itemId'] ?? 0,
      title: json['title'] ?? '상품명 없음',
      lenderName: json['lenderName'] ?? '판매자 정보 없음',
      price: json['price'] ?? 0,
      priceUnit: json['priceUnit'] ?? 'Day',
      deposit: json['securityDeposit'] ?? 0,
      startDate:
          json['borrowStartAt'] != null
              ? DateTime.parse(json['borrowStartAt'])
              : DateTime.now(),
      endDate:
          json['returnAt'] != null
              ? DateTime.parse(json['returnAt'])
              : DateTime.now().add(const Duration(days: 1)),
      status: json['state'] ?? 'active',
      imageUrl: json['imageUrl'],
    );
  }
}

class RentalListPage extends StatefulWidget {
  final bool showActiveOnly;

  const RentalListPage({Key? key, this.showActiveOnly = true})
    : super(key: key);

  @override
  State<RentalListPage> createState() => _RentalListPageState();
}

class _RentalListPageState extends State<RentalListPage> {
  List<RentalItem> _rentals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  // API 호출 없이 샘플 데이터 로드
  Future<void> _loadRentals() async {
    // 지연 효과를 위한 딜레이
    await Future.delayed(const Duration(milliseconds: 800));

    // 샘플 데이터 생성
    final List<RentalItem> sampleData =
        widget.showActiveOnly ? _getActiveRentals() : _getHistoryRentals();

    setState(() {
      _rentals = sampleData;
      _isLoading = false;
    });
  }

  // 대여 중인 상품 샘플 데이터
  List<RentalItem> _getActiveRentals() {
    return [
      RentalItem(
        itemId: 1,
        title: '예제 상품 입니다',
        lenderName: '테스트계정',
        price: 2000,
        priceUnit: 'Day',
        deposit: 5000,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        status: 'Pending',
        imageUrl: 'https://via.placeholder.com/100',
      ),
      RentalItem(
        itemId: 2,
        title: '예제 상품 입니다',
        lenderName: '테스트계정',
        price: 5000,
        priceUnit: 'Day',
        deposit: 10000,
        startDate: DateTime.now().subtract(const Duration(days: 4)),
        endDate: DateTime.now().add(const Duration(days: 1)),
        status: 'Active',
        imageUrl: 'https://via.placeholder.com/100',
      ),
    ];
  }

  // 결제 완료된 상품 샘플 데이터
  List<RentalItem> _getHistoryRentals() {
    return [
      RentalItem(
        itemId: 3,
        title: '예제 상품 입니다',
        lenderName: '테스트계정',
        price: 2000,
        priceUnit: 'Day',
        deposit: 5000,
        startDate: DateTime(2025, 3, 20),
        endDate: DateTime(2025, 3, 25),
        status: 'Active',
        imageUrl: 'https://via.placeholder.com/100',
      ),
      RentalItem(
        itemId: 4,
        title: '예제 상품 입니다',
        lenderName: '테스트계정',
        price: 5000,
        priceUnit: 'Day',
        deposit: 10000,
        startDate: DateTime(2025, 3, 1),
        endDate: DateTime(2025, 3, 5),
        status: 'Completed',
        imageUrl: 'https://via.placeholder.com/100',
      ),
      RentalItem(
        itemId: 5,
        title: '예제 상품 입니다',
        lenderName: '테스트계정',
        price: 5000,
        priceUnit: 'Week',
        deposit: 15000,
        startDate: DateTime(2025, 2, 15),
        endDate: DateTime(2025, 2, 28),
        status: 'Cancelled',
        imageUrl: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showActiveOnly ? '대여중인 제품' : '결제완료 물품'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rentals.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadRentals,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rentals.length,
                  itemBuilder: (context, index) {
                    return _buildRentalItem(_rentals[index]);
                  },
                ),
              ),
    );
  }

  // 빈 상태 UI
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            widget.showActiveOnly ? '대여중인 제품이 없습니다' : '결제완료 내역이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // 렌탈 아이템 UI
  Widget _buildRentalItem(RentalItem item) {
    final dateFormat = DateFormat('yyyy년 M월 d일');
    final numberFormat = NumberFormat('#,###');

    // priceUnit 한글 변환
    String koreanPriceUnit = '일';
    switch (item.priceUnit) {
      case 'Day':
        koreanPriceUnit = '일';
        break;
      case 'Week':
        koreanPriceUnit = '주';
        break;
      case 'Month':
        koreanPriceUnit = '월';
        break;
      case 'Year':
        koreanPriceUnit = '년';
        break;
    }

    // 상태 표시 텍스트
    String statusText = '대여중';
    Color statusColor = const Color(0xFF3154FF);

    if (item.status == 'Completed') {
      statusText = '반납완료';
      statusColor = Colors.green;
    } else if (item.status == 'Cancelled') {
      statusText = '취소됨';
      statusColor = Colors.red;
    } else if (item.status == 'Pending') {
      statusText = '대여준비';
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 정보: 제목 및 상태
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지
                if (item.imageUrl != null)
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl!), // API 도메인 참조 제거
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),

                // 상품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 상태 표시
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 제품 제목
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // 대여자 정보
                      Text(
                        '대여자: ${item.lenderName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 대여 정보
            Row(
              children: [
                // 왼쪽 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('대여 시작', dateFormat.format(item.startDate)),
                      const SizedBox(height: 8),
                      _buildInfoRow('대여 종료', dateFormat.format(item.endDate)),
                    ],
                  ),
                ),

                // 오른쪽 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        '대여료',
                        '${numberFormat.format(item.price)}원/${koreanPriceUnit}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        '보증금',
                        '${numberFormat.format(item.deposit)}원',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 리뷰 작성 버튼 (대여 종료되었고 리뷰 미작성 시에만)
            if (item.status == 'Completed')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        // 리뷰 작성 페이지로 이동 (실제 구현 없음)
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3154FF),
                        side: const BorderSide(color: Color(0xFF3154FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('리뷰 작성하기'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 정보 행 위젯
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
