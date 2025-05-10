import 'package:flutter/material.dart';
import 'package:renty_client/post/postDataFile.dart';
import 'searchService.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/post/AdBoard.dart';
import 'package:renty_client/post/mainBoard.dart'; // ProductCard 재활용

class SearchResultPage extends StatefulWidget {
  final String query;
  final String? category;

  const SearchResultPage({required this.query, this.category, super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  late Future<List<Product>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = SearchService().searchProducts(
      query: widget.query,
      category: widget.category,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('검색 결과'),
      ),
      body: FutureBuilder<List<Product>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error is DioException && error.response?.statusCode == 404) {
              // ✅ 404일 때는 '검색 결과 없음' 처리
              return Center(child: Text('검색 결과가 없습니다.',style: TextStyle(fontSize: 20)));
            } else {
              // ❌ 그 외의 에러는 일반 오류 메시지
              return Center(child: Text('검색 중 오류 발생: ${snapshot.error}'));
            }
          }

          final products = snapshot.data ?? [];

          return ListView.separated(
            itemCount: products.length,
            separatorBuilder: (context, index) {
              if ((index + 1) % 5 == 0) {
                return AdCard();
              }
              return SizedBox(height: 0);
            },
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
          ;
        },
      ),
    );
  }
}