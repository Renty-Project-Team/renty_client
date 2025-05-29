import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'searchService.dart';
import 'package:renty_client/post/postDataFile.dart';
import 'package:renty_client/post/AdBoard.dart';
import 'package:renty_client/post/mainBoard.dart'; // ProductCard 재활용
import 'package:renty_client/post/buyerPost/buyerPost.dart';

class SearchResultPage extends StatefulWidget {
  final String initialQuery;
  final String? initialCategory;

  const SearchResultPage({
    required this.initialQuery,
    this.initialCategory,
    super.key,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  List<BuyerPost> _buyerPosts = [];
  bool _isLoading = false;
  bool _hasError = false;

  String? selectedPriceUnit;
  RangeValues selectedRange = RangeValues(0, 100000);
  bool convertToDaily = false;
  int selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.all_inclusive, 'label': '', 'kor': '전체'},
    {'icon': Icons.checkroom, 'label': 'ClothingAndFashion', 'kor': '의류 및 패션'},
    {'icon': Icons.computer, 'label': 'Electronics', 'kor': '전자제품'},
    {'icon': Icons.chair, 'label': 'FurnitureAndInterior', 'kor': '가구 및 인테리어'},
    {'icon': Icons.brush, 'label': 'Beauty', 'kor': '뷰티/미용'},
    {'icon': Icons.book, 'label': 'Books', 'kor': '도서'},
    {'icon': Icons.create, 'label': 'Stationery', 'kor': '문구'},
    {'icon': Icons.directions_car, 'label': 'CarAccessories', 'kor': '자동차용품'},
    {'icon': Icons.sports_tennis, 'label': 'Sports', 'kor': '스포츠레저'},
    {'icon': Icons.baby_changing_station, 'label': 'InfantsAndChildren', 'kor': '유아 및 아동'},
    {'icon': Icons.pets, 'label': 'PetSupplies', 'kor': '반려동물 용품'},
    {'icon': Icons.local_hospital, 'label': 'HealthAndMedical', 'kor': '건강 및 의료'},
    {'icon': Icons.hiking, 'label': 'Hobbies', 'kor': '취미 및 여가'},
  ];
  List<dynamic> _combinedList() {
    final List<dynamic> combined = [];

    combined.addAll(_products);
    combined.addAll(_buyerPosts);

    combined.sort((a, b) {
      final aDate = a is Product ? a.createdAt : (a as BuyerPost).createdAt;
      final bDate = b is Product ? b.createdAt : (b as BuyerPost).createdAt;
      return bDate.compareTo(aDate); // 최신순 정렬
    });

    return combined;
  }
  final Map<String, String> priceUnitLabels = {
    'Day': '일',
    'Week': '주',
    'Month': '월',
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;

    if (widget.initialCategory != null) {
      final index = categories.indexWhere((c) => c['label'] == widget.initialCategory);
      if (index >= 0) selectedCategoryIndex = index;
    }

    _fetchSearchResults();
  }

  double convertToDayUnit(double price, String unit) {
    switch (unit) {
      case 'Week': return price / 7;
      case 'Month': return price / 30;
      default: return price;
    }
  }

  List<Product> _applyFilters(List<Product> products) {
    return products.where((p) {
      double price = p.price ?? 0.0;
      if (convertToDaily) price = convertToDayUnit(price, p.priceUnit);

      if (selectedPriceUnit != null && selectedPriceUnit!.isNotEmpty && !convertToDaily) {
        if (p.priceUnit != selectedPriceUnit) return false;
      }

      return price >= selectedRange.start && price <= selectedRange.end;
    }).toList();
  }

  Future<void> _fetchSearchResults() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final selectedCategory = categories[selectedCategoryIndex]['label'];
      final query = _searchController.text.trim();

      final products = await SearchService().searchProducts(
        query: query,
        category: selectedCategory,
      );
      final buyers = await SearchService().searchBuyerPosts(
        titleWords: query.isNotEmpty ? [query] : null,
        category: selectedCategory?.isNotEmpty == true ? [selectedCategory!] : null,
      );

