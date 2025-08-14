// lib/presentation/widgets/matrix_rain.dart

import 'dart:math';
import 'package:flutter/material.dart';

// Karakter fallback jika tidak ada judul konten yang tersedia.
const String _fallbackCharacters = 'PerpusKu';

/// Widget utama yang menjadi host animasi hujan matriks.
class MatrixRain extends StatefulWidget {
  final List<String> words;

  const MatrixRain({super.key, required this.words});

  @override
  State<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Durasi loop diperlambat
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MatrixRainPainter(animation: _controller, words: widget.words),
      child: Container(),
    );
  }
}

/// CustomPainter untuk menggambar animasi hujan matriks.
class _MatrixRainPainter extends CustomPainter {
  final Animation<double> animation;
  final List<String> words;
  final Random _random = Random();
  final List<_RainDrop> _drops = [];

  _MatrixRainPainter({required this.animation, required this.words})
    : super(repaint: animation) {
    if (_drops.isEmpty) {
      final hasWords = words.isNotEmpty;
      // Kurangi jumlah tulisan agar tidak terlalu padat
      final int numberOfDrops = (hasWords ? words.length : 15).clamp(10, 25);

      for (int i = 0; i < numberOfDrops; i++) {
        _drops.add(
          _RainDrop(
            x: _random.nextDouble(),
            y: _random.nextDouble(),
            speed: _random.nextDouble() * 0.003 + 0.002,
            text: hasWords
                ? words[_random.nextInt(words.length)]
                : _fallbackCharacters,
          ),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rainColor = Colors.green.withOpacity(0.6);

    for (final drop in _drops) {
      // Perbarui posisi Y dari setiap tetesan
      drop.y = (drop.y + drop.speed) % 1.2;

      // Jika tetesan hujan baru saja reset, berikan kata baru dan posisi X acak
      if (drop.y < drop.speed) {
        if (words.isNotEmpty) {
          drop.text = words[_random.nextInt(words.length)];
        }
        drop.x = _random.nextDouble();
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: drop.text,
          style: TextStyle(
            color: rainColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final charX = drop.x * size.width;
      final charY = drop.y * size.height;

      // Cek agar teks tidak keluar dari batas kanan layar
      if (charX + textPainter.width > size.width) {
        drop.x = (size.width - textPainter.width) / size.width;
      }

      // Gambar teks secara horizontal pada posisi yang telah dihitung
      textPainter.paint(canvas, Offset(drop.x * size.width, charY));
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) => true;
}

/// Model data untuk satu "tetesan" hujan.
class _RainDrop {
  double x;
  double y;
  String text;
  final double speed;

  _RainDrop({
    required this.x,
    required this.y,
    required this.text,
    required this.speed,
  });
}
