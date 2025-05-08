import 'package:flutter/material.dart';
import 'AdBoard.dart';
import '../detailed_post/detailPost.dart';
import 'postService.dart';
import 'postDataFile.dart';

class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    String? maxCreatedAt;
    if (_products.isNotEmpty) {
      maxCreatedAt = _products.last.createdAt.toIso8601String();
    }

    try {
      final newProducts =
      await PostService().fetchProducts(maxCreatedAt: maxCreatedAt);
      if (newProducts.length < 20) {
        _hasMore = false; // 20개 미만 → 더 이상 불러올 데이터 없음
      }
      setState(() {
        _products.addAll(newProducts);
      });
    } catch (e) {
      print('상품 불러오기 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ 위로 당길 때 새로고침
  Future<void> _refreshProducts() async {
    setState(() {
      _products.clear(); // 기존 목록 초기화
      _hasMore = true;   // 다시 무한스크롤 허용
    });
    await _fetchProducts(); // 처음부터 다시 로드
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalItemCount =
        _products.length + (_products.length ~/ 4) + (_isLoading ? 1 : 0);

    return RefreshIndicator(
      onRefresh: _refreshProducts, // ✅ 새로고침 연결
      child: ListView.builder(
        controller: _scrollController,
        itemCount: totalItemCount,
        itemBuilder: (context, index) {
          if (_isLoading && index == totalItemCount - 1) {
            return Center(child: CircularProgressIndicator());
          }

          if (index != 0 && index % 5 == 0) {
            return AdCard();
          }

          final productIndex = index - (index ~/ 5);
          if (productIndex >= _products.length) {
            return SizedBox();
          }

          final product = _products[productIndex];
          return ProductCard(product: product);
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => DetailPage(itemId: product.id)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://deciding-silkworm-set.ngrok-free.app${product.imageUrl}',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${product.priceUnit} ${product.price.toInt()}원",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "보증금: ${product.deposit.toInt()}원",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                      children: [Icon(Icons.more_vert, size: 20, color: Colors.grey[600])]),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Icon(Icons.favorite_border,
                          size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${product.wishCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${product.viewCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}