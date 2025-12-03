import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../generated/icons.dart';

class IconsPage extends StatelessWidget {
  const IconsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Icons',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildIconTile(context, 'ic16KeyEmergency', AppIcons.ic16KeyEmergency),
            _buildIconTile(context, 'ic16KeySandglass', AppIcons.ic16KeySandglass),
            _buildIconTile(context, 'ic16Notification', AppIcons.ic16Notification),
            _buildIconTile(context, 'ic24ArrowBack', AppIcons.ic24ArrowBack),
            _buildIconTile(context, 'ic24ArrowRight', AppIcons.ic24ArrowRight),
            _buildIconTile(context, 'ic24Close', AppIcons.ic24Close),
            _buildIconTile(context, 'ic24Dots', AppIcons.ic24Dots),
            _buildIconTile(context, 'ic24DropdownDown', AppIcons.ic24DropdownDown),
            _buildIconTile(context, 'ic24DropdownUp', AppIcons.ic24DropdownUp),
            _buildIconTile(context, 'ic24FullscreenDisable', AppIcons.ic24FullscreenDisable),
            _buildIconTile(context, 'ic24FullscreenEnable', AppIcons.ic24FullscreenEnable),
            _buildIconTile(context, 'ic24Profile', AppIcons.ic24Profile),
            _buildIconTile(context, 'ic24ShareAndroid', AppIcons.ic24ShareAndroid),
          ],
        ),
      ],
    );
  }

  Widget _buildIconTile(BuildContext context, String name, String assetPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            assetPath,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }
}
