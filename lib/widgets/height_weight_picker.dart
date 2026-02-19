import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 키 80~220cm, 몸무게 40~300kg → BMI 산출
class HeightWeightPicker extends StatefulWidget {
  const HeightWeightPicker({
    super.key,
    this.initialHeight = 170,
    this.initialWeight = 70,
    this.onChanged,
  });

  final int initialHeight;
  final int initialWeight;
  final void Function(int height, int weight, double bmi)? onChanged;

  @override
  State<HeightWeightPicker> createState() => _HeightWeightPickerState();
}

class _HeightWeightPickerState extends State<HeightWeightPicker> {
  static const int _heightMin = 80;
  static const int _heightMax = 220;
  static const int _weightMin = 40;
  static const int _weightMax = 300;

  static const int _heightStepCount = 141;
  static const int _weightStepCount = 261;

  late int _height;
  late int _weight;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight.clamp(_heightMin, _heightMax);
    _weight = widget.initialWeight.clamp(_weightMin, _weightMax);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void didUpdateWidget(HeightWeightPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHeight != widget.initialHeight ||
        oldWidget.initialWeight != widget.initialWeight) {
      setState(() {
        _height = widget.initialHeight.clamp(_heightMin, _heightMax);
        _weight = widget.initialWeight.clamp(_weightMin, _weightMax);
      });
    }
  }

  double get bmi =>
      _weight / ((_height / 100) * (_height / 100));

  void _notifyChanged() {
    widget.onChanged?.call(_height, _weight, bmi);
  }

  Future<void> _showHeightPicker() async {
    int selected = _height;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      setState(() {
                        _height = selected;
                        _notifyChanged();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: _height - _heightMin,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (i) =>
                      setModalState(() => selected = _heightMin + i),
                  children: List.generate(
                    _heightStepCount,
                    (i) => Center(
                      child: Text('${_heightMin + i} cm'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWeightPicker() async {
    int selected = _weight;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 250,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  CupertinoButton(
                    onPressed: () {
                      setState(() {
                        _weight = selected;
                        _notifyChanged();
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: _weight - _weightMin,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (i) =>
                      setModalState(() => selected = _weightMin + i),
                  children: List.generate(
                    _weightStepCount,
                    (i) => Center(
                      child: Text('${_weightMin + i} kg'),
                    ),
                  ),
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
    final maxHeight = MediaQuery.of(context).size.height / 3;
    final isNarrow = MediaQuery.of(context).size.width < 320;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: isNarrow
          ? Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _PickerTile(
                        label: '키',
                        value: '$_height cm',
                        onTap: _showHeightPicker,
                        compact: true,
                      ),
                    ),
                    Expanded(
                      child: _PickerTile(
                        label: '몸무게',
                        value: '$_weight kg',
                        onTap: _showWeightPicker,
                        compact: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: _BmiTile(bmi: bmi, compact: true),
                ),
              ],
            )
          : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Expanded(
                  flex: 2,
                  child: _PickerTile(
                    label: '키',
                    value: '$_height cm',
                    onTap: _showHeightPicker,
                    compact: false,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _PickerTile(
                    label: '몸무게',
                    value: '$_weight kg',
                    onTap: _showWeightPicker,
                    compact: false,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _BmiTile(bmi: bmi, compact: false),
                ),
              ],
            ),
          ),
    );
  }
}

class _BmiTile extends StatelessWidget {
  const _BmiTile({required this.bmi, this.compact = false});

  final double bmi;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 6 : 12,
        horizontal: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'BMI',
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            bmi.toStringAsFixed(1),
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 12,
            horizontal: compact ? 6 : 12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              SizedBox(height: compact ? 2 : 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    size: compact ? 18 : 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
