import 'package:flutter/material.dart';
import 'package:renty_client/post/mainBoard.dart';//card형 UI
import 'package:renty_client/post/postDataFile.dart';
import 'package:renty_client/core/api_client.dart'; //서버요청 UI
import 'package:renty_client/detailed_post/productService.dart'; // removeFromWishlist 사용

class WishlistPage extends StatefulWidget {
  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  late Future<List<Product>> _wishlistFuture;

  @override
  void initState() {
    super.initState();
    _wishlistFuture = _fetchWishlist();
  }

  Future<List<Product>> _fetchWishlist() async {
    final response = await ApiClient().client.get('/My/wishlist');

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((item) => Product.fromJson(item))
          .toList();
    } else {
      throw Exception('찜 목록 불러오기 실패');
    }
  }

  Future<void> _removeFromWishlist(int itemId) async {
    await ProductService().removeFromWishlist(itemId);
    setState(() {
      _wishlistFuture = _fetchWishlist(); // 다시 불러오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('찜 목록')),
      body: FutureBuilder<List<Product>>(
        future: _wishlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('찜한 상품이 없습니다.'));
          }

          final wishlist = snapshot.data!;
          return ListView.builder(
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              final product = wishlist[index];
              return Stack(
                children: [
                  ProductCard(product: product), // ✅ 재사용
                  Positioned(
                    right: 16,
                    top: 12,
                    child: IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await _removeFromWishlist(product.id);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
