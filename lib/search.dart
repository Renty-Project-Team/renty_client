import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'global_theme.dart';
import 'logo_app_ber.dart';
import 'bottom_menu_bar.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _allItems = [
    '청소기 대여',
    '빔프로젝터 대여',
    '카메라 대여',
    '아이패드 대여',
    '노트북 대여',
  ];

  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = _allItems;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredItems = _allItems
          .where((item) => item.contains(query.trim()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: Column(
        children: [
          // 🔍 검색창
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // 📄 검색 결과 리스트
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(item),
                  leading: const Icon(Icons.inventory_2_outlined),
                  onTap: () {
                    // TODO: 상세페이지 연결 가능
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
