import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DraggableScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController controller;
  final VoidCallback? onRefreshShortcut;

  const DraggableScrollWrapper({
    Key? key,
    required this.child,
    required this.controller,
    this.onRefreshShortcut,
  }) : super(key: key);

  @override
  State<DraggableScrollWrapper> createState() => _DraggableScrollWrapperState();
}

class _DraggableScrollWrapperState extends State<DraggableScrollWrapper> {
  final FocusNode _focusNode = FocusNode();

  bool get isDesktop => defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();

    if (isDesktop) {
      RawKeyboard.instance.addListener(_handleKey);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    if (isDesktop) {
      RawKeyboard.instance.removeListener(_handleKey);
    }
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final isCtrlPressed = event.isControlPressed;

      if (event.logicalKey == LogicalKeyboardKey.f5 ||
          (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyR)) {
        print("✅ 새로고침 단축키 감지됨 (F5 또는 Ctrl+R)");
        widget.onRefreshShortcut?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget result = widget.child;

    if (isDesktop) {
      // 마우스 드래그 스크롤 감지
      result = RawGestureDetector(
        gestures: {
          _MouseVerticalDragGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_MouseVerticalDragGestureRecognizer>(
                () => _MouseVerticalDragGestureRecognizer(),
                (_MouseVerticalDragGestureRecognizer instance) {
              instance.onUpdate = (details) {
                final newOffset = (widget.controller.offset - details.delta.dy).clamp(
                  widget.controller.position.minScrollExtent,
                  widget.controller.position.maxScrollExtent,
                );
                widget.controller.jumpTo(newOffset);
              };
            },
          ),
        },
        behavior: HitTestBehavior.opaque,
        child: result,
      );

      // 키보드 포커스
      result = Focus(
        focusNode: _focusNode,
        autofocus: true,
        child: result,
      );
    }

    return result;
  }
}

class _MouseVerticalDragGestureRecognizer extends VerticalDragGestureRecognizer {
  _MouseVerticalDragGestureRecognizer() : super();

  @override
  bool isPointerAllowed(PointerEvent event) {
    return event.kind == PointerDeviceKind.mouse && super.isPointerAllowed(event);
  }
}
