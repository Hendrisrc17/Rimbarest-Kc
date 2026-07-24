import 'package:flutter/material.dart';

import '../data/map_node_data.dart';

class MapNodePin extends StatelessWidget {
  final MapNodeData node;
  final bool selected;
  final AnimationController pingCtrl;

  const MapNodePin({
    super.key,
    required this.node,
    required this.selected,
    required this.pingCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = node.color;

    return AnimatedBuilder(
      animation: pingCtrl,
      builder: (_, child) {
        return SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (node.isOnline)
                Container(
                  width: 30 + 20 * pingCtrl.value,
                  height: 30 + 20 * pingCtrl.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(
                        alpha: (1 - pingCtrl.value) * 0.4,
                      ),
                    ),
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: selected ? 34 : 26,
        height: selected ? 34 : 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(
            color: color,
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: selected ? 0.3 : 0.15),
              blurRadius: selected ? 10 : 4,
            ),
          ],
        ),
        child: Icon(
          node.icon,
          color: color,
          size: selected ? 17 : 13,
        ),
      ),
    );
  }
}
