import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import 'productService.dart';
import 'productDataFile.dart';
import 'package:renty_client/windowClickEvent/dragEvent.dart'; // 드래그 wrapper 임포트

class DetailPage extends StatefulWidget {
  final int itemId;
  const DetailPage({required this.itemId, Key? key}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  int _currentImageIndex = 0;
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = ProductService().fetchProduct(widget.itemId);
  }

  void _showFullScreenImage(List<String> images, int startIndex) {
    PageController controller = PageController(initialPage: startIndex);
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
                      itemBuilder: (context, index) {
                        final imageUrl = '${apiClient.getDomain}${images[index]}';
                        return Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
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
                  ),
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
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final imageUrl = '${apiClient.getDomain}${imageUrls[index]}';
          return GestureDetector(
            onTap: () => _showFullScreenImage(imageUrls, index),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text('에러 발생: ${snapshot.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _productFuture = ProductService().fetchProduct(widget.itemId);
                      });
                    },
                    child: Text('다시 시도하기'),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasData) {
          final product = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(),
              actions: [
                Icon(Icons.lightbulb_outline),
                SizedBox(width: 16),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 400, child: _buildImageSlider(product.imagesUrl)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(child: Icon(Icons.person)),
                            SizedBox(width: 8),
                            Text(product.userName, style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Divider(height: 24, thickness: 1),
                        SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '[${product.state == 'Active' ? '대여 가능' : '대여중'}] ',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: product.state == 'Active' ? Colors.green : Colors.red,
                                ),
                              ),
                              TextSpan(
                                text: product.title,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Text("카테고리: ${product.categories.isNotEmpty ? product.categories.first : '없음'}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Column(
                          children: [
                            Row(
                              children: [
                                Spacer(),
                                Text("대여 가격: ${product.priceUnit} ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text("${product.price.toInt()} 원",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Spacer(),
                                Text("보증금: ",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text("${product.securityDeposit.toInt()} 원",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Spacer(),
                                Icon(Icons.visibility),
                                Text(" ${product.viewCount}"),
                                Icon(Icons.favorite_border),
                                Text("${product.wishCount}")
                              ],
                            ),
                            Divider(height: 24, thickness: 1),
                          ],
                        ),
                        Text(product.description,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Icon(Icons.favorite_border),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // 채팅 기능 연결
                      },
                      child: Text("채팅하기"),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(leading: BackButton()),
            body: Center(child: Text('데이터가 없습니다.')),
          );
        }
      },
    );
  }
}
