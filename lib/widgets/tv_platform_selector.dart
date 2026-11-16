import 'package:flutter/material.dart';

import '../services/tv_output_service.dart';

class TvPlatformSelector extends StatelessWidget {
  const TvPlatformSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final TvOutputKind selected;
  final ValueChanged<TvOutputKind>? onSelected;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF4DE2D0);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final kind in TvOutputKind.values)
          ChoiceChip(
            label: Text(switch (kind) {
              TvOutputKind.android => 'Android TV',
              TvOutputKind.lg => 'LG webOS • Beta',
              TvOutputKind.samsung => 'Samsung Tizen • Beta',
            }),
            selected: selected == kind,
            showCheckmark: true,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            selectedColor: accent,
            checkmarkColor: const Color(0xFF090D18),
            labelStyle: selected == kind
                ? const TextStyle(
                    color: Color(0xFF090D18),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  )
                : const TextStyle(fontSize: 12),
            onSelected: onSelected == null
                ? null
                : (value) {
                    if (value) onSelected!(kind);
                  },
          ),
      ],
    );
  }
}
