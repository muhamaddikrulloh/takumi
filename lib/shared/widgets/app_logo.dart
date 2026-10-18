import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double width;
  final Color? color;

  const AppLogo({super.key, this.width = 200, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: width,
      child: ClipRect(
        // Adaptive foreground assets include padding for the launcher safe zone.
        child: Transform.scale(
          scale: 2.25,
          child: Image.asset(
            'assets/images/app_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            color: color,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
