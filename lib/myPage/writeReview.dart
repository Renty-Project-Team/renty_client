import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ReviewWritePage extends StatefulWidget {
  final String productTitle;
  final String? productImageUrl;
  final DateTime rentalDate;
  final String lessorName; // 대여자 이름 추가

  const ReviewWritePage({
    Key? key,
    required this.productTitle,
    this.productImageUrl,
    required this.rentalDate,
    required this.lessorName,
  }) : super(key: key);

  @override
  State<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends State<ReviewWritePage> {
  // 좋아요/싫어요 상태 (null: 선택 안함, true: 좋아요, false: 싫어요)
  bool? _isServiceSatisfied;

  // 별점 (0-5) - 기본값 0점으로 변경
  int _productRating = 0;

  // 리뷰 텍스트 컨트롤러
  final TextEditingController _reviewController = TextEditingController();

  // 이미지 관련 변수
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _reviewImages = [];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // 이미지 선택 함수
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          // 최대 10개까지만 추가
          _reviewImages.addAll(pickedFiles);
          if (_reviewImages.length > 10) {
            _reviewImages.sublist(0, 10);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지는 최대 10장까지 등록할 수 있습니다.')),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e')));
    }
  }

  // 이미지 제거 함수
  void _removeImage(int index) {
    setState(() {
      _reviewImages.removeAt(index);
    });
  }

  // 리뷰 제출 함수
  void _submitReview() {
    // 리뷰 내용 유효성 검사
    if (_isServiceSatisfied == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('대여자 서비스에 대한 평가를 선택해주세요.')));
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해주세요.')));
      return;
    }

    // 여기에 리뷰 제출 API 호출 로직 추가 예정
    // TODO: API 구현 시 활성화
    /*
    // API 클라이언트 인스턴스 생성
    // final apiClient = ApiClient();
    
    // 리뷰 데이터 준비
    Map<String, dynamic> reviewData = {
      'productId': '상품ID', // 상품 ID (파라미터로 받아야 함)
      'lessorId': '대여자ID', // 대여자 ID (파라미터로 받아야 함)
      'serviceSatisfaction': _isServiceSatisfied,
      'productRating': _productRating,
      'content': _reviewController.text
    };
    
    // 이미지 업로드를 위한 FormData 생성
    // var formData = FormData.fromMap(reviewData);
    
    // 이미지 추가
    if (_reviewImages.isNotEmpty) {
      // List<MultipartFile> imageFiles = [];
      // for (var img in _reviewImages) {
      //   imageFiles.add(
      //     await MultipartFile.fromFile(
      //       img.path,
      //       filename: img.path.split('/').last
      //     )
      //   );
      // }
      // formData.files.addAll([
      //   MapEntry('images', imageFiles),
      // ]);
    }
    
    // API 호출
    // final response = await apiClient.post('/reviews', data: formData);
    */

    // 임시 성공 메시지
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('리뷰가 작성되었습니다.')));

    // 이전 화면으로 돌아가기
    Navigator.of(context).pop(true); // true는 리뷰 작성 성공을 의미
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '리뷰쓰기',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대여자 서비스 평가
              _buildServiceRatingSection(),

              const SizedBox(height: 24),

              // 대여 상품 품질 평가
              _buildProductRatingSection(),

              const SizedBox(height: 24),

              // 리뷰 작성 영역
              _buildReviewTextField(),

              const SizedBox(height: 16),

              // 이미지 업로드 영역
              _buildImageUploadSection(),

              const SizedBox(height: 40),

              // 리뷰 작성 완료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B70FD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '리뷰 작성 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 대여자 서비스 평가 섹션
  Widget _buildServiceRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('대여자 서비스 평가'),
        const SizedBox(height: 20),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 30, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '대여자 서비스 평가',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.lessorName} 님의 질문 응답, 대여 가격, 보증금 등에 대한 만족도는 어떠셨나요?',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 싫어요 버튼
            _buildRatingButton(
              icon: Icons.thumb_down,
              isSelected: _isServiceSatisfied == false,
              onTap: () {
                setState(() {
                  _isServiceSatisfied =
                      _isServiceSatisfied == false ? null : false;
                });
              },
            ),
            const SizedBox(width: 16),
            // 좋아요 버튼
            _buildRatingButton(
              icon: Icons.thumb_up,
              isSelected: _isServiceSatisfied == true,
              onTap: () {
                setState(() {
                  _isServiceSatisfied =
                      _isServiceSatisfied == true ? null : true;
                });
              },
              isLikeButton: true,
            ),
          ],
        ),
      ],
    );
  }

  // 좋아요/싫어요 버튼 위젯 수정 - 싫어요 버튼 색상을 빨간색으로 변경
  Widget _buildRatingButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLikeButton = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected
                  ? (isLikeButton
                      ? const Color(0xFF4B70FD)
                      : Colors.red) // 싫어요 버튼 색상을 빨간색으로 변경
                  : Colors.grey[200],
        ),
        child: Icon(
          icon,
          size: 30,
          color: isSelected ? Colors.white : Colors.black45,
        ),
      ),
    );
  }

  // 대여 상품 품질 평가 섹션
  Widget _buildProductRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('대여 상품 품질 평가'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬로 변경
          children: [
            // 상품 이미지
            Container(
              width: 100,
              height: 100,
              color: Colors.grey[300],
              child:
                  widget.productImageUrl != null
                      ? Image.network(
                        widget.productImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Text(
                              '이미지 \n없음',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                      : const Center(
                        child: Text(
                          '이미지 \n없음',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start, // 상단 정렬 추가
                children: [
                  Text(
                    widget.productTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '대여종료일 : ${_formatDate(widget.rentalDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // 별점
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _productRating = index + 1;
                });
              },
              child: Icon(
                index < _productRating ? Icons.star : Icons.star_border,
                color: index < _productRating ? Colors.amber : Colors.grey,
                size: 40,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '작성 기한 : ${_formatDate(DateTime.now().add(const Duration(days: 30)))}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  // 리뷰 작성 텍스트 필드
  Widget _buildReviewTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _reviewController,
            maxLength: 500,
            maxLines: 5,
            decoration: InputDecoration(
              hintText:
                  '다른 고객님들에게 도움이 될 수 있도록 상품에 대한 솔직한 평가를 남겨주세요.\n\n전화번호, SNS계정 등 개인 정보 및 욕설이 포함된 설명글 입력은 제한될 수 있습니다.',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              counterText: '', // 내부 카운터 텍스트 숨기기
            ),
            onChanged: (text) {
              // 텍스트가 변경될 때마다 화면 갱신을 위해 setState 호출
              setState(() {});
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_reviewController.text.length}/500',
              style: TextStyle(
                fontSize: 12,
                color:
                    _reviewController.text.length > 500
                        ? Colors.red
                        : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 이미지 업로드 섹션
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.grey),
                    Text(
                      '${_reviewImages.length}/10',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (_reviewImages.isNotEmpty)
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reviewImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(
                                    File(_reviewImages[index].path),
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // 날짜 포맷팅 함수
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
