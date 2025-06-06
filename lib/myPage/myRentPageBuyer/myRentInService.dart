import 'package:flutter/material.dart';
import 'package:renty_client/core/api_client.dart';
import 'package:renty_client/mypage/myRentPage/myRantOutData.dart';
import 'package:dio/dio.dart';

class RentInService {
  static Future<List<RentOutItem>> fetchRentOutItems() async {
    try {
      await ApiClient().initialize();
      final response = await ApiClient().client.get('/Transaction/buyer');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => RentOutItem.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching rent-out items: $e");
      return [];
    }
  }
  static Future<Map<String, dynamic>?> createOrGetChatRoom(int itemId) async {
    try {
      final response = await ApiClient().client.post(
        '/chat/Create',
        data: {'itemId': itemId},
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } on DioException catch (e) {
      print('❌ 채팅방 생성 오류: ${e.message}');
    }
    return null;
  }
}