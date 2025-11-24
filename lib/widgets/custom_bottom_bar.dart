import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIcon('assets/images/icons/ic_home.png', 0),
                _buildIcon('assets/images/icons/ic_badge.png', 1),
                _buildIcon('assets/images/icons/ic_community.png', 2),
                _buildIcon('assets/images/icons/ic_user.png', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String iconPath, int index) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Image.asset(
          iconPath,
          color: isSelected ? Colors.blueAccent : Colors.grey,
          width:50,
          height: 50,
        ),
      ),
    );
  }
}
