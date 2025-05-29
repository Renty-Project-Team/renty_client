import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:intl/intl.dart';

class ReviewWritePage extends StatefulWidget {
  final int itemId;
  final String productTitle;
  final String? productImageUrl;
  final DateTime rentalDate;
  final String sellerName;
  final String? sellerProfileImageUrl; // 판매자 프로필 이미지 URL

  const ReviewWritePage({
    Key? key,
    required this.itemId,
    required this.productTitle,
    this.productImageUrl,
    required this.rentalDate,
    required this.sellerName,
    this.sellerProfileImageUrl, // 생성자에 프로필 이미지 파라미터 추가
  }) : super(key: key);

  @override
  State<ReviewWritePage> createState() => _ReviewWritePageState();
}

class _ReviewWritePageState extends State<ReviewWritePage> {
  bool? _isServiceSatisfied;
  int _productRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _reviewImages = [];
  String? _fullSellerProfileImageUrl; // 도메인 추가된 완전한 URL

  @override
  void initState() {
    super.initState();
    // 프로필 이미지 URL 처리
    if (widget.sellerProfileImageUrl != null &&
        widget.sellerProfileImageUrl!.isNotEmpty) {
      _fullSellerProfileImageUrl = _getFullImageUrl(
        widget.sellerProfileImageUrl!,
      );
    }
  }

  // URL이 상대 경로일 경우 도메인 추가
  String _getFullImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // 도메인 추가
    final apiClient = ApiClient();
    return '${apiClient.getDomain}$url';
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
          // 최대 5개까지만 추가
          if (_reviewImages.length + pickedFiles.length > 5) {
            final int canAdd = 5 - _reviewImages.length;
            if (canAdd > 0) {
              _reviewImages.addAll(pickedFiles.take(canAdd));
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지는 최대 5장까지 등록할 수 있습니다.')),
            );
          } else {
            _reviewImages.addAll(pickedFiles);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e')));
    }
  }

  // 리뷰 제출 함수
  Future<void> _submitReview() async {
    // 리뷰 내용 유효성 검사
    if (_isServiceSatisfied == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('판매자 서비스에 대한 평가를 선택해주세요.')));
      return;
    }

    if (_productRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품 만족도를 선택해주세요.')));
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해주세요.')));
      return;
    }

    try {
      // API 요청 준비
      var formData = FormData();

      // 기본 필드 추가
      formData.fields.addAll([
        MapEntry('ItemId', widget.itemId.toString()),
        MapEntry('SellerEvaluation', _isServiceSatisfied == true ? '1' : '0'),
        MapEntry('Satisfaction', _productRating.toString()),
        MapEntry('Content', _reviewController.text),
      ]);

      // 이미지 추가
      if (_reviewImages.isNotEmpty) {
        formData.fields.add(MapEntry('ImageAction', 'Upload'));

        for (var i = 0; i < _reviewImages.length; i++) {
          final file = await MultipartFile.fromFile(
            _reviewImages[i].path,
            filename: 'image_$i.jpg',
          );
          formData.files.add(MapEntry('Images', file));
        }
      } else {
        formData.fields.add(MapEntry('ImageAction', 'None'));
      }

      // API 호출
      final response = await ApiClient().client.put(
        '/Product/review',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('리뷰가 성공적으로 등록되었습니다.')));
          Navigator.of(context).pop(true); // true를 반환하여 리뷰 작성 완료 표시
        }
      } else {
        throw Exception('리뷰 등록에 실패했습니다.');
      }
    } catch (e) {
      String errorMessage = '리뷰 등록 중 오류가 발생했습니다.';

      if (e is DioError && e.response != null) {
        if (e.response!.data is Map && e.response!.data['detail'] != null) {
          errorMessage = e.response!.data['detail'];
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
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
              // 판매자 서비스 평가
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

  // 판매자 서비스 평가 섹션
  Widget _buildServiceRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('판매자 서비스 평가'),
        const SizedBox(height: 20),
        Row(
          children: [
            // 판매자 프로필 이미지
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  _fullSellerProfileImageUrl != null
                      ? NetworkImage(_fullSellerProfileImageUrl!)
                      : null,
              child:
                  _fullSellerProfileImageUrl == null
                      ? Text(
                        widget.sellerName.isNotEmpty
                            ? widget.sellerName[0]
                            : "?",
                        style: TextStyle(color: Colors.grey[700]),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '판매자 서비스 평가',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.sellerName} 님의 질문 응답, 대여 가격, 보증금 등에 대한 만족도는 어떠셨나요?',
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
              isLikeButton: false,
              onTap: () {
                setState(() {
                  _isServiceSatisfied = false;
                });
              },
            ),
            const SizedBox(width: 24),
            // 좋아요 버튼
            _buildRatingButton(
              icon: Icons.thumb_up,
              isSelected: _isServiceSatisfied == true,
              isLikeButton: true,
              onTap: () {
                setState(() {
                  _isServiceSatisfied = true;
                });
              },
            ),
          ],
        ),
      ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  widget.productImageUrl != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.productImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print(
                              '이미지 로드 오류: $error, URL: ${widget.productImageUrl}',
                            );
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
                        ),
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
                mainAxisAlignment: MainAxisAlignment.start,
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
      ],
    );
  }

  // 리뷰 텍스트 입력 필드
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
              counterText: '',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0, right: 8.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_reviewController.text.length}/500',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            Text(
              '사진 첨부',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_reviewImages.length}/5)',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 이미지 추가 버튼
            if (_reviewImages.length < 5)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
            // 선택된 이미지들
            ..._reviewImages.asMap().entries.map((entry) {
              final int index = entry.key;
              final XFile image = entry.value;
              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(image.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap:
                          () => setState(() => _reviewImages.removeAt(index)),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // 섹션 제목 위젯
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 날짜 포맷 함수
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 평가 버튼 위젯
  Widget _buildRatingButton({
    required IconData icon,
    required bool isSelected,
    required bool isLikeButton,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected
                  ? (isLikeButton ? const Color(0xFF4B70FD) : Colors.red)
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
}

// API 요청에 사용할 Enum
enum SellerEvaluation { none, good, bad }

enum ImageAction { upload, delete, none }
