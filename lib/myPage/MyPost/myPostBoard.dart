import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/detailed_post/detailPost.dart';
import 'package:renty_client/post/AdBoard.dart';
import 'myPostService.dart';
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

  // 대여 완료 메서드
  Future<void> _markAsCompleted(int itemId) async {
    try {
      final response = await ApiClient().client.put(
        '/Product/complete',
        queryParameters: {'itemId': itemId},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('대여 완료로 변경되었습니다.'),
            backgroundColor: Color(0xFF4B70FD),
          ),
        );

        await _refreshProducts();
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('권한이 없거나 이미 완료된 상품입니다.')));
      } else {
        print('대여 완료 처리 실패: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('대여 완료 처리에 실패했습니다.')));
      }
    }
  }

  // 게시글 삭제 메서드 추가
  Future<void> _deleteProduct(int itemId) async {
    try {
      final response = await ApiClient().client.delete(
        '/Product/post',
        queryParameters: {'itemId': itemId},
      );

      if (response.statusCode == 200) {
        // 로컬 목록에서 삭제된 상품 제거
        setState(() {
          _products.removeWhere((product) => product.id == itemId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('게시글이 삭제되었습니다.'),
            backgroundColor: Color(0xFF4B70FD),
          ),
        );
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 400) {
        final errorDetail = e.response?.data['detail'] ?? '알 수 없는 오류가 발생했습니다.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorDetail)));
      } else {
        print('게시글 삭제 실패: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시글 삭제에 실패했습니다.')));
      }
    }
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
                    return ProductCard(
                      product: _products[index],
                      onMarkComplete: _markAsCompleted,
                      onDelete: _deleteProduct, // 삭제 콜백 추가
                    );
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
  final Function(int)? onMarkComplete;
  final Function(int)? onDelete; // 삭제 콜백 추가

  ProductCard({
    required this.product,
    this.onMarkComplete,
    this.onDelete, // 삭제 콜백 추가
  });

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = ApiClient();

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
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStateColor(
                              product.state,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStateText(product.state),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStateColor(product.state),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "${product.priceUnit} ${NumberFormat("#,###").format(product.price.toInt())}원",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 게시글 설정 버튼 (Active 상태일 때만)
                  if (product.state == 'Active')
                    ElevatedButton(
                      onPressed: () => _showSettingsMenu(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B70FD),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size(80, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.settings, size: 14),
                          SizedBox(width: 4),
                          Text('설정', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),

                  // 완료된 상태 표시
                  if (product.state == 'Completed')
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '완료됨',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  SizedBox(height: 16),
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

  // 게시글 설정 메뉴 표시
  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '게시글 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // 대여 완료 버튼
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.orange),
                title: Text('대여 완료'),
                subtitle: Text('이 상품의 대여를 완료합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _showCompleteDialog(context);
                },
              ),

              Divider(),

              // 게시글 삭제 버튼
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('게시글 삭제', style: TextStyle(color: Colors.red)),
                subtitle: Text('이 게시글을 완전히 삭제합니다'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),

              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 대여 완료 확인 다이얼로그
  void _showCompleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '대여 완료',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                const Text(
                  '이 상품을 대여 완료 상태로 변경하시겠습니까?\n변경 후에는 되돌릴 수 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onMarkComplete != null) {
                          onMarkComplete!(product.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        '완료',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 게시글 삭제 확인 다이얼로그
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '게시글 삭제',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                const Text(
                  '이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onDelete != null) {
                          onDelete!(product.id);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'Active':
        return Colors.green;
      case 'Inactive':
        return Colors.red;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStateText(String state) {
    switch (state) {
      case 'Active':
        return '[대여 가능]';
      case 'Inactive':
        return '[대여 불가능]';
      case 'Completed':
        return '[대여 완료]';
      default:
        return '[알 수 없음]';
    }
  }
}
