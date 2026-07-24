// File: lib/screens/audio/widgets/node_tabs.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class NodeTabs extends StatelessWidget {
  final int selectedIndex;
  final List<String> nodeNames;
  final ValueChanged<int> onChanged;

  const NodeTabs({
    super.key,
    required this.selectedIndex,
    required this.nodeNames,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nodeNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  // 🌟 SOLUSI: Menggunakan borderMedium atau warna transparan abu-abu agar lolos dari error undefined getter
                  color: isSelected ? AppTheme.primary : AppTheme.borderMedium,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                nodeNames[index],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
