import 'package:flutter/material.dart';
import 'global_theme.dart';
import 'SearchCategory.dart';
import 'bottom_menu_bar.dart';


class SearchPage extends StatelessWidget {
  const SearchPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '검색어를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(width: 6), // 텍스트 필드와 아이콘 사이 간격
              IconButton(
                icon: Icon(Icons.search,size:30),
                onPressed: () {
                  // 검색 버튼 눌렀을 때 동작
                  print("검색 버튼 클릭됨");
                },
              ),
            ],
          ),
        ),
      ),
      body: Center(child: SearchCategories()),
    );
  }
}

