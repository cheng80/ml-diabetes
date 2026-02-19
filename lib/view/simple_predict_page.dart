import 'package:diabetes_app/widgets/age_picker.dart';
import 'package:diabetes_app/widgets/height_weight_picker.dart';
import 'package:diabetes_app/widgets/percentile_range_radio.dart';
import 'package:flutter/material.dart';

// 라디오로 혈당·임신횟수 선택하는 심플 예측
class SimplePredictPage extends StatefulWidget {
  const SimplePredictPage({super.key});

  @override
  State<SimplePredictPage> createState() => _SimplePredictPageState();
}

class _SimplePredictPageState extends State<SimplePredictPage> {
  double _bmi = 0;
  int _age = 30;
  int? _sugarIndex;
  int? _pregIndex;

  bool get _ok => _bmi > 0 && _pregIndex != null;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const Text('나이'),
                  AgePicker(
                    initialAge: _age,
                    onChanged: (age) => setState(() => _age = age),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const Text('키·몸무게 (BMI 산출)'),
                  HeightWeightPicker(
                    onChanged: (height, weight, bmi) {
                      setState(() => _bmi = bmi);
                    },
                  ),
                ],
              ),
              PercentileRangeRadio(
                label: '임신횟수 (회)',
                ranges: PercentileRangeRadio.pregnancyRanges,
                selectedIndex: _pregIndex,
                onChanged: (index) => setState(() => _pregIndex = index),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  PercentileRangeRadio(
                    label: '혈당 (mg/dL)',
                    ranges: PercentileRangeRadio.bloodGlucoseRanges,
                    selectedIndex: _sugarIndex,
                    onChanged: (index) => setState(() => _sugarIndex = index),
                  ),
                  Text(
                    '혈당 미선택 시에도 예측 가능하나, 정확도가 낮아질 수 있습니다.',
                    style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
              FilledButton(
                onPressed: _ok ? () {} : null,
                child: const Text('예측하기'),
              ),
            ],
          ),
        ),
    );
  }
}
