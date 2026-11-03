import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Reveals a circular delete action when swiped to the left.
///
/// A swipe alone never deletes the notification; deletion requires a
/// separate tap on the revealed icon. Swiping right closes the action.
class NotificationSwipeDelete extends StatefulWidget {
  const NotificationSwipeDelete({
    required this.child,
    required this.onDelete,
    super.key,
    this.isDeleting = false,
  });

  final Widget child;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  State<NotificationSwipeDelete> createState() =>
      _NotificationSwipeDeleteState();
}

class _NotificationSwipeDeleteState extends State<NotificationSwipeDelete> {
  static const double _revealWidth = 72;
  double _offset = 0;
  bool _dragging = false;

  void _startDrag(DragStartDetails details) {
    if (widget.isDeleting) return;
    setState(() => _dragging = true);
  }

  void _updateDrag(DragUpdateDetails details) {
    if (widget.isDeleting) return;
    setState(() {
      _offset = (_offset + details.delta.dx)
          .clamp(-_revealWidth, 0.0)
          .toDouble();
    });
  }

  void _endDrag(DragEndDetails details) {
    if (widget.isDeleting) return;
    setState(() {
      _dragging = false;
      _offset = _offset <= -_revealWidth * 0.4 ? -_revealWidth : 0;
    });
  }

  void _cancelDrag() {
    if (widget.isDeleting) return;
    setState(() {
      _dragging = false;
      _offset = _offset <= -_revealWidth * 0.4 ? -_revealWidth : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IgnorePointer(
                  ignoring: _offset == 0 || widget.isDeleting,
                  child: Semantics(
                    button: true,
                    label: 'Delete notification',
                    child: Material(
                      color: AppColors.destructive,
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: const ValueKey('notification-delete-button'),
                        customBorder: const CircleBorder(),
                        onTap: widget.isDeleting ? null : widget.onDelete,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: widget.isDeleting
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: _dragging
                ? Duration.zero
                : const Duration(milliseconds: 170),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _startDrag,
              onHorizontalDragUpdate: _updateDrag,
              onHorizontalDragEnd: _endDrag,
              onHorizontalDragCancel: _cancelDrag,
              child: ColoredBox(
                color: AppColors.background,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
