// lib/presentation/widgets/matrix_rain.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/presentation/providers/rain_speed_provider.dart';

// Karakter fallback jika tidak ada judul konten yang tersedia.
const String _fallbackCharacters = 'PerpusKu';

/// Widget utama yang menjadi host animasi hujan matriks.
/// Diubah menjadi ConsumerStatefulWidget untuk mengakses provider kecepatan.
class MatrixRain extends ConsumerStatefulWidget {
  final List<String> words;

  const MatrixRain({super.key, required this.words});

  @override
  ConsumerState<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends ConsumerState<MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Awasi (watch) provider kecepatan untuk mendapatkan nilai terbaru.
    final speedMultiplier = ref.watch(rainSpeedProvider);

    return CustomPaint(
      painter: _MatrixRainPainter(
        animation: _controller,
        words: widget.words,
        speedMultiplier: speedMultiplier, // Kirim kecepatan ke painter
      ),
      child: Container(),
    );
  }
}

/// CustomPainter untuk menggambar animasi hujan matriks.
class _MatrixRainPainter extends CustomPainter {
  final Animation<double> animation;
  final List<String> words;
  final double speedMultiplier; // Terima pengali kecepatan
  final Random _random = Random();
  final List<_RainDrop> _drops = [];

  _MatrixRainPainter({
    required this.animation,
    required this.words,
    required this.speedMultiplier, // Wajibkan parameter kecepatan
  }) : super(repaint: animation) {
    if (_drops.isEmpty) {
      final hasWords = words.isNotEmpty;
      final int numberOfDrops = (hasWords ? words.length : 15).clamp(10, 25);

      for (int i = 0; i < numberOfDrops; i++) {
        _drops.add(
          _RainDrop(
            x: _random.nextDouble(),
            y: _random.nextDouble(),
            // Kecepatan dasar akan dikalikan dengan speedMultiplier
            baseSpeed: _random.nextDouble() * 0.003 + 0.002,
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
      // Gunakan pengali kecepatan untuk mengatur kecepatan jatuh
      drop.y = (drop.y + (drop.baseSpeed * speedMultiplier)) % 1.2;

      if (drop.y < (drop.baseSpeed * speedMultiplier)) {
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

      if (charX + textPainter.width > size.width) {
        drop.x = (size.width - textPainter.width) / size.width;
      }

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
  final double baseSpeed; // Kecepatan dasar sebelum dikalikan

  _RainDrop({
    required this.x,
    required this.y,
    required this.text,
    required this.baseSpeed,
  });
}
