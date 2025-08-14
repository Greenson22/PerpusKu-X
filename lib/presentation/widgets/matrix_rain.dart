// lib/presentation/widgets/matrix_rain.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// --- PERUBAHAN DI SINI: IMPORT PROVIDER BARU ---
import 'package:my_perpusku/presentation/providers/animation_config_provider.dart';
// --- AKHIR PERUBAHAN ---

const String _fallbackCharacters = 'PerpusKu';

class MatrixRain extends ConsumerStatefulWidget {
  final List<String> words;

  const MatrixRain({super.key, required this.words});

  @override
  ConsumerState<MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends ConsumerState<MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // Simpan Painter untuk menghindari pembuatan ulang yang tidak perlu.
  _MatrixRainPainter? _painter;

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
    // Awasi (watch) provider konfigurasi untuk mendapatkan nilai terbaru.
    final config = ref.watch(animationConfigProvider);

    // Buat atau perbarui painter hanya jika diperlukan.
    _painter ??= _MatrixRainPainter(
      animation: _controller,
      words: widget.words,
      config: config,
    );
    _painter!.updateConfig(
      config,
      widget.words,
    ); // Selalu update config terbaru

    return CustomPaint(painter: _painter, child: Container());
  }
}

class _MatrixRainPainter extends CustomPainter {
  final Animation<double> animation;
  List<String> words;
  AnimationConfig config;
  final Random _random = Random();
  final List<_RainDrop> _drops = [];

  _MatrixRainPainter({
    required this.animation,
    required this.words,
    required this.config,
  }) : super(repaint: animation);

  /// Memperbarui konfigurasi tanpa harus membuat ulang seluruh objek painter.
  void updateConfig(AnimationConfig newConfig, List<String> newWords) {
    config = newConfig;
    words = newWords;

    // Jika jumlah tetesan yang diinginkan berubah, atur ulang daftar tetesan.
    if (_drops.length != config.count) {
      _drops.clear();
      _initializeDrops();
    }
  }

  void _initializeDrops() {
    final hasWords = words.isNotEmpty;
    for (int i = 0; i < config.count; i++) {
      _drops.add(
        _RainDrop(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          baseSpeed: _random.nextDouble() * 0.003 + 0.002,
          text: hasWords
              ? words[_random.nextInt(words.length)]
              : _fallbackCharacters,
        ),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_drops.isEmpty) _initializeDrops();

    final rainColor = Colors.green.withOpacity(0.6);

    for (final drop in _drops) {
      drop.y = (drop.y + (drop.baseSpeed * config.speed)) % 1.2;

      if (drop.y < (drop.baseSpeed * config.speed)) {
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
            fontSize: config.size, // Gunakan ukuran dari config
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final charX = drop.x * size.width;
      if (charX + textPainter.width > size.width) {
        drop.x = (size.width - textPainter.width) / size.width;
      }

      textPainter.paint(
        canvas,
        Offset(drop.x * size.width, drop.y * size.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MatrixRainPainter oldDelegate) {
    // Repaint jika config atau kata-katanya berubah.
    return oldDelegate.config != config || oldDelegate.words != words;
  }
}

class _RainDrop {
  double x;
  double y;
  String text;
  final double baseSpeed;

  _RainDrop({
    required this.x,
    required this.y,
    required this.text,
    required this.baseSpeed,
  });
}
