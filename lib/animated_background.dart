import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  AppBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003311), // أخضر داكن جداً
            Color(0xFF004d1a), // أخضر ملكي
          ],
        ),
      ),
      child: Stack(
        children: [
          // إضافة صورة الشعار g.jpeg بشفافية خفيفة في الخلفية
          Opacity(
            opacity: 0.05,
            child: Center(child: Image.asset('assets/images/g.jpeg')),
          ),
          child,
        ],
      ),
    );
  }
}