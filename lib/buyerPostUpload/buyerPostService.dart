import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:renty_client/core/api_client.dart';

class PostUploadService {
  static Future<int> uploadPost({
    required String title,
    required String description,
    required String category,
    required List<XFile> images,
  }) async {
    final formData = FormData();

    formData.fields
      ..add(MapEntry('Title', title))
      ..add(MapEntry('Description', description))
      ..add(MapEntry('Category', category));

    for (final image in images) {
      final file = File(image.path);
      final ext = file.path.split('.').last.toLowerCase();
      if (['jpeg', 'jpg', 'png', 'webp', 'gif'].contains(ext)) {
        formData.files.add(MapEntry(
          'Images',
          await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }
    }

    final dio = ApiClient().client;
    final response = await dio.post('/Post/upload', data: formData);

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = response.data;
      return response.data['postId'];
    }else{
      throw Exception('업로드 실패: ${response.statusCode}');
    }
  }
}