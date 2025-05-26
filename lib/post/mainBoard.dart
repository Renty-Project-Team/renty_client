import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/post/postService.dart';
import 'package:renty_client/post/postDataFile.dart'; // Product, BuyerPost
import 'package:renty_client/post/buyerPost/buyerPost.dart'; // BuyerPostCard
import 'package:renty_client/windowClickEvent/scrollEvent.dart';
import 'package:renty_client/detailed_post/detailPost.dart';
import 'package:renty_client/detailed_post/buyerDetail/buyerDetailPost.dart';
import 'package:renty_client/post/AdBoard.dart';

/// 통합 타입
abstract class PostUnion {}

class SellerProduct extends Product implements PostUnion {
  SellerProduct({
    required super.id,
    required super.title,
    required super.price,
    required super.deposit,
    required super.categorys,
    required super.priceUnit,
    required super.viewCount,
    required super.wishCount,
    required super.chatCount,
    required super.createdAt,
    required super.imageUrl,
    required super.userName,
  });
}

class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<PostUnion> _items = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAll();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading) {
        // 페이징 처리 시 사용 가능
      }
    });
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    try {
      final postService = PostService();
      final products = await postService.fetchProducts();
      final posts = await postService.fetchBuyerPosts();

      _items = [
        ...products.map((p) => SellerProduct(
          id: p.id,
          title: p.title,
          price: p.price,
          deposit: p.deposit,
          categorys: p.categorys,
          priceUnit: p.priceUnit,
          viewCount: p.viewCount,
          wishCount: p.wishCount,
          chatCount: p.chatCount,
          createdAt: p.createdAt,
          imageUrl: p.imageUrl,
          userName: p.userName,
        )),
        ...posts,
      ];

      _items.sort((a, b) {
        DateTime aTime = a is SellerProduct ? a.createdAt : (a as BuyerPost).createdAt;
        DateTime bTime = b is SellerProduct ? b.createdAt : (b as BuyerPost).createdAt;
        return bTime.compareTo(aTime);
      });

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('불러오기 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _fetchAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listView = RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (context, index) {
          if ((index + 1) % 5 == 0) return AdCard();
          return SizedBox.shrink();
        },
        itemBuilder: (context, index) {
          final item = _items[index];

          return InkWell(
            onTap: () {
              if (item is SellerProduct) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(itemId: item.id)),
                );
              } else if (item is BuyerPost) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BuyerPostDetailPage(postId: item.id)),
                );
              }
            },
            child: item is SellerProduct
                ? ProductCard(product: item)
                : item is BuyerPost
                ? BuyerPostCard(post: item)
                : SizedBox.shrink(),
          );
        },
      ),
    );

    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(defaultTargetPlatform);

    return isDesktop
        ? DraggableScrollWrapper(
      controller: _scrollController,
      onRefreshShortcut: _refresh,
      child: listView,
    )
        : listView;
  }
}


/// 상품 카드 UI
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
                  errorBuilder: (_, __, ___) => Container(
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
                      Text('${product.wishCount}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${product.viewCount}', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
