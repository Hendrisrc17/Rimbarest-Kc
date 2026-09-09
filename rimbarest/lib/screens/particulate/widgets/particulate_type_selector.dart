import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ParticulateTypeSelector extends StatelessWidget {
  final List<String> types;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ParticulateTypeSelector({
    super.key,
    required this.types,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: types.asMap().entries.map((entry) {
        final selected = selectedIndex == entry.key;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                left: entry.key == 0 ? 0 : 4,
                right: entry.key == types.length - 1 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                gradient: selected ? LightGradients.primaryGrad : null,
                color: selected ? null : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected ? Colors.transparent : AppTheme.borderSoft,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Center(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
