// lib/presentation/widgets/dashboard/animation_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/presentation/providers/animation_config_provider.dart';
import 'topic_filter_list.dart';

/// Dialog utama untuk semua pengaturan animasi.
class AnimationSettingsDialog extends ConsumerStatefulWidget {
  const AnimationSettingsDialog({super.key});

  @override
  ConsumerState<AnimationSettingsDialog> createState() =>
      _AnimationSettingsDialogState();
}

class _AnimationSettingsDialogState
    extends ConsumerState<AnimationSettingsDialog> {
  late AnimationConfig _tempConfig;

  @override
  void initState() {
    super.initState();
    _tempConfig = ref.read(animationConfigProvider);
  }

  void _saveChanges() {
    ref.read(animationConfigProvider.notifier).updateConfig(_tempConfig);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pengaturan Animasi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SettingsSlider(
              label: 'Kecepatan',
              value: _tempConfig.speed,
              min: 0.2,
              max: 2.0,
              divisions: 18,
              onChanged: (value) => setState(
                () => _tempConfig = _tempConfig.copyWith(speed: value),
              ),
            ),
            const Divider(),
            _SettingsSlider(
              label: 'Jumlah',
              value: _tempConfig.count.toDouble(),
              min: 5,
              max: 40,
              divisions: 35,
              isInteger: true,
              onChanged: (value) => setState(
                () => _tempConfig = _tempConfig.copyWith(count: value.toInt()),
              ),
            ),
            const Divider(),
            _SettingsSlider(
              label: 'Ukuran Font',
              value: _tempConfig.size,
              min: 10,
              max: 24,
              divisions: 14,
              isInteger: true,
              onChanged: (value) => setState(
                () => _tempConfig = _tempConfig.copyWith(size: value),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'Tampilkan Judul Dari',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const TopicFilterList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Simpan & Tutup'),
          onPressed: () {
            _saveChanges();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

/// Widget slider yang dapat digunakan kembali untuk berbagai pengaturan.
class _SettingsSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool isInteger;
  final ValueChanged<double> onChanged;

  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${isInteger ? value.toInt() : value.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: isInteger
              ? value.toInt().toString()
              : value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
