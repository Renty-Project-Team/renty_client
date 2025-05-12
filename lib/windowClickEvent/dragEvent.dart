import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class MouseDraggableWrapper extends StatefulWidget {
  final Widget child;
  final PageController controller;

  const MouseDraggableWrapper({
    required this.child,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  _MouseDraggableWrapperState createState() => _MouseDraggableWrapperState();
}

class _MouseDraggableWrapperState extends State<MouseDraggableWrapper> {
  double? _dragStartX;
  final double _dragThreshold = 200;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse) {
          _dragStartX = event.position.dx;
        }
      },
      onPointerMove: (event) {
        if (_dragStartX != null) {
          final dragDelta = event.position.dx - _dragStartX!;
          if (dragDelta.abs() > _dragThreshold) {
            if (dragDelta > 0) {
              widget.controller.previousPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            } else {
              widget.controller.nextPage(
                duration: Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            }
            _dragStartX = null;
          }
        }
      },
      onPointerUp: (_) => _dragStartX = null,
      onPointerCancel: (_) => _dragStartX = null,
      child: widget.child,
    );
  }
}

