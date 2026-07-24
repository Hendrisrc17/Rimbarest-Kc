import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../data/audio_data.dart';

class AudioCategoryFilter extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const AudioCategoryFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: audioCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final item = audioCategories[i];
          final selectedItem = selected == item;

          return GestureDetector(
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
              decoration: BoxDecoration(
                color: selectedItem ? AppTheme.bgPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      selectedItem ? AppTheme.bdrPrimary : AppTheme.borderSoft,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: selectedItem ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
