import 'package:flutter/material.dart';

import '../generated/images.dart';

class ImagesPage extends StatelessWidget {
  const ImagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Images',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildImageCard(context, 'imgZeroEmpty', AppImages.imgZeroEmpty),
        const SizedBox(height: 16),
        _buildImageCard(context, 'imgWidgetLarge', AppImages.imgWidgetLarge),
        const SizedBox(height: 16),
        _buildImageCard(context, 'imgWidgetSmall', AppImages.imgWidgetSmall),
      ],
    );
  }

  Widget _buildImageCard(BuildContext context, String name, String assetPath) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                assetPath,
                fit: BoxFit.contain,
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Run exfig images to export',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
