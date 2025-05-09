import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:renty_client/main.dart';

enum ItemCondition { used, new_ }

enum CategoryType {
  ClothingAndFashion('의류/패션'),
  Electronics("전자제품"),
  FurnitureAndInterior("가구/인테리어"),
  Beauty("뷰티/미용"),
  Books("도서"),
  Stationery("문구"),
  CarAccessories("자동차 용품"),
  Sports('스포츠/레저'),
  InfantsAndChildren('유아/아동'),
  PetSupplies('반려동물 용품'),
  HealthAndMedical('건강/의료'),
  Hobbies('취미/여가');

  const CategoryType(this.displayName);
  final String displayName;
}

enum PriceUnit {
  Day('일'),
  Week('주'),
  Month('월');

  const PriceUnit(this.displayName);
  final String displayName;
}

class ProductUpload extends StatefulWidget {
  const ProductUpload({super.key});

  @override
  State<ProductUpload> createState() => _ProductUploadState();

}

class _ProductUploadState extends State<ProductUpload> {
  final _formKey = GlobalKey<FormState>(); // 폼 상태 관리를 위한 키

  // 입력 컨트롤러
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();

  // 선택된 값들
  List<XFile> _images = []; // 선택된 이미지 파일 목록
  String? _selectedCategory; // 선택된 카테고리
  final ItemCondition _selectedCondition = ItemCondition.used; // 선택된 상품 상태 (기본값: 중고)
  String _selectedPriceUnit = PriceUnit.Day.name; // 선택된 대여 가격 단위 (기본값: 일)

  final ImagePicker _picker = ImagePicker(); // 이미지 피커 인스턴스

