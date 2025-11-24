import 'package:flutter/material.dart';

class PageImageTitle extends StatelessWidget {
  final String assetPath;
  final double height;

  const PageImageTitle({
    super.key,
    required this.assetPath,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
