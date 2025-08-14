// lib/presentation/widgets/flag_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

/// Sebuah CustomPainter untuk menggambar bendera Merah Putih yang berkibar.
class FlagPainter extends CustomPainter {
  final double animationValue;

  FlagPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Pengaturan untuk efek gelombang
    final waveAmplitude = size.height * 0.05; // Amplitudo gelombang
    final waveFrequency = 2.5 * pi / size.width; // Frekuensi gelombang
    final wavePhase = animationValue * 2 * pi; // Fase pergerakan gelombang

    // Path untuk bagian merah (atas)
    final redPath = Path();
    redPath.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final y =
          (size.height / 2) +
          sin(x * waveFrequency + wavePhase) * waveAmplitude;
      redPath.lineTo(x, y);
    }
    redPath.lineTo(size.width, 0);
    redPath.lineTo(0, 0);
    redPath.close();

    // Path untuk bagian putih (bawah)
    final whitePath = Path();
    whitePath.moveTo(0, size.height / 2);
    for (double x = 0; x <= size.width; x++) {
      final y =
          (size.height / 2) +
          sin(x * waveFrequency + wavePhase) * waveAmplitude;
      whitePath.lineTo(x, y);
    }
    whitePath.lineTo(size.width, size.height);
    whitePath.lineTo(0, size.height);
    whitePath.close();

    // Cat untuk warna
    final redPaint = Paint()..color = const Color(0xFFFF0000);
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);

    // Gambar kedua path
    canvas.drawPath(redPath, redPaint);
    canvas.drawPath(whitePath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant FlagPainter oldDelegate) {
    // Repaint jika nilai animasi berubah
    return oldDelegate.animationValue != animationValue;
  }
}
