import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/main.dart';
import 'package:renty_client/windowClickEvent/dragEvent.dart';

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
                        final imageUrl = '${apiClient.getDomain}${images[index]}';
                        return Image.network(imageUrl, fit: BoxFit.contain);
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
          final imageUrl = '${apiClient.getDomain}${imageUrls[index]}';
          return GestureDetector(
            onTap: () => _showFullScreenImage(imageUrls, index),
            child: Image.network(imageUrl, fit: BoxFit.cover),
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

    final imageUrls = List<String>.from(_post!['imagesUrl'] ?? []);
    final comments = List<Map<String, dynamic>>.from(_post!['comments'] ?? []);
    final createdAt = DateTime.parse(_post!['createdAt']);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text(_post!['title']),
        actions: [
          Icon(Icons.info_outline),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrls.isNotEmpty)
              SizedBox(height: 400, child: _buildImageSlider(imageUrls)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(child: Icon(Icons.person)),
                      SizedBox(width: 8),
                      Text(_post!['userName'], style: TextStyle(fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text(DateFormat('yyyy.MM.dd HH:mm').format(createdAt),
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Divider(height: 24),
                  Text('카테고리: ${_post!['category']}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(_post!['description'] ?? '', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 24),
                  Divider(height: 24, thickness: 1),
                  Text('댓글 ${comments.length}', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  ...comments.map(_buildComment).toList(),
                ],
              ),
            )
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
          Row(
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
                  '${item['title']} • ${item['priceUnit']} ${NumberFormat("#,###").format(item['price'])}원',
                  style: TextStyle(fontSize: 14),
                ),
              )
            ],
          ),
        SizedBox(height: 16),
        Divider(height: 1),
        SizedBox(height: 8),
      ],
    );
  }
}
