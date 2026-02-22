import 'dart:convert';

import 'package:diabetes_app/models/predict_input_profile.dart';
import 'package:diabetes_app/utils/app_storage.dart';
import 'package:diabetes_app/utils/custom_common_util.dart';
import 'package:diabetes_app/view/address_search_page.dart';
import 'package:diabetes_app/view/hospital_search_page.dart';
import 'package:diabetes_app/widgets/age_picker.dart';
import 'package:diabetes_app/widgets/height_weight_picker.dart';
import 'package:diabetes_app/widgets/percentile_range_radio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 라디오로 혈당·임신횟수 선택하는 심플 예측
class SimplePredictPage extends StatefulWidget {
  const SimplePredictPage({super.key});

  @override
  State<SimplePredictPage> createState() => _SimplePredictPageState();
}

class _SimplePredictPageState extends State<SimplePredictPage> {
  double _bmi = 0;
  int _age = 30;
  int _heightCm = 170;
  int _weightKg = 70;
  int? _sugarIndex;
  int? _pregIndex;
  VoidCallback? _unlistenProfile;

  @override
  void initState() {
    super.initState();
    _applyProfile(PredictInputProfile.load());
    _unlistenProfile = AppStorage.rawStorage.listenKey(
      PredictInputProfile.storageKey,
      (_) {
        if (!mounted) return;
        setState(() => _applyProfile(PredictInputProfile.load()));
      },
    );
  }

  @override
  void dispose() {
    _unlistenProfile?.call();
    super.dispose();
  }

  bool get _ok => _bmi > 0 && _pregIndex != null;

  void _applyProfile(PredictInputProfile profile) {
    _age = profile.age;
    _heightCm = profile.heightCm;
    _weightKg = profile.weightKg;
    _bmi = profile.bmi;
  }

  Future<void> _saveProfile() {
    return PredictInputProfile(
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
    ).save();
  }

  Future<void> _onPredict() async {
    CustomCommonUtil.showLoadingOverlay(context, message: '당뇨 위험도를 분석 중입니다...');

    try {
      final url = '${CustomCommonUtil.getApiBaseUrlSync()}/predict';

      final pregRange = PercentileRangeRadio.pregnancyRanges[_pregIndex!];
      final sugarRange = _sugarIndex != null
          ? PercentileRangeRadio.bloodGlucoseRanges[_sugarIndex!]
          : null;

      final body = {
        '나이': _age,
        'BMI': _bmi,
        '임신횟수': (pregRange.$1 + pregRange.$2) / 2.0,
        if (sugarRange != null) '혈당': (sugarRange.$1 + sugarRange.$2) / 2.0,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;
      CustomCommonUtil.hideLoadingOverlay(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _showResultDialog(data);
      } else {
        CustomCommonUtil.showErrorSnackbar(
          context: context,
          message: '예측 실패: 상태 코드 ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomCommonUtil.hideLoadingOverlay(context);
      CustomCommonUtil.logError(functionName: '_onPredict (Simple)', error: e);
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        message: '서버 연결에 실패했습니다. 네트워크 상태를 확인해주세요.',
      );
    }
  }

  void _showResultDialog(Map<String, dynamic> data) {
    final label = data['label'] as String;
    final probability = (data['probability'] as double) * 100;
    final chartBase64 = data['chart_image_base64'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '분석 결과',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: data['prediction'] == 1
                                ? Colors.red.shade600
                                : Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '당뇨 가능성: ${probability.toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        if (chartBase64 != null) ...[
                          const SizedBox(height: 24),
                          Image.memory(
                            base64Decode(chartBase64),
                            fit: BoxFit.contain,
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Text(
                          '이 결과는 통계적 수치에 의한 예측일 뿐이므로\n정확한 결과는 가까운 병원을 방문하시어\n검진하시길 바랍니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              final latStr = AppStorage.getLat();
                              final lngStr = AppStorage.getLng();

                              if (latStr != null && lngStr != null) {
                                final lat = double.tryParse(latStr) ?? 0.0;
                                final lng = double.tryParse(lngStr) ?? 0.0;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        HospitalSearchPage(lat: lat, lng: lng),
                                  ),
                                );
                              } else {
                                CustomCommonUtil.showErrorSnackbar(
                                  context: context,
                                  message: '저장된 주소가 없습니다. 주소를 먼저 설정해주세요.',
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddressSearchPage(),
                                  ),
                                );
                              }
                            },
                            child: const Text('병원 찾기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                  onChanged: (age) {
                    setState(() => _age = age);
                    _saveProfile();
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                const Text('키·몸무게 (BMI 산출)'),
                HeightWeightPicker(
                  initialHeight: _heightCm,
                  initialWeight: _weightKg,
                  onChanged: (height, weight, bmi) {
                    setState(() {
                      _heightCm = height;
                      _weightKg = weight;
                      _bmi = bmi;
                    });
                    _saveProfile();
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
                  style:
                      (Theme.of(context).textTheme.bodySmall ??
                              const TextStyle())
                          .copyWith(color: Colors.red.shade400),
                ),
              ],
            ),
            FilledButton(
              onPressed: _ok ? _onPredict : null,
              child: const Text('예측하기'),
            ),
          ],
        ),
      ),
    );
  }
}
