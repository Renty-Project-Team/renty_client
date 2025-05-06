import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'login/login.dart'; // 로그인 페이지 import 추가
import 'package:flutter/widgets.dart'; // BuildContext 접근을 위한 import

// 채팅방 생성 응답을 처리하는 모델 클래스
class ChatRoomResponse {
  final String message;
  final String status;
  final bool isSuccess;
  final int? chatRoomId;
  final bool needsLogin; // 로그인 필요 여부 필드 추가

  ChatRoomResponse({
    required this.message,
    required this.status,
    required this.isSuccess,
    this.chatRoomId,
    this.needsLogin = false, // 기본값은 false
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) {
    return ChatRoomResponse(
      message: json['message'] as String? ?? '응답 메시지가 없습니다.',
      status: json['status'] as String? ?? '',
      isSuccess: json['status'] == 'created' || json['status'] == 'exists',
      chatRoomId: json['chatRoomId'] as int?, // 채팅방 ID (있을 경우)
    );
  }
}

// 채팅 관련 API 호출을 담당하는 서비스 클래스
class ChatService {
  // ApiClient 인스턴스
  final ApiClient _apiClient = ApiClient();

  // BuildContext 저장 변수 (UI 접근용)
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // 채팅방 생성 API 호출 함수
  Future<ChatRoomResponse> createChatRoom(
    int itemId, [
    BuildContext? context,
  ]) async {
    try {
      // ApiClient를 통한 요청
      final response = await _apiClient.client.post(
        '/chat/Create',
        data: {
          'itemId': itemId, // 상품 ID만 필요
        },
      );

      // 성공 응답 (상태 코드 200)
      if (response.statusCode == 200) {
        return ChatRoomResponse.fromJson(response.data);
      } else {
        // 기타 상태 코드의 응답 처리
        return ChatRoomResponse(
          message: response.data['message'] ?? '채팅방을 생성할 수 없습니다.',
          status: 'error',
          isSuccess: false,
        );
      }
    } on DioException catch (e) {
      // Dio 관련 오류 처리
      String errorMessage = '채팅방 생성 오류 발생';
      bool needsLogin = false;

      // 401 오류 특별 처리 추가
      if (e.response != null && e.response!.statusCode == 401) {
        errorMessage = '로그인이 필요합니다';
        needsLogin = true;

        // context가 제공된 경우 로그인 화면으로 이동
        if (context != null) {
          // UI 스레드에서 내비게이션 실행
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const LoginPage()));
          });
        }
      } else if (e.response != null) {
        // 기타 서버 오류 응답
        errorMessage =
            e.response?.data['message'] ?? '서버 오류 (${e.response?.statusCode})';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 타임아웃 발생';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '네트워크 연결 오류 발생';
      } else {
        // 기타 Dio 오류
        errorMessage = '네트워크 요청 중 오류 발생: ${e.message}';
      }

      return ChatRoomResponse(
        message: errorMessage,
        status: 'error',
        isSuccess: false,
        needsLogin: needsLogin, // 로그인 필요 여부 설정
      );
    } catch (e) {
      // 기타 오류 처리
      return ChatRoomResponse(
        message: '알 수 없는 오류 발생: $e',
        status: 'error',
        isSuccess: false,
      );
    }
  }
}
