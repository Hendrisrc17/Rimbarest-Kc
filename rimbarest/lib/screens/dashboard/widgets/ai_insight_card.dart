// File: lib/screens/dashboard/widgets/ai_insight_card.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AiInsightCard extends StatelessWidget {
  final Map<String, dynamic>? insight;

  const AiInsightCard({
    super.key,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final String insightMessage = insight?['message'] ??
        insight?['insightMessage'] ??
        insight?['text'] ??
        'Sistem mendeteksi kondisi lingkungan dalam batas aman dan normal.';

    final List<dynamic> tags = insight?['tags'] ?? [];

    final String fullTextUpper =
        "$insightMessage ${tags.join(' ')}".toUpperCase();
    final bool isAnomaly = fullTextUpper.contains('ANCAMAN') ||
        fullTextUpper.contains('KEBAKARAN') ||
        fullTextUpper.contains('KRITIS') ||
        fullTextUpper.contains('ANOMALI') ||
        fullTextUpper.contains('ASAP');

    final bool isWarning =
        fullTextUpper.contains('POLUSI') || fullTextUpper.contains('WASPADA');

    final Color cardBorder = isAnomaly
        ? AppTheme.danger
        : (isWarning ? AppTheme.warning : AppTheme.borderMedium);

    final Color glowColor = isAnomaly
        ? AppTheme.danger.withAlpha(40)
        : (isWarning
            ? AppTheme.warning.withAlpha(30)
            : AppTheme.primary.withAlpha(15));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnomaly ? AppTheme.danger.withAlpha(15) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder, width: isAnomaly ? 1.8 : 1.0),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: isAnomaly ? 20 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AiHeader(isAnomaly: isAnomaly, isWarning: isWarning),
          const SizedBox(height: 10),
          Text(
            insightMessage,
            style: TextStyle(
              color: isAnomaly ? AppTheme.danger : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: isAnomaly ? FontWeight.w600 : FontWeight.normal,
              height: 1.5,
            ),
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: tags.map((t) {
                final tagStr = t.toString().toUpperCase();

                if (tagStr.contains('KEBAKARAN') ||
                    tagStr.contains('KRITIS') ||
                    tagStr.contains('ANCAMAN') ||
                    tagStr.contains('ANOMALI') ||
                    tagStr.contains('ASAP') ||
                    tagStr.contains('DANGER')) {
                  return _Chip(
                    label: '⚠️ $t',
                    color: AppTheme.danger,
                    bg: AppTheme.bgDanger,
                    border: AppTheme.bdrDanger,
                  );
                } else if (tagStr.contains('POLUSI') ||
                    tagStr.contains('WASPADA')) {
                  return _Chip(
                    label: '⚡ $t',
                    color: AppTheme.warning,
                    bg: AppTheme.bgWarning,
                    border: AppTheme.bdrWarning,
                  );
                }

                return _Chip(
                  label: '💡 $t',
                  color: AppTheme.success,
                  bg: AppTheme.bgSuccess,
                  border: AppTheme.bdrSuccess,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiHeader extends StatelessWidget {
  final bool isAnomaly;
  final bool isWarning;

  const _AiHeader({
    required this.isAnomaly,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerColor = isAnomaly
        ? AppTheme.danger
        : (isWarning ? AppTheme.warning : AppTheme.primary);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: headerColor.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isAnomaly ? Icons.warning_amber_rounded : Icons.auto_awesome,
            color: headerColor,
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        Text(
          isAnomaly ? '🚨 ANOMALI TERDETEKSI' : 'AI Edge Insight System',
          style: TextStyle(
            color: headerColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: headerColor.withAlpha(25),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isAnomaly ? 'ALERT LIVE' : 'DS-CNN Local',
            style: TextStyle(
              fontSize: 8,
              color: headerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final Color border;

  const _Chip({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
