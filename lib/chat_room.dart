class ChatRoom {
  final int chatRoomId;
  final String roomName;
  final String? profileImageUrl;
  final String? message;
  final String? messageType;
  final DateTime lastAt;
  final int? unreadCount; // 안 읽은 메시지 개수 추가

  ChatRoom({
    required this.chatRoomId,
    required this.roomName,
    required this.lastAt,
    this.profileImageUrl,
    this.message,
    this.messageType,
    this.unreadCount = 0, // 기본값은 0
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: json['chatRoomId'] as int,
      roomName: json['roomName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      message: json['message'] as String?,
      messageType: json['messageType'] as String?,
      lastAt: DateTime.parse(json['lastAt']),
      unreadCount: json['unreadCount'] as int? ?? 0, // 안 읽은 메시지 개수 추가
    );
  }
}
