import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/core/token_manager.dart';
import 'package:renty_client/post/AdBoard.dart';
import 'package:renty_client/windowClickEvent/scrollEvent.dart';
import 'package:renty_client/detailed_post/buyerDetail/buyerDetailPost.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'buyerPostService.dart';
import 'buyerPostDataFile.dart';

class MyBuyerPostListPage extends StatefulWidget {
  const MyBuyerPostListPage({Key? key}) : super(key: key);

  @override
  State<MyBuyerPostListPage> createState() => _MyBuyerPostListPageState();
}

class _MyBuyerPostListPageState extends State<MyBuyerPostListPage> {
  List<BuyerPost> _posts = [];
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
        _fetchPosts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUsername() async {
    try {
      final response = await _apiClient.client.get('/My/profile');

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _currentUsername = data['userName'] ?? '';
        });
        _fetchPosts();
      } else {
        _handleApiError('사용자 정보를 불러오는데 실패했습니다');
      }
    } catch (e) {
      _handleApiError('오류가 발생했습니다: $e');
      print('사용자 정보 로드 실패: $e');
    }
  }

  Future<void> _fetchPosts() async {
    if (_isLoading || _currentUsername.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    String? maxCreatedAt;
    if (_posts.isNotEmpty) {
      maxCreatedAt = _posts.last.createdAt.toIso8601String();
    }

    try {
      final newPosts = await BuyerPostService().fetchBuyerPosts(
        maxCreatedAt: maxCreatedAt,
      );

      final myPosts =
          newPosts.where((post) => post.userName == _currentUsername).toList();

      setState(() {
        _posts.addAll(myPosts);
        _isLoading = false;
        _initialLoadComplete = true;

        if (newPosts.length < 20) {
          _hasMore = false;
        }
      });
    } catch (e) {
      _handleApiError('대여 요청 게시글 목록을 불러오는데 실패했습니다: $e');
      print('대여 요청 게시글 목록 불러오기 실패: $e');
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _posts = [];
      _hasMore = true;
    });

    await _fetchPosts();
    return Future.value();
  }

  // 게시글 삭제 기능 추가
  Future<void> _deletePost(int postId) async {
    try {
      final response = await ApiClient().client.delete(
        '/Post/post',
        queryParameters: {'postId': postId},
      );

      if (response.statusCode == 200) {
        // 로컬 목록에서 삭제된 게시글 제거
        setState(() {
          _posts.removeWhere((post) => post.id == postId);
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
      onRefresh: _refreshPosts,
      child:
          _initialLoadComplete && _posts.isEmpty
              ? _buildEmptyView()
              : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _posts.length + (_hasMore ? 1 : 0),
                separatorBuilder: (context, index) {
                  if ((index + 1) % 5 == 0) return AdCard();
                  return SizedBox(height: 0);
                },
                itemBuilder: (context, index) {
                  if (index < _posts.length) {
                    return BuyerPostCard(
                      post: _posts[index],
                      onDelete: _deletePost, // 삭제 콜백 전달
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
          '내 대여 요청 게시글',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _isLoading && _posts.isEmpty
              ? Center(child: CircularProgressIndicator())
              : isDesktop
              ? DraggableScrollWrapper(
                controller: _scrollController,
                onRefreshShortcut: () {
                  print('✅ F5 or Ctrl+R 눌러서 새로고침 호출됨');
                  _refreshPosts();
                },
                child: listView,
              )
              : listView,
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.post_add, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '등록한 대여 요청 게시글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '원하는 상품을 요청해보세요!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('대여 요청 게시글 작성 기능은 준비 중입니다.')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('요청 게시글 작성하기'),
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

class BuyerPostCard extends StatelessWidget {
  final BuyerPost post;
  final Function(int)? onDelete; // 삭제 콜백 추가

  BuyerPostCard({required this.post, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ApiClient apiClient = ApiClient();

    return InkWell(
      onTap: () {
        // 대여 요청 게시글 상세 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerPostDetailPage(postId: post.id),
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
              // 이미지 영역
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    post.imageUrl != null
                        ? Image.network(
                          '${apiClient.getDomain}${post.imageUrl}',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
              ),
              SizedBox(width: 12),

              // 텍스트 정보 영역
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
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '[상품 요청]',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            post.title,
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
                      "카테고리: ${post.categoryKorean}",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy.MM.dd HH:mm').format(post.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // 우측 삭제 버튼 및 통계 정보 영역
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 삭제 버튼
                  ElevatedButton(
                    onPressed: () => _showDeleteDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size(70, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text('삭제', style: TextStyle(fontSize: 12)),
                  ),

                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
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
                        '${post.viewCount}',
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

  // 삭제 확인 다이얼로그
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
                          onDelete!(post.id);
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
}
