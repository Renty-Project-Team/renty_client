import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/windowClickEvent/dragEvent.dart';
import 'package:renty_client/detailed_post/detailPost.dart';
import 'package:renty_client/core/token_manager.dart';

const categoryMap = {
  'ClothingAndFashion': '의류/패션',
  'Electronics': '전자제품',
  'FurnitureAndInterior': '가구/인테리어',
  'Beauty': '뷰티/미용',
  'Books': '도서',
  'Stationery': '문구',
  'CarAccessories': '자동차 용품',
  'Sports': '스포츠/레저',
  'InfantsAndChildren': '유아/아동',
  'PetSupplies': '반려동물 용품',
  'HealthAndMedical': '건강/의료',
  'Hobbies': '취미/여가',
};

const priceUnitMap = {
  'Day': '일',
  'Week': '주',
  'Month': '월',
};

class BuyerPostDetailPage extends StatefulWidget {
  final int postId;

  const BuyerPostDetailPage({super.key, required this.postId});

  @override
  State<BuyerPostDetailPage> createState() => _BuyerPostDetailPageState();
}

class _BuyerPostDetailPageState extends State<BuyerPostDetailPage> {
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPostDetail();
  }
  Future<void> _fetchPostDetail() async {
    try {
      final res = await ApiClient().client.get('/Post/detail', queryParameters: {
        'postId': widget.postId,
      });
      setState(() {
        _post = res.data;
        _isLoading = false;
      });
    } catch (e) {
      print('상세 불러오기 오류: $e');
      setState(() {
        _post = null;
        _isLoading = false;
      });
    }
  }
  Future<void> _showMyItemList() async {
    if (await TokenManager.getToken() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }
    try {
      final response = await ApiClient().client.get('/My/posts');
      final List<dynamic> items = response.data;

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // ✅ 전체 높이 제어 가능
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) {
          return FractionallySizedBox(
            heightFactor: 0.5, // ✅ 전체 화면의 50%만 차지
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                        leading: Image.network(
                          '${apiClient.getDomain}${item['imageUrl']}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _noImage(),
                      ),
                      title: Text(item['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${priceUnitMap[item['priceUnit']]} ${NumberFormat("#,###").format(item['price'].toInt())}원'),
                      onTap: () {
                        setState(() => _selectedItem = item);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 목록을 불러올 수 없습니다')),
      );
    }
  }
  Widget _noImage() => Container(
    width: 90,
    height: 90,
    color: Colors.grey[300],
    child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
  );

  Future<void> _submitComment() async {
    if (await TokenManager.getToken() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }
    final content = _commentController.text.trim();
    final itemId = _selectedItem?['id'];

    if ((content.isEmpty) && itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 내용 또는 상품 첨부가 필요합니다.')),
      );
      return;
    }

    try {
      await ApiClient().client.post('/Post/comment', data: {
        'postId': widget.postId,
        'content': content.isEmpty ? null : content,
        'itemId': itemId,
      });

      setState(() {
        _commentController.clear();
        _selectedItem = null;
        _fetchPostDetail(); // 새 댓글 반영
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글이 등록되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('등록 실패: $e')));
    }
  }

  void _showFullScreenImage(List<String> images, int startIndex) {
    final controller = PageController(initialPage: startIndex);
    int localIndex = startIndex;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  MouseDraggableWrapper(
                    controller: controller,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => localIndex = index),
                      itemBuilder: (_, index) {
                        if (images[index].toString().isNotEmpty) {
                          final imageUrl = '${apiClient.getDomain}${images[index]}';
                          return Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) { // 여기에도 errorBuilder 추가
                                print('Error loading fullscreen image: $imageUrl. Error: $error');
                                return Center(child: _noImage());
                              }
                          );
                        } else {
                          return Center(child: _noImage()); // 경로가 비어있으면 플레이스홀더 반환
                        }
                      },
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '${localIndex + 1} / ${images.length}',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageSlider(List<String> imageUrls) {
    final controller = PageController(initialPage: _currentImageIndex);

    return MouseDraggableWrapper(
      controller: controller,
      child: PageView.builder(
        controller: controller,
        itemCount: imageUrls.length,
        onPageChanged: (index) => setState(() => _currentImageIndex = index),
        itemBuilder: (_, index) {
          final String imagePath = imageUrls[index];
          print('[DEBUG] _buildImageSlider - Attempting to load URL: ${apiClient.getDomain}$imagePath (imagePath: "$imagePath")');
          if (imagePath.isEmpty) {
            print('[DEBUG] _buildImageSlider - imagePath is empty. Using _noImage().');
            return _noImage(); // 또는 다른 플레이스홀더 위젯
          }

          final imageUrl = '${apiClient.getDomain}$imagePath';
          return GestureDetector(
            onTap: () => _showFullScreenImage(imageUrls, index),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image in _buildImageSlider: $imageUrl. Error: $error');
                return _noImage();
              },
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton()),
        body: Center(child: Text('게시글을 불러오지 못했습니다')),
      );
    }

    final imageUrls = _post!['imagesUrl'] != null && _post!['imagesUrl'] is List
        ? List<String>.from(_post!['imagesUrl'].map((item) => item.toString())) // 각 요소를 String으로 변환
        : List<String>.empty(growable: false);
    final comments = List<Map<String, dynamic>>.from(_post!['comments'] ?? []);
    final createdAt = DateTime.parse(_post!['createdAt']);

    return Scaffold(
      resizeToAvoidBottomInset: false, // ✅ 키보드로 인한 리사이즈 방지
      appBar: AppBar(
        leading: BackButton(),
        actions: [Icon(Icons.lightbulb_outline), SizedBox(width: 16)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (imageUrls.isNotEmpty)
                    SizedBox(height: 400, child: _buildImageSlider(imageUrls)),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage('${apiClient.getDomain}${_post!['userProfileImage']}'),
                      ),
                      SizedBox(width: 8),
                      Text(
                        _post!['userName'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        DateFormat('yyyy.MM.dd HH:mm').format(createdAt),
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '[상품요청]',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        TextSpan(
                          text: _post!['title'],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Text('카테고리: ${categoryMap[_post!['category']] ?? _post!['category']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(_post!['description'] ?? '', style: TextStyle(fontSize: 16)),
                  Divider(height: 24, thickness: 1),
                  Text('댓글 ${comments.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ...comments.map(_buildComment).toList(),
                  SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                left: 16,
                right: 16,
                top: 8,
              ),
              child: _buildCommentInput(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(Map<String, dynamic> comment) {
    final created = DateTime.parse(comment['createdAt']);
    final item = comment['itemDetail'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${comment['userName']} · ${DateFormat('MM/dd HH:mm').format(created)}',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        if (comment['content'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(comment['content']),
          ),
        if (item != null)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailPage(itemId: item['itemId']),
                ),
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${apiClient.getDomain}${item['imageUrl']}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${item['title']} • ${priceUnitMap[item['priceUnit']] ?? item['priceUnit']} ${NumberFormat("#,###").format(item['price'].toInt())}원',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey), // 📎 클릭 가능한 느낌 강조
              ],
            ),
          ),
        SizedBox(height: 16),
        SizedBox(height: 8),
      ],
    );
  }
  // 댓글 입력 상태 변수
  final TextEditingController _commentController = TextEditingController();
  Map<String, dynamic>? _selectedItem;

// 댓글 입력 UI + 첨부 상품
  Widget _buildCommentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 상품 첨부 미리보기 (있을 경우)
        if (_selectedItem != null)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    '${apiClient.getDomain}${_selectedItem!['imageUrl']}',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedItem!['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_selectedItem!['priceUnit']} ${_selectedItem!['price']}원'),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => setState(() => _selectedItem = null),
                )
              ],
            ),
          ),

        // ✅ 댓글 입력 + 등록 버튼 (항상 보임)
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              tooltip: '상품 첨부',
              onPressed: _showMyItemList,
            ),
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              tooltip: '댓글 등록',
              onPressed: _submitComment,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ],
    );
  }
}
