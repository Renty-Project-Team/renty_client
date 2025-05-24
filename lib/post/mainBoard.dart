import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import 'package:flutter/foundation.dart';
import 'AdBoard.dart';
import 'package:renty_client/detailed_post/detailPost.dart';
import 'postService.dart';
import 'postDataFile.dart';
import 'package:renty_client/windowClickEvent/scrollEvent.dart';
import 'package:intl/intl.dart';

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
    if (_isLoading) return;
    setState(() => _isLoading = true);

    String? maxCreatedAt;
    if (_products.isNotEmpty) {
      maxCreatedAt = _products.last.createdAt.toIso8601String();
    }

    try {
      final newProducts =
      await PostService().fetchProducts(maxCreatedAt: maxCreatedAt);
      if (newProducts.length < 20) {
        _hasMore = false;
      }
      setState(() {
        _products.addAll(newProducts);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 불러오기 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products.clear();
      _hasMore = true;
    });
    await _fetchProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listView = RefreshIndicator(
      onRefresh: _refreshProducts,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // ✅ 모바일에서 새로고침 가능하도록 강제
        itemCount: _products.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) {
          if ((index + 1) % 5 == 0) return AdCard();
          return SizedBox(height: 0);
        },
        itemBuilder: (context, index) {
          if (index < _products.length) {
            return ProductCard(product: _products[index]);
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );

    // ✅ 데스크탑일 경우만 드래그+단축키 래퍼 적용
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(defaultTargetPlatform);

    if (isDesktop) {
      return DraggableScrollWrapper(
        controller: _scrollController,
        onRefreshShortcut: () {
          print('✅ F5 or Ctrl+R 눌러서 새로고침 호출됨');
          _refreshProducts();
        },
        child: listView,
      );
    } else {
      return listView; // 모바일에서는 그대로 RefreshIndicator만 사용
    }
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
            builder: (context) => DetailPage(itemId: product.id),
          ),
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
                  '${apiClient.getDomain}${product.imageUrl}',
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
                    Text(
                      product.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${product.priceUnit} ${NumberFormat("#,###").format(product.price.toInt())}원",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "보증금: ${NumberFormat("#,###").format(product.deposit.toInt())}원",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.more_vert, size: 20, color: Colors.grey[600]),
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, size: 14, color: Colors.grey),
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
