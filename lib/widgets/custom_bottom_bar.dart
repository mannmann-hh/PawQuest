import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pawquest/services/forum_service.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final ForumService _forum = ForumService();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIcon('assets/images/icons/ic_home.png', 0),
                _buildIcon('assets/images/icons/ic_badge.png', 1),
                _buildIcon(Icons.cloud, 2),
                _buildIcon('assets/images/icons/ic_community.png', 3),
                _buildIcon('assets/images/icons/ic_user.png', 4,
                    showBadge: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Object icon, int index, {bool showBadge = false}) {
    final isSelected = index == currentIndex;

    final iconWidget = icon is IconData
        ? Icon(
            icon,
            color: isSelected ? Colors.blueAccent : Colors.grey,
            size: 42,
          )
        : Image.asset(
            icon as String,
            color: isSelected ? Colors.blueAccent : Colors.grey,
            width: 50,
            height: 50,
          );

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: showBadge ? _withNotificationDot(iconWidget) : iconWidget,
      ),
    );
  }

  /// Overlays a red dot on the icon when the user has unread notifications.
  Widget _withNotificationDot(Widget child) {
    return StreamBuilder<int>(
      stream: _forum.unreadNotificationCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