      setState(() {
        _products = _applyFilters(products);
        _buyerPosts = buyers;
        _isLoading = false;
      });
    } on DioException catch (e) {
      print('검색 실패: ${e.response}');
      setState(() {
        _products = [];
        _buyerPosts = [];
        _hasError = false;
        _isLoading = false;
      });
    } catch (e) {
      print('예외 발생: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '검색어를 입력해주세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: (_) => _fetchSearchResults(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search, size: 24),
              padding: EdgeInsets.zero,
              onPressed: _fetchSearchResults,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            height: 60,
            child: Row(
              children: [
                // ✅ 카테고리 탭들 - 좌측
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(categories.length, (index) {
                        final category = categories[index];
                        final isSelected = selectedCategoryIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategoryIndex = index;
                            });
                            _fetchSearchResults();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent, // 이걸로 color 설정
                              border: isSelected
                                  ? Border(
                                bottom: BorderSide(width: 2, color: Colors.blue),
                              )
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  category['icon'],
                                  size: 20,
                                  color: isSelected ? Colors.blue : Colors.black,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  category['kor'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                // ✅ 필터 아이콘 - 우측
                IconButton(
                  icon: Icon(Icons.filter_list, size: 24),
                  padding: EdgeInsets.only(right: 8),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        String? tempUnit = selectedPriceUnit;
                        RangeValues tempRange = selectedRange;
                        bool tempConvert = convertToDaily;

                        return StatefulBuilder(
                          builder: (context, setModalState) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ✅ 단위 선택
                                  DropdownButton<String>(
                                    value: tempUnit,
                                    hint: Text("단위 선택"),
                                    items: ['Day', 'Week', 'Month'].map((unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: Text(priceUnitLabels[unit]!),
                                      );
                                    }).toList(),
                                    onChanged: (val) => setModalState(() => tempUnit = val),
                                  ),

                                  // ✅ 단위 환산 여부 체크
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: tempConvert,
                                        onChanged: (val) => setModalState(() => tempConvert = val ?? false),
                                      ),
                                      Text("월,주 단위의 가격도 일(Day)로 환산해서 필터링",style: TextStyle(fontSize: 15))
                                    ],
                                  ),

                                  // ✅ 가격 슬라이더
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("가격 범위"),
                                      SizedBox(height: 12),

                                      // ✅ 직접 입력
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(labelText: '최소 가격'),
                                              controller: TextEditingController(text: tempRange.start.toInt().toString()),
                                              onChanged: (value) {
                                                final newMin = double.tryParse(value);
                                                if (newMin != null && newMin <= tempRange.end) {
                                                  setModalState(() => tempRange = RangeValues(newMin, tempRange.end));
                                                }
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: TextField(
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(labelText: '최대 가격'),
                                              controller: TextEditingController(text: tempRange.end.toInt().toString()),
                                              onChanged: (value) {
                                                final newMax = double.tryParse(value);
                                                if (newMax != null && newMax >= tempRange.start) {
                                                  setModalState(() => tempRange = RangeValues(tempRange.start, newMax));
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: 16),

                                      // ✅ 슬라이더
                                      RangeSlider(
                                        values: tempRange,
                                        min: 0,
                                        max: 100000,
                                        divisions: 100,
                                        labels: RangeLabels(
                                          tempRange.start.toInt().toString(),
                                          tempRange.end.toInt().toString(),
                                        ),
                                        onChanged: (range) => setModalState(() => tempRange = range),
                                      ),
                                    ],
                                  ),
                                  // ✅ 적용 버튼
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedPriceUnit = tempUnit;
                                        selectedRange = tempRange;
                                        convertToDaily = tempConvert;

                                        // ✅ 기존 _products에 필터 적용
                                        _products = _applyFilters(_products);
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: Text("적용"),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );

                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text('검색 중 오류가 발생했습니다.'))
          : (_products.isEmpty && _buyerPosts.isEmpty)
          ? Center(child: Text('검색 결과가 없습니다.', style: TextStyle(fontSize: 20)))
          : ListView.separated(
        itemCount: _combinedList().length,
        separatorBuilder: (context, index) {
          // 광고 삽입: 5개마다
          if ((index + 1) % 5 == 0) {
            return AdCard();
          }
          return SizedBox(height: 0);
        },
        itemBuilder: (context, index) {
          final item = _combinedList()[index];
          if (item is Product) {
            return ProductCard(product: item);
          } else if (item is BuyerPost) {
            return BuyerPostCard(post: item);
          } else {
            return SizedBox(); // 안전 장치
          }
        },
      ),

    );
  }
}