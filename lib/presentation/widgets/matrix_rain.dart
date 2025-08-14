// lib/presentation/widgets/matrix_rain.dart

import 'dart:math';
import 'package:flutter/material.dart';

// Karakter yang akan digunakan dalam animasi hujan
const String _matrixCharacters =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

/// Widget utama yang akan menjadi host dari animasi hujan matriks.
class MatrixRain extends StatefulWidget {
  const MatrixRain({super.key});

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
      duration: const Duration(seconds: 5), // Durasi loop animasi
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
      // Menggunakan AnimatedBuilder secara implisit melalui repaint pada CustomPainter
      painter: _MatrixRainPainter(animation: _controller),
      child: Container(), // Container kosong sebagai child
    );
  }
}

/// CustomPainter untuk menggambar animasi hujan matriks.
class _MatrixRainPainter extends CustomPainter {
  final Animation<double> animation;
  final Random _random = Random();
  final List<_RainDrop> _drops = [];
  final int _numberOfDrops;

  _MatrixRainPainter({required this.animation})
    : _numberOfDrops = 30, // Jumlah kolom hujan, bisa disesuaikan
      super(repaint: animation) {
    // Inisialisasi awal dari tetesan hujan
    if (_drops.isEmpty) {
      for (int i = 0; i < _numberOfDrops; i++) {
        _drops.add(
          _RainDrop(
            // Inisialisasi posisi dan kecepatan secara acak
            x: _random.nextDouble(),
            y: _random.nextDouble(),
            speed: _random.nextDouble() * 0.005 + 0.002, // Kecepatan jatuh
            length: _random.nextInt(15) + 5, // Panjang setiap jejak hujan
            characters: List.generate(
              20,
              (index) =>
                  _matrixCharacters[_random.nextInt(_matrixCharacters.length)],
            ),
          ),
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rainColor = Colors.green.withOpacity(0.7);

    for (final drop in _drops) {
      // Perbarui posisi Y dari setiap tetesan berdasarkan kecepatan dan waktu animasi
      drop.y =
          (drop.y +
              drop.speed +
              (animation.value * 0.0001)) // Sedikit percepatan dari animasi
          %
          1.1; // Loop kembali ke atas setelah melewati batas bawah

      // Gambar setiap karakter dalam jejak hujan
      for (int i = 0; i < drop.length; i++) {
        final charIndex = (i + (drop.y * 100).floor()) % drop.characters.length;
        final char = drop.characters[charIndex];

        // Semakin ke bawah, semakin pudar warnanya
        final opacity = 1.0 - (i / drop.length);
        final color = rainColor.withOpacity(rainColor.opacity * opacity);

        final textPainter = TextPainter(
          text: TextSpan(
            text: char,
            style: TextStyle(color: color, fontSize: 14),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        // Hitung posisi untuk menggambar karakter
        final charX = drop.x * size.width;
        final charY = (drop.y * size.height) - (i * textPainter.height);

        // Hanya gambar jika berada dalam area pandang canvas
        if (charY < size.height && charY > -textPainter.height) {
          textPainter.paint(canvas, Offset(charX, charY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) {
    // Selalu repaint karena animasi berjalan terus-menerus
    return true;
  }
}

/// Model data untuk merepresentasikan satu "tetesan" atau jejak hujan.
class _RainDrop {
  double x; // Posisi horizontal (0.0 - 1.0)
  double y; // Posisi vertikal (0.0 - 1.0)
  final double speed; // Kecepatan jatuh
  final int length; // Panjang jejak (jumlah karakter)
  final List<String> characters; // Karakter dalam jejak

  _RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.characters,
  });
}
