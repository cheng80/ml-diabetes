import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// 나이 1~120, 백십일 3휠 (스크롤 최소화)
class AgePicker extends StatefulWidget {
  const AgePicker({
    super.key,
    this.initialAge = 30,
    this.onChanged,
  });

  final int initialAge;
  final void Function(int age)? onChanged;

  @override
  State<AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<AgePicker> {
  static const int _minAge = 1;
  static const int _maxAge = 120;

  late int _age;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge.clamp(_minAge, _maxAge);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChanged());
  }

  @override
  void didUpdateWidget(AgePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAge != widget.initialAge) {
      setState(() {
        _age = widget.initialAge.clamp(_minAge, _maxAge);
      });
    }
  }

  void _notifyChanged() {
    widget.onChanged?.call(_age);
  }

  int _getHundreds(int age) => (age ~/ 100).clamp(0, 1);
  int _getTens(int age) => ((age % 100) ~/ 10).clamp(0, 9);
  int _getOnes(int age) => (age % 10).clamp(0, 9);

  Future<void> _showAgePicker() async {
    int h = _getHundreds(_age);
    int t = _getTens(_age);
    int o = _getOnes(_age);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void updateValue(int nh, int nt, int no) {
            setModalState(() {
              h = nh;
              t = nt;
              o = no;
            });
          }

          final rawValue = h * 100 + t * 10 + o;
          final displayAge = rawValue.clamp(_minAge, _maxAge);

          return Container(
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
                          _age = displayAge;
                          _notifyChanged();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: h,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              updateValue(i, t, o),
                          children: const [
                            Center(child: Text('0')),
                            Center(child: Text('1')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: t,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              updateValue(h, i, o),
                          children: List.generate(
                            10,
                            (i) => Center(child: Text('$i')),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: o,
                          ),
                          itemExtent: 40,
                          onSelectedItemChanged: (i) =>
                              updateValue(h, t, i),
                          children: List.generate(
                            10,
                            (i) => Center(child: Text('$i')),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '$displayAge세',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _showAgePicker,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Text(
                  '$_age세',
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                size: 24,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
