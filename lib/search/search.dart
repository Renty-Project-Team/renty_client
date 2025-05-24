import 'package:flutter/material.dart';
import 'searchResultPage.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key}); // ✅ const 생성자

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.checkroom, 'label': 'ClothingAndFashion', 'kor': '의류 및 패션'},
    {'icon': Icons.computer, 'label': 'Electronics', 'kor': '전자제품'},
    {'icon': Icons.chair, 'label': 'FurnitureAndInterior', 'kor': '가구 및 인테리어'},
    {'icon': Icons.brush, 'label': 'BeautyAndCosmetics', 'kor': '뷰티/미용'},
    {'icon': Icons.book, 'label': 'Books', 'kor': '도서'},
    {'icon': Icons.create, 'label': 'Stationery', 'kor': '문구'},
    {'icon': Icons.directions_car, 'label': 'CarAccessories', 'kor': '자동차용품'},
    {'icon': Icons.sports_tennis, 'label': 'Sports', 'kor': '스포츠레저'},
    {'icon': Icons.baby_changing_station, 'label': 'InfantsAndChildren', 'kor': '유아 및 아동'},
    {'icon': Icons.pets, 'label': 'PetSupplies', 'kor': '반려동물 용품'},
    {'icon': Icons.local_hospital, 'label': 'HealthAndMedical', 'kor': '건강 및 의료'},
    {'icon': Icons.hiking, 'label': 'Hobbies', 'kor': '취미 및 여가'},
  ];

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
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색어를 입력해주세요',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.search, size: 30),
                onPressed: () {
                  final query = _searchController.text.trim();
                  if (query.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultPage(
                          initialQuery: query,  // ✅ 이름 수정
                          initialCategory: null, ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Divider(thickness: 1, height: 1, color: Colors.grey[300]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: GridView.builder(
                itemCount: categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SearchResultPage(
                            initialQuery: '',  // ✅ 이름 수정
                            initialCategory: category['label'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category['icon'], size: 35),
                          const SizedBox(height: 8),
                          Text(
                            category['kor'],
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
      ),
    );
  }
}
