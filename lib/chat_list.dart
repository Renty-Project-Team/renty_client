import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_theme.dart';
import 'bottom_menu_bar.dart';
import 'logo_app_ber.dart';
import 'dart:math' as math;
import 'chat_room.dart'; // ChatRoom 모델 임포트
import 'chat.dart'; // ChatScreen이 있는 파일 임포트

// 앱의 임시 진입점
void main() {
  runApp(const ChatList());
}

class ChatList extends StatelessWidget {
  const ChatList({Key? key}) : super(key: key);

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

// 읽음/안읽음 상태를 처리하기 위한 ChatRoom 확장
extension ChatRoomExtension on ChatRoom {
  // 마지막 메시지 시간이 24시간 이내인지 확인하여 읽지 않은 것으로 간주
  bool get isUnread {
    return DateTime.now().difference(lastAt).inHours < 24;
  }

  // 읽음 상태를 변경하는 메소드는 ChatRoom이 불변(final) 객체이므로 새 객체를 반환
  ChatRoom markAsRead() {
    // 채팅방을 읽음 처리 로직은 실제로는 서버와 동기화가 필요
    // 여기서는 구현을 위해 시간을 48시간 전으로 설정하여 읽음 상태로 표시
    return ChatRoom(
      chatRoomId: chatRoomId,
      roomName: roomName,
      profileImageUrl: profileImageUrl,
      message: message,
      messageType: messageType,
      lastAt: DateTime.now().subtract(const Duration(hours: 48)),
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
  int _currentIndex = 3; // 채팅 탭을 기본으로 선택 (인덱스 3)

  // API URL 상수
  final String apiUrl = 'http://localhost:8080/api/chat/RoomList';

  // 채팅 데이터 상태
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 앱 시작시 채팅방 목록 불러오기
    _fetchChatRooms();
  }

  // API에서 채팅방 목록 가져오기
  Future<void> _fetchChatRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> roomsData = data['rooms'];

        setState(() {
          _chatRooms =
              roomsData.map((room) => ChatRoom.fromJson(room)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '서버 오류가 발생했습니다 (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

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

            // Chat List with Loading/Error states
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchChatRooms,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      )
                      : _filteredChatRooms.isEmpty
                      ? const Center(child: Text('채팅방이 없습니다.'))
                      : RefreshIndicator(
                        onRefresh: _fetchChatRooms,
                        child: ListView.builder(
                          itemCount: _filteredChatRooms.length,
                          itemBuilder: (context, index) {
                            final chatRoom = _filteredChatRooms[index];
                            return _buildChatRoomItem(chatRoom);
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
      // 하단 메뉴바 추가
      bottomNavigationBar: BottomMenuBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // 여기서 탭 전환 로직 구현
        },
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
        // 기존 ChatRoom 객체가 불변이므로, 새 객체 리스트를 생성하여 상태 업데이트
        setState(() {
          final index = _chatRooms.indexWhere(
            (room) => room.chatRoomId == chatRoom.chatRoomId,
          );
          if (index != -1) {
            final updatedRoom = chatRoom.markAsRead();
            _chatRooms =
                List.from(_chatRooms)
                  ..removeAt(index)
                  ..insert(index, updatedRoom);
          }
        });

        // 채팅 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  chatRoomId: chatRoom.chatRoomId,
                  roomName: chatRoom.roomName,
                  profileImageUrl: chatRoom.profileImageUrl,
                  // 상품 정보가 필요한 경우 Product 객체 생성
                  // 예시: ChatRoom 모델에 상품 정보가 포함되어 있다고 가정하면:
                  // product: chatRoom.productInfo != null ? Product(
                  //   title: chatRoom.productInfo!.title,
                  //   price: chatRoom.productInfo!.price.toString(),
                  //   priceUnit: chatRoom.productInfo!.priceUnit,
                  //   deposit: chatRoom.productInfo!.deposit.toString(),
                  // ) : null,
                ),
          ),
        );
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
                  backgroundImage:
                      chatRoom.profileImageUrl != null
                          ? NetworkImage(chatRoom.profileImageUrl!)
                          : null,
                  child:
                      chatRoom.profileImageUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
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
                        chatRoom.roomName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chatRoom.lastAt),
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Last message
                  Text(
                    chatRoom.message ?? '새로운 채팅방이 생성되었습니다.',
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
                    SnackBar(content: Text('${chatRoom.roomName}의 알림이 꺼졌습니다.')),
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

  Future<bool?> showDeleteChatDialog(BuildContext context, String chatName) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 상단 타이틀 (굵게 표시된 텍스트)
                const Text(
                  '대화방 삭제',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),

                // 대화방 삭제 확인 메시지
                Text(
                  '정말 ${chatName}님과의 대화방을 삭제하시겠습니까?',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),

                // 하단 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 취소 버튼
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),

                    // 삭제제하기 버튼 (파란색 버튼)
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B70FD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0, // 기본 그림자 제거
                        shadowColor: Colors.transparent, // 그림자 색상 투명하게
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        '삭제하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(ChatRoom chatRoom) {
    showDeleteChatDialog(context, chatRoom.roomName).then((confirmed) {
      if (confirmed == true) {
        _deleteChatRoom(chatRoom); // 채팅방 삭제 실행
      }
    });
  }

  void _deleteChatRoom(ChatRoom chatRoom) {
    setState(() {
      _chatRooms.removeWhere((room) => room.chatRoomId == chatRoom.chatRoomId);
    });

    // 삭제 완료 메시지 표시
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chatRoom.roomName}님과의 대화방이 삭제되었습니다.')),
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
