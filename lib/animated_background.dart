import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  AppBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF001a09), // قلب أخضر عميق
            Color(0xFF000000), // أسود مطلق للأطراف
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