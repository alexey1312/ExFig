import 'package:flutter/material.dart';

import '../generated/colors.dart';

class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Light Colors',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildColorTile('backgroundPrimary', AppColors.backgroundPrimary),
        _buildColorTile('backgroundSecondary', AppColors.backgroundSecondary),
        _buildColorTile('button', AppColors.button),
        _buildColorTile('buttonRipple', AppColors.buttonRipple),
        _buildColorTile('textPrimary', AppColors.textPrimary),
        _buildColorTile('textSecondary', AppColors.textSecondary),
        _buildColorTile('tint', AppColors.tint),
        const SizedBox(height: 24),
        const Text(
          'Dark Colors',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildColorTile('backgroundPrimary', AppColorsDark.backgroundPrimary),
        _buildColorTile('backgroundSecondary', AppColorsDark.backgroundSecondary),
        _buildColorTile('button', AppColorsDark.button),
        _buildColorTile('buttonRipple', AppColorsDark.buttonRipple),
        _buildColorTile('textPrimary', AppColorsDark.textPrimary),
        _buildColorTile('textSecondary', AppColorsDark.textSecondary),
        _buildColorTile('tint', AppColorsDark.tint),
      ],
    );
  }

  Widget _buildColorTile(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 16),
          Text(name),
        ],
      ),
    );
  }
}
