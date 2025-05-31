import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'buyerPostService.dart';
import 'package:renty_client/detailed_post/buyerDetail/buyerDetailPost.dart';
class PostUploadPage extends StatefulWidget {
  const PostUploadPage({super.key});

  @override
  State<PostUploadPage> createState() => _PostUploadPageState();
}

class _PostUploadPageState extends State<PostUploadPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  String? _selectedCategory;

  final Map<String, String> categoryMap = {
    'ClothingAndFashion': '의류 및 패션',
    'Electronics': '전자제품',
    'FurnitureAndInterior': '가구 및 인테리어',
    'Beauty': '뷰티/미용',
    'Books': '도서',
    'Stationery': '문구',
    'CarAccessories': '자동차용품',
    'Sports': '스포츠',
    'InfantsAndChildren': '유아 및 아동',
    'PetSupplies': '반려동물 용품',
    'HealthAndMedical': '건강 및 의료',
    'Hobbies': '취미',
  };

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 80);
    if (_selectedImages.length + images.length > 10) {
      _showMessage('이미지는 최대 10장까지 업로드할 수 있습니다.');
      return;
    }
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final category = _selectedCategory;

    if (title.isEmpty || desc.isEmpty || category == null) {
      _showMessage('모든 항목을 입력해주세요.');
      return;
    }

    try {
      int postid  =  await PostUploadService.uploadPost(
        title: title,
        description: desc,
        category: category,
        images: _selectedImages,
      );
      Navigator.pushReplacement(context,
        MaterialPageRoute(
          builder: (context) => BuyerPostDetailPage(postId: postid), // 상세 페이지에 Product 전달
        ),
      );
      _showMessage('업로드 성공!');

    } catch (e) {
      _showMessage('오류 발생: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildImageSelector() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 100,
              height: 100,
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 28, color: Colors.grey.shade600),
                    SizedBox(height: 4),
                    Text(
                      '${_selectedImages.length}/10',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ..._selectedImages.asMap().entries.map((entry) {
            final index = entry.key;
            final img = entry.value;
            return Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(File(img.path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImages.removeAt(index)),
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '대표사진',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시글 작성'),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.save_alt),
            onPressed: () => _showMessage('임시 저장 완료'),
            label: Text(
              '임시 저장',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이미지', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildImageSelector(),
            SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: categoryMap.entries
                  .map((e) => DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 10,
              maxLength: 1000,
              decoration: InputDecoration(
                labelText: '본문',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 17),
            SizedBox(
              width: double.infinity, // 버튼 너비 최대로
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, // 버튼 배경색
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder( // 버튼 모양 둥글게
                      borderRadius: BorderRadius.circular(8.0),
                    )
                ),
                child: const Text(
                  '상품 요청하기',
                  style: TextStyle(color: Colors.white), // 버튼 텍스트 색상
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
