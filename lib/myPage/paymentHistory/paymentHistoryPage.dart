import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';


class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  late Future<List<dynamic>> _itemsFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentItems();
  }

  Future<void> _loadPaymentItems() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await ApiClient().client.get('/Transaction/buyer');
      if (response.statusCode == 200) {
        // 데이터를 최신순으로 정렬
        List<dynamic> items = response.data;
        items.sort((a, b) {
          DateTime dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(1970);
          return dateB.compareTo(dateA); // 내림차순 정렬 (최신순)
        });
        
        setState(() {
          _itemsFuture = Future.value(items);
          _isLoading = false;
        });
      } else {
        throw Exception('결제 내역을 불러오지 못했습니다');
      }
    } catch (e) {
      print('결제 내역 불러오기 오류: $e');
      setState(() => _isLoading = false);
      _itemsFuture = Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 완료 물품'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<dynamic>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '결제 내역을 불러오는데 실패했습니다',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadPaymentItems,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B70FD),
                            ),
                            child: const Text('다시 시도'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 70,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '결제 내역이 없습니다',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadPaymentItems,
                    child: ListView.builder(
                      itemCount: items.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder:
                          (context, index) => _buildReceiptCard(items[index]),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildReceiptCard(dynamic item) {
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('yyyy.MM.dd');

    // 날짜 파싱 (API 응답에서 제공된 날짜가 유효하지 않을 수 있으므로 예외 처리)
    DateTime createdAt;
    DateTime borrowStartAt;
    DateTime returnAt;

    try {
      createdAt = DateTime.parse(item['createdAt']);
      borrowStartAt = DateTime.parse(item['borrowStartAt']);
      returnAt = DateTime.parse(item['returnAt']);
    } catch (e) {
      createdAt = DateTime.now();
      borrowStartAt = DateTime.now();
      returnAt = DateTime.now().add(const Duration(days: 7));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 영수증 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4B70FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '영수증',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  dateFormat.format(createdAt),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // 상품 정보
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      item['itemImageUrl'] != null
                          ? Image.network(
                            '${ApiClient().getDomain}${item['itemImageUrl']}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _buildImagePlaceholder(),
                          )
                          : _buildImagePlaceholder(),
                ),
                const SizedBox(width: 16),

                // 상품 정보 텍스트
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] ?? '제목 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '판매자: ${item['name'] ?? '판매자 정보 없음'}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${dateFormat.format(borrowStartAt)} - ${dateFormat.format(returnAt)}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 결제 상세 정보 - 상품 정보에 집중
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  '상품 금액',
                  '${numberFormat.format(item['finalPrice'] ?? 0)}원',
                  priceUnit: _getPriceUnitText(item['priceUnit']),
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '보증금',
                  '${numberFormat.format(item['finalSecurityDeposit'] ?? 0)}원',
                ),
                const SizedBox(height: 8),
                _buildInfoRow('결제일시', dateFormat.format(createdAt)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildInfoRow(
                  '총 결제금액',
                  '${numberFormat.format((item['finalPrice'] ?? 0) + (item['finalSecurityDeposit'] ?? 0))}원',
                  titleStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  valueStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4B70FD),
                  ),
                ),
              ],
            ),
          ),

          // 하단 상품번호
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '상품번호',
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
                Text(
                  '#${item['itemId'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriceUnitText(String? unit) {
    switch (unit) {
      case 'Day':
        return '/ 일';
      case 'Week':
        return '/ 주';
      case 'Month':
        return '/ 월';
      case 'Hour':
        return '/ 시간';
      default:
        return '';
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, size: 30),
    );
  }

  Widget _buildInfoRow(
    String title,
    String value, {
    String priceUnit = '',
    TextStyle? titleStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ?? TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        Row(
          children: [
            Text(
              value,
              style:
                  valueStyle ??
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            if (priceUnit.isNotEmpty)
              Text(
                priceUnit,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
