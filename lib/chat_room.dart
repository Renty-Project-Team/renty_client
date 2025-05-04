class ChatRoom {
  final int chatRoomId;
  final String roomName;
  final String? profileImageUrl;
  final String? message;
  final String? messageType;
  final DateTime lastAt;

  ChatRoom({
    required this.chatRoomId,
    required this.roomName,
    this.profileImageUrl,
    this.message,
    this.messageType,
    required this.lastAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      chatRoomId: json['chatRoomId'],
      roomName: json['roomName'],
      profileImageUrl: json['profileImageUrl'],
      message: json['message'],
      messageType: json['messageType'],
      lastAt: DateTime.parse(json['lastAt']),
    );
  }
}