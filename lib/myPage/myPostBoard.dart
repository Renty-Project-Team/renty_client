import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/detailed_post/detailPost.dart';
import 'package:renty_client/post/AdBoard.dart';
import 'package:renty_client/mypage/myPostService.dart';
import 'package:renty_client/post/postDataFile.dart';
import 'package:renty_client/windowClickEvent/scrollEvent.dart';
import 'package:intl/intl.dart';

class MyPostListPage extends StatefulWidget {
  const MyPostListPage({Key? key}) : super(key: key);

  @override
  State<MyPostListPage> createState() => _MyPostListPageState();
}

class _MyPostListPageState extends State<MyPostListPage> {
  List<Product> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String _currentUsername = '';
  bool _initialLoadComplete = false;

  final ScrollController _scrollController = ScrollController();
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadCurrentUsername();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 현재 로그인한 사용자의 username 불러오기
  Future<void> _loadCurrentUsername() async {
    try {
      final response = await _apiClient.client.get('/My/profile');

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _currentUsername = data['userName'] ?? '';
        });
        // 사용자 정보 로드 후 상품 목록 가져오기
        _fetchProducts();
      } else {
        _handleApiError('사용자 정보를 불러오는데 실패했습니다');
      }
    } catch (e) {
      _handleApiError('오류가 발생했습니다: $e');
      print('사용자 정보 로드 실패: $e');
    }
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || _currentUsername.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    String? maxCreatedAt;
    if (_products.isNotEmpty) {
      maxCreatedAt = _products.last.createdAt.toIso8601String();
    }

    try {
      final newProducts = await PostService().fetchProducts(
        maxCreatedAt: maxCreatedAt,
      );

      // 현재 로그인한 사용자의 게시글만 필터링
      final myProducts =
          newProducts
              .where((product) => product.userName == _currentUsername)
              .toList();

      setState(() {
        _products.addAll(myProducts);
        _isLoading = false;
        _initialLoadComplete = true;

        // 불러온 전체 상품이 20개 미만이면 더 이상 상품이 없다고 판단
        if (newProducts.length < 20) {
          _hasMore = false;
        }
      });
    } catch (e) {
      _handleApiError('상품 목록을 불러오는데 실패했습니다: $e');
      print('상품 목록 불러오기 실패: $e');
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _products = [];
      _hasMore = true;
    });

    await _fetchProducts();
    return Future.value();
  }

  void _handleApiError(String message) {
    setState(() {
      _isLoading = false;
      _initialLoadComplete = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final listView = RefreshIndicator(
      onRefresh: _refreshProducts,
      child:
          _initialLoadComplete && _products.isEmpty
              ? _buildEmptyView()
              : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
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

    // 데스크탑일 경우만 드래그+단축키 래퍼 적용
    final isDesktop = [
      TargetPlatform.windows,
      TargetPlatform.macOS,
      TargetPlatform.linux,
    ].contains(defaultTargetPlatform);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          '내 대여 게시글',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading && _products.isEmpty
              ? Center(child: CircularProgressIndicator())
              : isDesktop
              ? DraggableScrollWrapper(
                controller: _scrollController,
                onRefreshShortcut: () {
                  print('✅ F5 or Ctrl+R 눌러서 새로고침 호출됨');
                  _refreshProducts();
                },
                child: listView,
              )
              : listView,
    );
  }

  // 게시글이 없을 때 표시할 화면
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '등록한 대여 상품이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '지금 바로 대여 상품을 등록해보세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/product_upload');
            },
            icon: const Icon(Icons.add),
            label: const Text('상품 등록하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3154FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// 이 클래스는 mainBoard.dart에서 가져온 것입니다.
class ProductCard extends StatelessWidget {
  final Product product;
  final ApiClient apiClient = ApiClient();

  ProductCard({required this.product});

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
                  errorBuilder:
                      (context, error, stackTrace) => Container(
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
                      Text(
                        '${product.wishCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.remove_red_eye, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        '${product.viewCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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
