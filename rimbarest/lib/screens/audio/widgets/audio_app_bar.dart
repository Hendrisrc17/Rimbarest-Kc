import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class AudioAppBar extends StatelessWidget {
  const AudioAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.bgPage,
      surfaceTintColor: Colors.transparent,
      title: const Text('Monitor Audio'),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.tune,
            color: AppTheme.textMuted,
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}