  // 이미지 선택 함수
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        // imageQuality: 80, // 이미지 품질 조절 (0-100)
        // maxWidth: 1000, // 이미지 최대 너비 조절
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          // 최대 10개까지만 추가하도록 제한 (예시)
          _images.addAll(pickedFiles);
          if (_images.length > 10) {
            _images = _images.sublist(_images.length - 10);
            // 사용자에게 알림 표시 (옵션)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('사진은 최대 10장까지 등록할 수 있습니다.')),
            );
          }
        });
      }
    } catch (e) {
      // 에러 처리 (예: 권한 거부)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 선택된 이미지 제거 함수
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대여 상품 등록'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: 임시 저장 로직 구현
            },
            child: const Text(
              '임시 저장',
              style: TextStyle(color: Colors.grey), // 앱 디자인에 맞게 색상 조절
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 이미지 등록 섹션 ---
                _buildImagePickerSection(),
                const SizedBox(height: 24.0),
                // --- 제목 ---
                _buildSectionTitle('제목'),
                TextFormField(
                  controller: _titleController,
                  decoration: _buildInputDecoration(hintText: '제목을 입력하세요.', color: Colors.grey[400]!),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '제목을 입력해주세요.';
                    }
                    else if (value.length > 50) {
                      return '제목은 최대 50자까지 입력 가능합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

              // --- 카테고리 ---
                _buildSectionTitle('카테고리'),
                 DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('카테고리 선택'),
                  decoration: _buildInputDecoration(color: Colors.grey[400]!),
                  items: CategoryType.values.map((var category) {
                    return DropdownMenuItem<String>(
                      value: category.name,
                      child: Text(category.displayName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '카테고리를 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // --- 대여 가격 ---
                _buildSectionTitle('대여 가격'),
                Row(
                  children: [
                    // 가격 단위 드롭다운
                    SizedBox(
                      width: 100, // 너비 조절
                      child: DropdownButtonFormField<String>(
                        value: _selectedPriceUnit,
                        decoration: _buildInputDecoration(),
                        items: PriceUnit.values.map((var unit) {
                          return DropdownMenuItem<String>(
                            value: unit.name,
                            child: Text(unit.displayName),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedPriceUnit = newValue!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 가격 입력 필드
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: _buildInputDecoration(hintText: '가격', color: Colors.grey[400]!, suffixText: '원', 
                          suffixStyle: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 숫자만 입력 가능
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '가격을 입력해주세요.';
                          }
                          // 필요시 숫자 범위 검증 추가
                          return null;
                        },
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // const Text('원', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 24.0),

                // --- 설명 ---
                _buildSectionTitle('설명'),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(fontSize: 14), // 설명 텍스트 스타일
                  decoration: InputDecoration(
                    hintText: '등록하실 대여 상품의 자세한 설명을 적어주세요. 법적으로 판매가 금지된 일부 상품은 게시가 제한될 수 있습니다.\n\n 전화번호, SNS계정 등 개인 정보 및 욕설이 포함된 설명글 입력은 제한 될 수 있습니다.',
                    hintStyle: TextStyle(fontSize: 10, color: Colors.grey[300]), // 힌트 텍스트 색상
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                    alignLabelWithHint: true, // Multi-line에서 hintText가 위로 가게 함
                  ),
                  maxLines: 6, // 여러 줄 입력 가능
                  maxLength: 2000, // 최대 글자 수 제한 및 카운터 표시
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '설명을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                // --- 보증금 ---
                 _buildSectionTitle('보증금'), // 보증금은 선택사항일 수 있음
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        decoration: _buildInputDecoration(hintText:  '보증금', color: Colors.grey[400]!, suffixText: '원', 
                          suffixStyle: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.bold)),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '보증금을 입력해주세요.';
                          }
                          // 필요시 숫자 범위 검증 추가
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                Text(
                  '※ 보증금은 계약 조건에 따라 반환되거나 일부 차감될 수 있으며, 불공정한 조항이 포함될 경우 처벌을 받을 수 있습니다. 계약 체결 시 보증금 반환 조건을 명확히 기재하여 주시길 바랍니다.',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32.0),

                // --- 등록 버튼 ---
                SizedBox(
                  width: double.infinity, // 버튼 너비 최대로
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary, // 버튼 배경색
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder( // 버튼 모양 둥글게
                        borderRadius: BorderRadius.circular(8.0),
                      )
                    ),
                    child: const Text(
                      '상품 등록',
                      style: TextStyle(color: Colors.white), // 버튼 텍스트 색상
                    ),
                  ),
                ),
              ]
            ),
          )
        )
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText, Color? color, double? fontSize = 13, String? suffixText, TextStyle? suffixStyle}) {
    return InputDecoration(
      hintText: hintText,
      suffixText: suffixText, // 입력 영역 안에 표시될 텍스트
      suffixStyle: suffixStyle,
      hintStyle: TextStyle(fontSize: fontSize, color: color), // 힌트 텍스트 색상
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey), // 밑줄 색상 지정 (회색)
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // 포커스 시 앱의 주요 색상 사용
        // borderSide: BorderSide(color: Colors.blue, width: 2.0), // 색상 및 두께 지정 가능
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red), // 에러 시 빨간색
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2.0), // 포커스 시 에러 빨간색
      ),
    );
  }

  // 섹션 제목 위젯 빌더
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 이미지 피커 섹션 위젯 빌더
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('사진 등록 (${_images.length}/10)'), // 사진 개수 표시
        const SizedBox(height: 8),
        SizedBox(
          height: 100, // 이미지 목록 높이 고정
          child: ListView.builder(
            scrollDirection: Axis.horizontal, // 가로 스크롤
            itemCount: _images.length + 1, // 등록 버튼 포함
            itemBuilder: (context, index) {
              if (index == 0) {
                // 사진 추가 버튼
                return _buildAddImageButton();
              }
              // 선택된 이미지 썸네일
              final imageIndex = index - 1;
              return _buildImageThumbnail(_images[imageIndex], imageIndex);
            },
          ),
        ),
      ],
    );
  }

  // 사진 추가 버튼
  Widget _buildAddImageButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), // 버튼 오른쪽 여백
      child: InkWell(
        onTap: _pickImages,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey[400]!),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 30, color: Colors.grey),
              SizedBox(height: 4),
              Text('사진 추가', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  // 선택된 이미지 썸네일
  Widget _buildImageThumbnail(XFile image, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0), // 이미지 오른쪽 여백
      child: Stack( // 이미지 위에 삭제 버튼을 올리기 위해 Stack 사용
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
              image: DecorationImage(
                image: FileImage(File(image.path)), // XFile -> File -> FileImage
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 삭제 버튼
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
          // 대표 이미지 표시 (첫 번째 이미지를 대표로 가정)
          if (index == 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0),
                  ),
                ),
                child: const Text(
                  '대표 이미지',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            )
        ],
      ),
    );
  }

  // 폼 제출 함수
  void _submitForm() async {
    if (_formKey.currentState!.validate()) { // 폼 유효성 검사
      // 유효성 검사 통과 시 로직 실행
      if (_images.isEmpty) {
        // 이미지 미등록 시 알림 (선택 사항)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진을 1장 이상 등록해주세요.')),
        );
        return; // 이미지 없으면 제출 중단
      }

      // 데이터 수집
      final title = _titleController.text;
      final category = _selectedCategory;
      final condition = _selectedCondition;
      final price = _priceController.text;
      final priceUnit = _selectedPriceUnit;
      final description = _descriptionController.text;
      final deposit = _depositController.text; // 빈 문자열이면 null 처리
      final imageFiles = _images.map((xfile) => File(xfile.path)).toList(); // API 전송을 위해 File 객체 리스트로 변환

      
      print('--- 폼 제출 데이터 ---');
      print('제목: $title');
      print('카테고리: $category');
      print('상태: $condition');
      print('가격: $price $priceUnit당');
      print('설명: $description');
      print('보증금: $deposit');
      print('이미지 개수: ${imageFiles.length}');
      for (var img in imageFiles) {
        print('이미지 경로: ${img.path}');
      }

      List<MultipartFile> multipartImageList = [];
      for (var image in imageFiles) {
        multipartImageList.add(await MultipartFile.fromFile(image.path, filename: image.path.split('/\\').last));
      }

      var formData = FormData.fromMap({
        "Title" : title,
        "Category" : category,
        "Price" : price,
        "Unit" : priceUnit,
        "Description" : description,
        "Deposit" : deposit,
        "Images" : multipartImageList,
      });

      try {
        var response = await apiClient.client.post(
          '/Product/upload', 
          data: formData
        );

        if (response.statusCode == 200) {
          // 예시: 성공 메시지 표시 및 이전 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 등록되었습니다.')),
          );
          // TODO: 현재 네비게이터를 상세 게시물 화면으로 변경.
          // Navigator.pop(context); // 등록 후 이전 화면으로 돌아가기
        } else {
          // 서버에서 예상치 못한 상태 코드 반환
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품 등록 실패')),
          );
        }

        
      } on DioException catch (e) {
        // Dio 관련 오류 처리
        String errorMessage = '업로드 오류 발생';
        if (e.response != null) {
          // 서버가 오류 응답을 반환한 경우
          print('서버 오류 응답: ${e.response?.data}');
          print('서버 오류 상태 코드: ${e.response?.statusCode}');
          if (e.response?.statusCode == 401) {
            errorMessage = '로그인 상태에 문제가 발생하였습니다.\n다시 로그인 해 주세요.';
          }
          else if (e.response?.statusCode == 400) {
            errorMessage = '${e.response?.data['errors']}';
          } 
          else {
            errorMessage = '서버 오류 (${e.response?.statusCode})';
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
                   e.type == DioExceptionType.sendTimeout ||
                   e.type == DioExceptionType.receiveTimeout) {
          errorMessage = '네트워크 타임아웃 발생';
        } else if (e.type == DioExceptionType.connectionError) {
           errorMessage = '네트워크 연결 오류 발생';
        }
         else {
          // 기타 Dio 오류 (요청 설정 오류 등)
          errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
      

      
    } else {
      // 유효성 검사 실패 시 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력되지 않은 필수 항목이 있습니다.')),
      );
    }
  }
}


  

