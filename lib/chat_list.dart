import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '빌려봄 채팅 목록',
      theme: buildAppTheme(),
      home: const ChatListScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _selectedFilter = '전체';

  // Sample chat data
  final List<ChatRoom> _chatRooms = [
    ChatRoom(
      id: '1',
      name: '홍길동',
      lastMessage: '안녕하세요! 거래 관련해서 문의드립니다.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      isUnread: true,
      profileImage: 'assets/profile1.png',
    ),
    ChatRoom(
      id: '2',
      name: '김철수',
      lastMessage: '견적서 확인 부탁드립니다. 내일까지 검토해주시면 감사하겠습니다.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      isUnread: false,
      profileImage: 'assets/profile2.png',
    ),
    ChatRoom(
      id: '3',
      name: '이영희',
      lastMessage: '주문한 제품 배송 현황을 알 수 있을까요?',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      isUnread: true,
      profileImage: 'assets/profile3.png',
    ),
  ];

  List<ChatRoom> get _filteredChatRooms {
    if (_selectedFilter == '읽음') {
      return _chatRooms.where((room) => !room.isUnread).toList();
    } else if (_selectedFilter == '안 읽음') {
      return _chatRooms.where((room) => room.isUnread).toList();
    } else {
      return _chatRooms;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Logo App Bar
            LogoAppBar(),

            // Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterButton('전체'),
                  const SizedBox(width: 8),
                  _buildFilterButton('읽음'),
                  const SizedBox(width: 8),
                  _buildFilterButton('안 읽음'),
                ],
              ),
            ),

            // Chat List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredChatRooms.length,
                itemBuilder: (context, index) {
                  final chatRoom = _filteredChatRooms[index];
                  return _buildChatRoomItem(chatRoom);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = _selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.black87,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom chatRoom) {
    return CenterRippleEffect(
      onTap: () {
        // 터치할 때 약간의 진동 피드백 추가
        HapticFeedback.lightImpact();

        setState(() {
          // Mark as read when tapped
          chatRoom.isUnread = false;
        });

        // In a real app, you'd navigate to the chat detail screen here
        print('Navigate to chat with ${chatRoom.name}');
      },
      onLongPress: () {
        _showChatRoomOptions(chatRoom);
      },
      // 채팅방 콘텐츠
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image with unread indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                // Red dot unread indicator
                if (chatRoom.isUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Chat details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and time
                  Row(
                    children: [
                      Text(
                        chatRoom.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chatRoom.lastMessageTime),
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message
                  Text(
                    chatRoom.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight:
                          chatRoom.isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatRoomOptions(ChatRoom chatRoom) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text('알림 끄기'),
                onTap: () {
                  // 알림 끄기 기능 구현
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${chatRoom.name}의 알림이 꺼졌습니다.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  '대화방 삭제',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  // 모달 닫기
                  Navigator.pop(context);
                  // 삭제 확인 대화상자 표시
                  _showDeleteConfirmationDialog(chatRoom);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(ChatRoom chatRoom) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('대화방 삭제'),
          content: Text('정말 ${chatRoom.name}님과의 대화방을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 대화상자 닫기
                _deleteChatRoom(chatRoom); // 채팅방 삭제 실행
              },
              child: const Text('확인', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _deleteChatRoom(ChatRoom chatRoom) {
    setState(() {
      _chatRooms.removeWhere((room) => room.id == chatRoom.id);
    });

    // 삭제 완료 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chatRoom.name}님과의 대화방이 삭제되었습니다.')),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}일 전';
    } else {
      return '${time.month}월 ${time.day}일';
    }
  }
}

// 가운데에서 퍼지는 원형 효과 위젯
class CenterRippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const CenterRippleEffect({
    Key? key,
    required this.child,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<CenterRippleEffect> createState() => _CenterRippleEffectState();
}

class _CenterRippleEffectState extends State<CenterRippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 정확히 0.3초로 설정
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isAnimating = true;
        });
        _controller.forward(from: 0.0);
      },
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.white,
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 채팅방 내용
                  widget.child,

                  // 중앙에서 퍼지는 원형 효과
                  if (_isAnimating)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CircleRipplePainter(
                          progress: _controller.value,
                          color: Colors.grey.withOpacity(
                            0.3 * (1 - _controller.value),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 원형 퍼짐 효과를 그리는 CustomPainter
class CircleRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // 중앙에서 퍼져나가는 원 그리기
    final center = Offset(size.width / 2, size.height / 2);

    // 최대 반지름 계산 (채팅방의 대각선 길이의 절반)
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

    // 현재 애니메이션 진행도에 따른 반지름
    final currentRadius = maxRadius * progress;

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleRipplePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// Chat room model
class ChatRoom {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  bool isUnread;
  final String profileImage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isUnread,
    required this.profileImage,
  });
}
