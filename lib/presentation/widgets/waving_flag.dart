// lib/presentation/widgets/waving_flag.dart

import 'package:flutter/material.dart';
import 'flag_painter.dart';

class WavingFlag extends StatefulWidget {
  const WavingFlag({super.key});

  @override
  State<WavingFlag> createState() => _WavingFlagState();
}

class _WavingFlagState extends State<WavingFlag>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Loop animasi
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          // Gunakan nilai dari controller untuk animasi
          painter: FlagPainter(animationValue: _controller.value),
          child: Container(),
        );
      },
    );
  }
}
