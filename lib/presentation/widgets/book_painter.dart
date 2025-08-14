// lib/presentation/widgets/book_painter.dart

import 'dart:math';
import 'package:flutter/material.dart';

class BookPainter extends CustomPainter {
  final Animation<double> animation;

  BookPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final Paint coverPaint = Paint()..color = Colors.deepPurple.shade400;
    final Paint pagePaint = Paint()..color = Colors.white;
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0;

    // Gambar sampul belakang
    final RRect backCover = RRect.fromLTRBR(
      width * 0.1,
      height * 0.1,
      width * 0.9,
      height * 0.9,
      const Radius.circular(4),
    );
    canvas.drawRRect(backCover, coverPaint);

    // Animasi halaman
    // Nilai animasi dari 0.0 (tertutup) ke 1.0 (terbuka penuh)
    final double pageAngle = (1.0 - animation.value) * (pi * 0.85);

    canvas.save();
    // Pindahkan pivot ke tulang buku (sebelah kiri)
    canvas.translate(width * 0.15, height * 0.5);
    // Putar canvas sesuai animasi
    canvas.rotate(-pageAngle);
    // Pindahkan kembali pivot
    canvas.translate(-width * 0.15, -height * 0.5);

    // Gambar halaman putih yang bergerak
    final RRect turningPage = RRect.fromLTRBR(
      width * 0.15,
      height * 0.15,
      width * 0.85,
      height * 0.85,
      const Radius.circular(2),
    );
    canvas.drawRRect(turningPage, pagePaint);

    // Gambar garis-garis teks pada halaman
    for (int i = 1; i <= 5; i++) {
      final y = height * (0.2 + i * 0.12);
      canvas.drawLine(
        Offset(width * 0.25, y),
        Offset(width * 0.75, y),
        linePaint,
      );
    }

    canvas.restore(); // Kembalikan state canvas (rotasi dan translasi)

    // Gambar tulang buku
    final Rect spine = Rect.fromLTWH(
      width * 0.08,
      height * 0.1,
      width * 0.1,
      height * 0.8,
    );
    canvas.drawRect(spine, Paint()..color = Colors.deepPurple.shade600);
  }

  @override
  bool shouldRepaint(covariant BookPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value;
  }
}
