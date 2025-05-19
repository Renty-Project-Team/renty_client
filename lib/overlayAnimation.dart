import 'package:flutter/material.dart';

class FloatingUploadController {
  static OverlayEntry? _overlay;

  static void show(BuildContext context) {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 투명 배경 (전체 클릭 감지용)
          Positioned.fill(
            child: GestureDetector(
              onTap: hide,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 버튼 영역 + 주변 어두운 배경
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 80), // 위치 조정
              alignment: Alignment.bottomCenter,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08), // 버튼 주변만 살짝 어둡게
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _AnimatedSlideUpButtons(
                    onRequestTap: () {
                      hide();
                      Navigator.pushNamed(context, '/request_upload');
                    },
                    onPostTap: () {
                      hide();
                      Navigator.pushNamed(context, '/product_upload');
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    _overlay?.remove();
    _overlay = null;
  }
}

class _AnimatedSlideUpButtons extends StatefulWidget {
  final VoidCallback onRequestTap;
  final VoidCallback onPostTap;

  const _AnimatedSlideUpButtons({
    required this.onRequestTap,
    required this.onPostTap,
  });

  @override
  State<_AnimatedSlideUpButtons> createState() => _AnimatedSlideUpButtonsState();
}

class _AnimatedSlideUpButtonsState extends State<_AnimatedSlideUpButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onRequestTap,
              icon: const Icon(Icons.add_comment),
              label: const Text('대여 요청'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 50),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: widget.onPostTap,
              icon: const Icon(Icons.post_add),
              label: const Text('대여글 올리기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 50),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
