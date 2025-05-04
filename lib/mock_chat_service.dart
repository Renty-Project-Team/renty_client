import 'dart:math';
import 'chat_service.dart';

// 실제 API가 없을 때 사용할 모의 채팅 서비스
class MockChatService implements ChatService {
  @override
  String baseUrl = 'http://localhost:8080/api';
  
  @override
  String? authToken = 'test_token';
  
  // 채팅방 생성 요청을 모의로 처리
  @override
  Future<ChatRoomResponse> createChatRoom(int itemId) async {
    // 네트워크 지연 시뮬레이션
    await Future.delayed(const Duration(seconds: 1));
    
    // 랜덤하게 다양한 응답 시나리오 생성
    final random = Random();
    final scenario = random.nextInt(10);
    
    if (scenario < 7) {
      // 70% 확률로 성공 (채팅방 생성)
      return ChatRoomResponse(
        message: '채팅방이 생성되었습니다.',
        status: 'created',
        isSuccess: true,
        chatRoomId: 1000 + random.nextInt(9000), // 랜덤 채팅방 ID
      );
    } else if (scenario < 9) {
      // 20% 확률로 이미 존재하는 채팅방
      return ChatRoomResponse(
        message: '채팅방이 이미 존재합니다.',
        status: 'exists',
        isSuccess: true,
        chatRoomId: 1000 + random.nextInt(9000), // 랜덤 채팅방 ID
      );
    } else if (itemId == 9999) {
      // 특정 상품 ID로 테스트할 때 본인 상품 오류 발생
      return ChatRoomResponse(
        message: '자기 자신과 채팅방을 생성할 수 없습니다.',
        status: 'error',
        isSuccess: false,
      );
    } else {
      // 10% 확률로 기타 오류
      final errorMessages = [
        '존재하지 않는 상품입니다.',
        '게시글 작성자를 찾을 수 없습니다.',
        '서버 오류가 발생했습니다.'
      ];
      
      return ChatRoomResponse(
        message: errorMessages[random.nextInt(errorMessages.length)],
        status: 'error',
        isSuccess: false,
      );
    }
  }
}