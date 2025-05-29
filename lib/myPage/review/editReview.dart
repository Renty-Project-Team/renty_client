import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/myPage/review/reviewModel.dart';

class EditReviewScreen extends StatefulWidget {
  final ReviewModel review;

  const EditReviewScreen({Key? key, required this.review}) : super(key: key);

  @override
  State<EditReviewScreen> createState() => _EditReviewScreenState();
}

class _EditReviewScreenState extends State<EditReviewScreen> {
  late bool? _isServiceSatisfied;
  late int _productRating;
  late TextEditingController _reviewController;
  final ImagePicker _picker = ImagePicker();
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];
  String _imageAction = 'None';
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    // 기존 리뷰 데이터로 초기화
    _isServiceSatisfied =
        widget.review.sellerEvaluation == 'Good'
            ? true
            : (widget.review.sellerEvaluation == 'Bad' ? false : null);
    _productRating = widget.review.satisfaction;
    _reviewController = TextEditingController(text: widget.review.content);
    _existingImages = List.from(widget.review.imagesUrl);
  }

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
          // 최대 5개까지만 추가 (기존 이미지와 새 이미지 합쳐서)
          final int totalImagesCount =
              _existingImages.length + _newImages.length + pickedFiles.length;
          if (totalImagesCount > 5) {
            final int canAdd = 5 - (_existingImages.length + _newImages.length);
            if (canAdd > 0) {
              _newImages.addAll(pickedFiles.take(canAdd));
              _imageAction = 'Upload';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지는 최대 5장까지 등록할 수 있습니다.')),
            );
          } else {
            _newImages.addAll(pickedFiles);
            _imageAction = 'Upload';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지를 가져오는 중 오류가 발생했습니다: $e')));
    }
  }

  // 기존 이미지 삭제 함수
  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
      if (_existingImages.isEmpty && _newImages.isEmpty) {
        _imageAction = 'Delete';
      } else if (_newImages.isNotEmpty) {
        _imageAction = 'Upload';
      }
    });
  }

  // 새 이미지 삭제 함수
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      if (_newImages.isEmpty && _existingImages.isEmpty) {
        _imageAction = 'Delete';
      } else if (_newImages.isEmpty && _existingImages.isNotEmpty) {
        _imageAction = 'None';
      }
    });
  }

  // 리뷰 수정 제출 함수
  Future<void> _submitReviewEdit() async {
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
        MapEntry('ItemId', widget.review.itemId.toString()),
        MapEntry('SellerEvaluation', _isServiceSatisfied == true ? '1' : '2'),
        MapEntry('Satisfaction', _productRating.toString()),
        MapEntry('Content', _reviewController.text),
        MapEntry('ImageAction', _imageAction),
      ]);

      // 이미지 처리
      if (_imageAction == 'Upload' && _newImages.isNotEmpty) {
        for (var i = 0; i < _newImages.length; i++) {
          final file = await MultipartFile.fromFile(
            _newImages[i].path,
            filename: 'image_$i.jpg',
          );
          formData.files.add(MapEntry('Images', file));
        }
      }

      // API 호출
      final response = await _apiClient.client.put(
        '/Product/review',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('리뷰가 성공적으로 수정되었습니다.')));
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('리뷰 수정에 실패했습니다.');
      }
    } catch (e) {
      String errorMessage = '리뷰 수정 중 오류가 발생했습니다.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String baseDomain = _apiClient.getDomain;

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
          '리뷰 수정하기',
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
              _buildImageSection(baseDomain),

              const SizedBox(height: 40),

              // 리뷰 수정 완료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReviewEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B70FD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '리뷰 수정 완료',
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
        const Text(
          '판매자 서비스 평가',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            // 판매자 프로필 이미지
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  widget.review.sellerProfileImageUrl != null
                      ? NetworkImage(
                        widget.review.sellerProfileImageUrl!.startsWith('http')
                            ? widget.review.sellerProfileImageUrl!
                            : '${_apiClient.getDomain}${widget.review.sellerProfileImageUrl!}',
                      )
                      : null,
              child:
                  widget.review.sellerProfileImageUrl == null
                      ? Text(
                        widget.review.sellerName.isNotEmpty
                            ? widget.review.sellerName[0]
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
                    '${widget.review.sellerName} 님의 질문 응답, 대여 가격, 보증금 등에 대한 만족도는 어떠셨나요?',
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _isServiceSatisfied = false;
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isServiceSatisfied == false
                          ? Colors.red
                          : Colors.grey[200],
                ),
                child: Icon(
                  Icons.thumb_down,
                  size: 30,
                  color:
                      _isServiceSatisfied == false
                          ? Colors.white
                          : Colors.black45,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // 좋아요 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  _isServiceSatisfied = true;
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isServiceSatisfied == true
                          ? const Color(0xFF4B70FD)
                          : Colors.grey[200],
                ),
                child: Icon(
                  Icons.thumb_up,
                  size: 30,
                  color:
                      _isServiceSatisfied == true
                          ? Colors.white
                          : Colors.black45,
                ),
              ),
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
        const Text(
          '대여 상품 품질 평가',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.review.itemImageUrl.startsWith('http')
                    ? widget.review.itemImageUrl
                    : '${_apiClient.getDomain}${widget.review.itemImageUrl}',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Text(
                        '이미지\n없음',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    widget.review.itemTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
              hintText: '다른 고객님들에게 도움이 될 수 있도록 상품에 대한 솔직한 평가를 남겨주세요.',
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

  // 이미지 섹션
  Widget _buildImageSection(String baseDomain) {
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
              '(${_existingImages.length + _newImages.length}/5)',
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
            if (_existingImages.length + _newImages.length < 5)
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

            // 기존 이미지들
            ..._existingImages.asMap().entries.map((entry) {
              final int index = entry.key;
              final String imageUrl = entry.value;
              final String fullImageUrl =
                  imageUrl.startsWith('http')
                      ? imageUrl
                      : '$baseDomain$imageUrl';

              return Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(fullImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _removeExistingImage(index),
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
            }).toList(),

            // 새로 추가한 이미지들
            ..._newImages.asMap().entries.map((entry) {
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
                      onTap: () => _removeNewImage(index),
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
            }).toList(),
          ],
        ),
      ],
    );
  }
}
