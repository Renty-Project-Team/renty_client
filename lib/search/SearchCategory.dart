import 'package:flutter/material.dart';

class SearchCategories extends StatelessWidget {  //아이콘 출가 할거 있으면 여기에 적으면 됨
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.checkroom, 'label': '의류 및 패션'},
    {'icon': Icons.computer, 'label': '전자제품'},
    {'icon': Icons.chair, 'label': '가구 및 인테리어'},
    {'icon': Icons.brush, 'label': '뷰티/미용'},
    {'icon': Icons.book, 'label': '도서'},
    {'icon': Icons.create, 'label': '문구'},
    {'icon': Icons.directions_car, 'label': '자동차용품'},
    {'icon': Icons.sports_tennis, 'label': '스포츠레저'},
    {'icon': Icons.baby_changing_station, 'label': '유아 및 아동'},
    {'icon': Icons.pets, 'label': '반려동물 용품'},
    {'icon': Icons.local_hospital, 'label': '건강 및 의료'},
    {'icon': Icons.hiking, 'label': '취미 및 여가'},
  ];@override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(
          thickness: 1,
          height: 1,
          color: Colors.grey[300],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: GridView.builder(
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 5,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    print("클릭한 카테고리: ${category['label']}");
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.transparent, // 시각적으로는 투명하지만 터치 가능
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(category['icon'], size: 35),
                        const SizedBox(height: 5),
                        Text(
                          category['label'],
                          style: const TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}