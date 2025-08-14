// lib/presentation/widgets/animated_book.dart

import 'package:flutter/material.dart';
import 'book_painter.dart';

class AnimatedBook extends StatefulWidget {
  const AnimatedBook({super.key});

  @override
  State<AnimatedBook> createState() => _AnimatedBookState();
}

class _AnimatedBookState extends State<AnimatedBook>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Membuat animasi 'EaseInOut' untuk pergerakan yang lebih natural
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Loop animasi (maju-mundur)
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100), // Ukuran canvas
      painter: BookPainter(animation: _animation),
    );
  }
}
