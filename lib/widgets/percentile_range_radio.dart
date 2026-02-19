import 'package:diabetes_app/constants/diabetes_predict_mapping.dart';
import 'package:flutter/material.dart';

// 분위 구간 라디오 (인덱스 0~3 반환, BloodGlucoseMapping/PregnancyMapping 참고)
class PercentileRangeRadio extends StatelessWidget {
  const PercentileRangeRadio({
    super.key,
    required this.label,
    required this.ranges,
    this.selectedIndex,
    this.onChanged,
  });

  final String label;
  final List<(int, int)> ranges;
  final int? selectedIndex;
  final void Function(int index)? onChanged;

  static List<(int, int)> get bloodGlucoseRanges =>
      BloodGlucoseMapping.ranges.toList();

  static List<(int, int)> get pregnancyRanges =>
      PregnancyMapping.ranges.toList();

  Widget _buildRadioItem(BuildContext context, int index) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onChanged != null ? () => onChanged!(index) : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Radio<int>(
                value: index,
                groupValue: selectedIndex,
                onChanged: onChanged != null
                    ? (value) => onChanged!(value!)
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Flexible(
                child: Text(
                  ranges[index].$1 == ranges[index].$2
                      ? '${ranges[index].$1}'
                      : '${ranges[index].$1}~${ranges[index].$2}',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  _buildRadioItem(context, 0),
                  _buildRadioItem(context, 1),
                ],
              ),
              TableRow(
                children: [
                  _buildRadioItem(context, 2),
                  _buildRadioItem(context, 3),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
