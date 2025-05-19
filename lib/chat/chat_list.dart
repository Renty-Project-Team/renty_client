import 'package:flutter/material.dart';
import 'package:renty_client/main.dart';
import '../core/token_manager.dart';
import '../bottom_menu_bar.dart';
import '../logo_app_ber.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'chat.dart';
import '../core/api_client.dart';
import 'package:dio/dio.dart';
import '../login/login.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String _selectedFilter = '전체';
  int _currentIndex = 3;

  final ApiClient _apiClient = ApiClient();

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadChatRooms();
  }

  Future<void> _checkLoginAndLoadChatRooms() async {
    try {
      await _apiClient.initialize();

      final token = await TokenManager.getToken();
      final isLoggedIn = token != null && token.isNotEmpty;

      if (!isLoggedIn) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = '로그인이 필요합니다';
          });

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
        return;
      }

      _fetchChatRooms();
    } catch (e) {
      setState(() {
        _errorMessage = 'API 클라이언트 초기화 오류: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchChatRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await _apiClient.client.get('/chat/RoomList');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> roomsData = data['rooms'];

        List<Map<String, dynamic>> rooms =
            roomsData.map<Map<String, dynamic>>((room) {
              return {
                'chatRoomId': room['chatRoomId'], // 타입 변환 없이 그대로 사용
                'roomName': room['roomName'] ?? '이름 없음', // null 처리
                'profileImageUrl': room['profileImageUrl'], // null 허용
                'message': room['message'], // null 허용
                'messageType': room['messageType'], // null 허용
                'lastAt':
                    room['lastAt'] != null
                        ? DateTime.parse(room['lastAt'])
                        : DateTime.now(),
                'unreadCount': room['unreadCount'] ?? 0,
              };
            }).toList();

        rooms.sort(
          (a, b) =>
              (b['lastAt'] as DateTime).compareTo(a['lastAt'] as DateTime),
        );

        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '서버 오류가 발생했습니다 (${response.statusCode})';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print('채팅 목록 로드 중 오류: ${e.message}, 상태 코드: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _errorMessage = '로그인이 필요합니다';
        });

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else if (e.response?.statusCode == 503) {
        setState(() {
          _errorMessage = '서버가 현재 점검 중입니다. 잠시 후 다시 시도해주세요.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '데이터를 불러오는 중 오류가 발생했습니다: ${e.message}';
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

  List<Map<String, dynamic>> get _filteredChatRooms {
    if (_selectedFilter == '읽음') {
      return _chatRooms
          .where((room) => (room['unreadCount'] ?? 0) == 0)
          .toList();
    } else if (_selectedFilter == '안 읽음') {
      return _chatRooms
          .where((room) => (room['unreadCount'] ?? 0) > 0)
          .toList();
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
            LogoAppBar(),
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
      bottomNavigationBar: BottomMenuBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          if (index == _currentIndex) return; // 이미 선택된 탭이면 아무것도 하지 않음
          await navigateBarAction(context, index);
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

  Widget _buildChatRoomItem(Map<String, dynamic> chatRoom) {
    final int unreadCount = chatRoom['unreadCount'] ?? 0;

    return CenterRippleEffect(
      onTap: () async {
        _navigateToChatScreen(chatRoom);
      },
      onLongPress: () {
        _showChatRoomOptions(chatRoom);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child:
                        chatRoom['profileImageUrl'] != null
                            ? Image.network(
                              '${_apiClient.getDomain}${chatRoom['profileImageUrl']}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('채팅 프로필 이미지 로드 오류: $error');
                                return Icon(Icons.person, color: Colors.white);
                              },
                            )
                            : Icon(Icons.person, color: Colors.white),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape:
                            unreadCount < 10
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                        borderRadius:
                            unreadCount < 10 ? null : BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chatRoom['roomName'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(chatRoom['lastAt']),
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildLastMessage(
                    chatRoom['message'] ?? '새로운 채팅방이 생성되었습니다.',
                    chatRoom['roomName'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMessage(String lastMessage, String senderName) {
    // JSON 메시지인지 확인
    if (lastMessage.startsWith('{') && lastMessage.endsWith('}')) {
      try {
        final jsonData = json.decode(lastMessage);

        // 상품 정보 업데이트 메시지인 경우
        if (jsonData['Type'] == 'Request' && jsonData['Data'] != null) {
          // 메시지 발신자에 따라 다른 텍스트 표시
          final sender = jsonData['Sender'];
          if (sender == senderName) {
            return const Text(
              '상품을 수정했습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            );
          } else {
            return const Text(
              '판매자가 상품을 수정했습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }
        }
      } catch (e) {
        // JSON 파싱 실패 시 원본 메시지 표시
      }
    }

    // 일반 메시지는 그대로 표시
    return Text(
      lastMessage,
      style: TextStyle(color: Colors.grey, fontSize: 14),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  void _navigateToChatScreen(Map<String, dynamic> chatRoom) {
    try {
      final chatRoomId = chatRoom['chatRoomId'];
      final roomName = chatRoom['roomName'] ?? '이름 없음';
      // 프로필 이미지 URL에 도메인 추가
      final profileImageUrl =
          chatRoom['profileImageUrl'] != null
              ? '${_apiClient.getDomain}${chatRoom['profileImageUrl']}'
              : null;

      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (context) => ChatScreen(
                    chatRoomId: chatRoomId,
                    roomName: roomName,
                    profileImageUrl: profileImageUrl,
                    product: null,
                    isBuyer: chatRoom['isBuyer'] ?? true,
                  ),
            ),
          )
          .then((_) async {
            if (mounted) {
              // 채팅방 목록 갱신
              _fetchChatRooms();
            }
          });
    } catch (e) {
      print('채팅방 이동 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방 접속 중 오류가 발생했습니다')));
    }
  }

  void _showChatRoomOptions(Map<String, dynamic> chatRoom) {
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
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${chatRoom['roomName']}의 알림이 꺼졌습니다.'),
                    ),
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
                  Navigator.pop(context);
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
                Text(
                  '정말 ${chatName}님과의 대화방을 삭제하시겠습니까?',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        '취소',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B70FD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> chatRoom) {
    showDeleteChatDialog(context, chatRoom['roomName']).then((confirmed) {
      if (confirmed == true) {
        _deleteChatRoom(chatRoom);
      }
    });
  }

  Future<void> _deleteChatRoom(Map<String, dynamic> chatRoom) async {
    try {
      final chatRoomId = chatRoom['chatRoomId'];

      // API 호출하여 채팅방 나가기
      final response = await _apiClient.client.post(
        '/chat/Leave',
        data: {'roomId': chatRoomId},
      );

      if (response.statusCode == 200) {
        // 성공적으로 API 호출이 완료되면 UI에서도 해당 채팅방 제거
        setState(() {
          _chatRooms.removeWhere((room) => room['chatRoomId'] == chatRoomId);
          // No need to assign to _filteredChatRooms as it's a getter that will automatically update
        });

        // 사용자에게 알림
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${chatRoom['roomName']}님과의 대화방이 삭제되었습니다.')),
          );
        }
      } else {
        // API 호출은 성공했지만 예상치 못한 응답 코드
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('채팅방 삭제 중 오류가 발생했습니다 (${response.statusCode})'),
            ),
          );
        }
      }
    } on DioException catch (e) {
      print('채팅방 삭제 중 오류: ${e.message}, 상태 코드: ${e.response?.statusCode}');

      // 인증 오류인 경우 로그인 화면으로 이동
      if (e.response?.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } else {
        // 기타 오류
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('채팅방 삭제 중 오류가 발생했습니다: ${e.message}')),
          );
        }
      }
    } catch (e) {
      print('채팅방 삭제 중 예상치 못한 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('채팅방 삭제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final hour = time.hour > 12 ? time.hour - 12 : time.hour;
      final amPm = time.hour >= 12 ? '오후' : '오전';
      final minute = time.minute.toString().padLeft(2, '0');
      return '$amPm ${hour == 0 ? 12 : hour}:$minute';
    } else if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day - 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (time.year == now.year) {
      return '${time.month}월 ${time.day}일';
    } else {
      return '${time.year}.${time.month}.${time.day}';
    }
  }
}

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
      duration: const Duration(milliseconds: 300),
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
                  widget.child,
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

class CircleRipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleRipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;

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
