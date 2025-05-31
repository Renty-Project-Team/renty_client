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
    super.state = 'Active',
  });
}

class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<PostUnion> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchAll();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading) {
        _fetchMore();
        // 페이징 처리 시 사용 가능
      }
    });
  }


  Future<void> _fetchMore() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final lastItem = _items.last;
      final lastCreatedAt = lastItem is SellerProduct
          ? lastItem.createdAt.toIso8601String()
          : (lastItem as BuyerPost).createdAt.toIso8601String();

      final postService = PostService();

      // 404 방지 처리된 서비스 메서드 호출
      final List<SellerProduct> newProducts = (await postService.fetchProducts(maxCreatedAt: lastCreatedAt))
          .map((p) => SellerProduct(
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
      ))
          .toList();

      final List<BuyerPost> newBuyerPosts = await postService.fetchBuyerPosts(maxCreatedAt: lastCreatedAt);

      final List<PostUnion> newItems = [...newProducts, ...newBuyerPosts];

      // 🔐 중복 방지: ID 기준 필터링
      final existingIds = _items.map((e) => e is SellerProduct ? 's_${e.id}' : 'b_${(e as BuyerPost).id}').toSet();
      final filteredNewItems = newItems.where((e) {
        final idKey = e is SellerProduct ? 's_${e.id}' : 'b_${(e as BuyerPost).id}';
        return !existingIds.contains(idKey);
      }).toList();

      if (filteredNewItems.isEmpty) {
        _hasMore = false;
        print('${_hasMore}');// 새로운 게 없다면 더 이상 불러올 것 없음
      } else {
        _items.addAll(filteredNewItems);
        _items.sort((a, b) {
          final aTime = a is SellerProduct ? a.createdAt : (a as BuyerPost).createdAt;
          final bTime = b is SellerProduct ? b.createdAt : (b as BuyerPost).createdAt;
          return bTime.compareTo(aTime); // 최신순 정렬
        });
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('더 불러오기 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
    });
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
    final adInterval = 5;
    final listView = RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_items.length ~/ adInterval),
        itemBuilder: (context, index) {
          final numAdsBefore = index ~/ (adInterval + 1);

          // 광고 위치: 6, 12, 18, ...
          if ((index + 1) % (adInterval + 1) == 0) {
            return AdCard();
          }

          final itemIndex = index - numAdsBefore;
          if (itemIndex >= _items.length) return SizedBox.shrink(); // 안전하게 방어

          final item = _items[itemIndex];

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
