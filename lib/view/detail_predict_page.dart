import 'package:diabetes_app/widgets/age_picker.dart';
import 'package:diabetes_app/widgets/height_weight_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 텍스트박스로 직접 입력하는 상세 예측 (임신 0~14, 혈당 44~199)
class DetailPredictPage extends StatefulWidget {
  const DetailPredictPage({super.key});

  @override
  State<DetailPredictPage> createState() => _DetailPredictPageState();
}

class _DetailPredictPageState extends State<DetailPredictPage> {
  double _bmi = 0;
  int _age = 30;

  static const int _pregMin = 0;
  static const int _pregMax = 14;
  static const int _sugarMin = 44;
  static const int _sugarMax = 199;

  final _pregCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();

  @override
  void dispose() {
    _pregCtrl.dispose();
    _sugarCtrl.dispose();
    super.dispose();
  }

  bool _isPregOut() {
    final text = _pregCtrl.text.trim();
    if (text.isEmpty) return false; // 공백=0
    final v = int.tryParse(text);
    return v == null || v < _pregMin || v > _pregMax;
  }

  bool _isSugarOut() {
    final text = _sugarCtrl.text.trim();
    if (text.isEmpty) return false; // 혈당 선택사항
    final v = int.tryParse(text);
    return v == null || v < _sugarMin || v > _sugarMax;
  }

  // 공백이면 0 (API 전송용)
  // ignore: unused_element
  int get _pregVal {
    final text = _pregCtrl.text.trim();
    if (text.isEmpty) return 0;
    return int.tryParse(text) ?? 0;
  }

  bool get _ok =>
      _bmi > 0 && !_isPregOut() && !_isSugarOut();

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  const Text('임신횟수 (회)'),
                  TextFormField(
                    controller: _pregCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '최소 $_pregMin, 최대 $_pregMax (미입력 시 0)',
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      errorText: _pregCtrl.text.trim().isNotEmpty && _isPregOut()
                          ? '범위를 벗어났습니다 ($_pregMin~$_pregMax)'
                          : null,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  const Text('혈당 (mg/dL)'),
                  TextFormField(
                    controller: _sugarCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: '최소 $_sugarMin, 최대 $_sugarMax (선택)',
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      errorText: _sugarCtrl.text.trim().isNotEmpty && _isSugarOut()
                          ? '범위를 벗어났습니다 ($_sugarMin~$_sugarMax)'
                          : null,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (_) => setState(() {}),
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
