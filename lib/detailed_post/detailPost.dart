import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:renty_client/main.dart';
import 'productService.dart';
import 'productDataFile.dart';

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
                  MouseDraggablePageView(
                    images: images.map((img) => '${apiClient.getDomain}$img').toList(),
                    controller: controller,
                    isFullScreen: true,
                    onPageChanged: (index) {
                      setState(() {
                        localIndex = index;
                      });
                    },
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
                  SizedBox(
                    height: 400,
                    child: MouseDraggablePageView(
                      images: product.imagesUrl.map((img) => '${apiClient.getDomain}$img').toList(),
                      controller: PageController(initialPage: _currentImageIndex),
                      isFullScreen: false,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      onImageTap: (index) {
                        _showFullScreenImage(product.imagesUrl, index);
                      },
                    ),
                  ),
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

// =====================
// MouseDraggablePageView (드래그 + 페이지뷰 통합)
// =====================
class MouseDraggablePageView extends StatefulWidget {
  final List<String> images;
  final PageController controller;
  final Function(int)? onPageChanged;
  final Function(int)? onImageTap;
  final bool isFullScreen;

  const MouseDraggablePageView({
    required this.images,
    required this.controller,
    this.onPageChanged,
    this.onImageTap,
    this.isFullScreen = false,
    Key? key,
  }) : super(key: key);

  @override
  _MouseDraggablePageViewState createState() => _MouseDraggablePageViewState();
}

class _MouseDraggablePageViewState extends State<MouseDraggablePageView> {
  double? _dragStartX;
  double _dragThreshold = 300;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          _dragStartX = event.position.dx;
        }
      },
      onPointerMove: (event) {
        if (_dragStartX != null) {
          double dragDelta = event.position.dx - _dragStartX!;
          if (dragDelta.abs() > _dragThreshold) {
            if (dragDelta > 0) {
              widget.controller.previousPage(
                  duration: Duration(milliseconds: 300), curve: Curves.ease);
            } else {
              widget.controller.nextPage(
                  duration: Duration(milliseconds: 300), curve: Curves.ease);
            }
            _dragStartX = null;
          }
        }
      },
      onPointerUp: (_) => _dragStartX = null,
      onPointerCancel: (_) => _dragStartX = null,
      child: PageView.builder(
        controller: widget.controller,
        itemCount: widget.images.length,
        onPageChanged: widget.onPageChanged,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (widget.onImageTap != null) {
                widget.onImageTap!(index);
              }
            },
              child: Image.network(
                widget.images[index],
                fit: widget.isFullScreen ? BoxFit.contain : BoxFit.cover,
                width: widget.isFullScreen ? double.infinity : null,
                height: widget.isFullScreen ? double.infinity : null,
              ),

          );
        },
      ),
    );
  }
}
