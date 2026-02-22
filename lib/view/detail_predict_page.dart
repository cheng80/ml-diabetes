import 'dart:convert';

import 'package:diabetes_app/models/predict_input_profile.dart';
import 'package:diabetes_app/utils/app_storage.dart';
import 'package:diabetes_app/utils/custom_common_util.dart';
import 'package:diabetes_app/view/address_search_page.dart';
import 'package:diabetes_app/view/hospital_search_page.dart';
import 'package:diabetes_app/widgets/age_picker.dart';
import 'package:diabetes_app/widgets/height_weight_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// 텍스트박스로 직접 입력하는 상세 예측 (임신 0~14, 혈당 44~199)
class DetailPredictPage extends StatefulWidget {
  const DetailPredictPage({super.key});

  @override
  State<DetailPredictPage> createState() => _DetailPredictPageState();
}

class _DetailPredictPageState extends State<DetailPredictPage> {
  double _bmi = 0;
  int _age = 30;
  int _heightCm = 170;
  int _weightKg = 70;

  static const int _pregMin = 0;
  static const int _pregMax = 14;
  static const int _sugarMin = 44;
  static const int _sugarMax = 199;

  final _pregCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
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
    _pregCtrl.dispose();
    _sugarCtrl.dispose();
    super.dispose();
  }

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

  bool get _ok => _bmi > 0 && !_isPregOut() && !_isSugarOut();

  Future<void> _onPredict() async {
    CustomCommonUtil.showLoadingOverlay(context, message: '당뇨 위험도를 분석 중입니다...');

    try {
      final url = '${CustomCommonUtil.getApiBaseUrlSync()}/predict';

      final body = {'나이': _age, 'BMI': _bmi, '임신횟수': _pregVal};

      if (_sugarCtrl.text.trim().isNotEmpty) {
        body['혈당'] = int.parse(_sugarCtrl.text.trim());
      }

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
      CustomCommonUtil.logError(functionName: '_onPredict (Detail)', error: e);
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                const Text('임신횟수 (회)'),
                TextFormField(
                  controller: _pregCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '최소 $_sugarMin, 최대 $_sugarMax (선택)',
                    hintStyle: Theme.of(context).textTheme.bodySmall,
                    errorText:
                        _sugarCtrl.text.trim().isNotEmpty && _isSugarOut()
                        ? '범위를 벗어났습니다 ($_sugarMin~$_sugarMax)'
                        : null,
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (_) => setState(() {}),
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
