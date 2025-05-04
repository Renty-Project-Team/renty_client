import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 채팅방 생성 응답을 처리하는 모델 클래스
class ChatRoomResponse {
  final String message;
  final String status;
  final bool isSuccess;
  final int? chatRoomId;

  ChatRoomResponse({
    required this.message,
    required this.status,
    required this.isSuccess,
    this.chatRoomId,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) {
    return ChatRoomResponse(
      message: json['message'] as String,
      status: json['status'] as String? ?? '',
      isSuccess: json['status'] == 'created' || json['status'] == 'exists',
      chatRoomId: json['chatRoomId'] as int?, // 채팅방 ID (있을 경우)
    );
  }
}

// 채팅 관련 API 호출을 담당하는 서비스 클래스
class ChatService {
  // API 서버 URL - 실제로는 환경 설정에서 가져오는 것이 좋습니다
  final String baseUrl = 'http://localhost:8080/api';
  
  // 인증 토큰 (실제로는 상태 관리 라이브러리나 보안 저장소에서 가져와야 함)
  String? authToken = 'test_token';
  
  // 채팅방 생성 API 호출 함수
  Future<ChatRoomResponse> createChatRoom(int itemId) async {
    try {
      final url = Uri.parse('$baseUrl/chat/Create');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // 인증 토큰
        },
        body: jsonEncode({
          'itemId': itemId, // 상품 ID만 필요
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // 성공 응답 (채팅방 생성 성공 또는 이미 존재하는 경우)
        return ChatRoomResponse.fromJson(responseData);
      } else {
        // 실패 응답 (400 Bad Request 등)
        return ChatRoomResponse(
          message: responseData['message'] ?? '채팅방을 생성할 수 없습니다.',
          status: 'error',
          isSuccess: false,
        );
      }
    } catch (e) {
      // 네트워크 오류 등 예외 발생
      return ChatRoomResponse(
        message: '서버 연결 오류: $e',
        status: 'error',
        isSuccess: false,
      );
    }
  }
}