import 'dart:convert';

import 'package:diabetes_app/utils/app_storage.dart';
import 'package:diabetes_app/utils/custom_common_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kpostal/kpostal.dart';

/// 주소 찾기 화면
///
/// - 주소 검색 버튼: 눌러서 검색 화면으로 이동 → 주소 선택 시 아래 필드에 표시
/// - 우편번호, 기본주소: 검색 결과 (읽기 전용)
/// - 상세주소: 사용자 직접 입력 (동/호수 등)
/// - 좌표 변환 버튼: 입력한 주소를 FastAPI로 전송 → lat, lng 표시
/// - 저장하기: 기본주소·좌표를 GetStorage에 저장 (상세주소 선택)
class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final _formKey = GlobalKey<FormState>();
  final _postcodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDetailController = TextEditingController();

  String? _lat;
  String? _lng;
  bool _geocodeLoading = false;

  /// kpostal 검색 결과 좌표 (있으면 /geocode 호출 생략 → Nominatim 503 회피)
  double? _lastSearchLat;
  double? _lastSearchLng;

  bool get _canSave => _buildBaseAddress().isNotEmpty;

  @override
  void dispose() {
    _postcodeController.dispose();
    _addressController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    try {
      final Kpostal? result = await Navigator.push<Kpostal>(
        context,
        MaterialPageRoute(
          builder: (context) => KpostalView(),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _postcodeController.text = result.postCode;
          _addressController.text = result.userSelectedAddress;
          _addressDetailController.text = result.buildingName;
        });
        // kpostal 좌표 로드 (비동기 latLng getter)
        await result.latLng;
        if (mounted) {
          setState(() {
            _lastSearchLat = result.latitude;
            _lastSearchLng = result.longitude;
          });
        }
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final isChannelError = e.code == 'channel-error' ||
          (e.message?.contains('Unable to establish connection') ?? false);
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        title: '주소 검색 오류',
        message: isChannelError
            ? 'WebView를 사용할 수 없습니다. 실제 기기에서 시도해 주세요.'
            : (e.message ?? '주소 검색 중 오류가 발생했습니다.'),
      );
    } catch (e) {
      if (!mounted) return;
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        title: '주소 검색 오류',
        message: '주소 검색 중 오류가 발생했습니다.',
      );
    }
  }

  /// 전체 주소 (기본주소 + 상세주소) — 저장용
  String _buildFullAddress() {
    final parts = <String>[
      _addressController.text.trim(),
      _addressDetailController.text.trim(),
    ];
    return parts.where((s) => s.isNotEmpty).join(' ');
  }

  /// 기본주소만 — geocoding API용 (상세주소 제외)
  String _buildBaseAddress() => _addressController.text.trim();

  Future<void> _fetchCoordinates() async {
    final address = _buildBaseAddress();
    if (address.isEmpty) {
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        title: '입력 오류',
        message: '기본주소를 입력해 주세요.',
      );
      return;
    }

    // kpostal 좌표가 있으면 서버 호출 생략 (Nominatim 503 회피)
    if (_lastSearchLat != null && _lastSearchLng != null) {
      if (!mounted) return;
      setState(() {
        _lat = _lastSearchLat!.toString();
        _lng = _lastSearchLng!.toString();
      });
      return;
    }

    setState(() {
      _geocodeLoading = true;
      _lat = null;
      _lng = null;
    });

    try {
      final baseUrl = CustomCommonUtil.getApiBaseUrlSync();
      final response = await http.post(
        Uri.parse('$baseUrl/geocode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': address}),
      );

      if (!mounted) return;

      if (response.statusCode == 404) {
        CustomCommonUtil.showErrorSnackbar(
          context: context,
          title: '좌표 변환 실패',
          message: '주소를 찾을 수 없습니다.',
        );
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('서버 오류(${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _lat = data['lat'] as String?;
        _lng = data['lng'] as String?;
      });
    } catch (e) {
      if (!mounted) return;
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        title: '좌표 변환 오류',
        message: '서버 연결을 확인해 주세요. $e',
      );
    } finally {
      if (mounted) {
        setState(() => _geocodeLoading = false);
      }
    }
  }

  Future<void> _saveAddress() async {
    final baseAddress = _buildBaseAddress();
    if (baseAddress.isEmpty) return;

    final fullAddress = _buildFullAddress();

    CustomCommonUtil.showLoadingOverlay(context, message: '저장 중...');

    try {
      String? lat;
      String? lng;

      // kpostal 좌표가 있으면 서버 호출 생략 (Nominatim 503 회피)
      if (_lastSearchLat != null && _lastSearchLng != null) {
        lat = _lastSearchLat!.toString();
        lng = _lastSearchLng!.toString();
      } else {
        final baseUrl = CustomCommonUtil.getApiBaseUrlSync();
        final response = await http.post(
          Uri.parse('$baseUrl/geocode'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'address': baseAddress}),
        );

        if (!mounted) return;
        CustomCommonUtil.hideLoadingOverlay(context);

        if (response.statusCode == 404) {
          CustomCommonUtil.showErrorSnackbar(
            context: context,
            title: '저장 실패',
            message: '주소를 찾을 수 없습니다.',
          );
          return;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('서버 오류(${response.statusCode})');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        lat = data['lat'] as String?;
        lng = data['lng'] as String?;
      }

      if (!mounted) return;
      CustomCommonUtil.hideLoadingOverlay(context);

      if (lat == null || lng == null) {
        CustomCommonUtil.showErrorSnackbar(
          context: context,
          title: '저장 실패',
          message: '좌표를 받아오지 못했습니다.',
        );
        return;
      }

      await AppStorage.saveAddress(fullAddress.isNotEmpty ? fullAddress : baseAddress);
      await AppStorage.saveCoordinates(lat, lng);

      if (!mounted) return;
      CustomCommonUtil.showSuccessSnackbar(
        context: context,
        title: '저장 완료',
        message: '정상적으로 저장 되었습니다.',
      );
      setState(() {
        _lat = lat;
        _lng = lng;
      });
    } catch (e) {
      if (!mounted) return;
      CustomCommonUtil.hideLoadingOverlay(context);
      CustomCommonUtil.showErrorSnackbar(
        context: context,
        title: '저장 실패',
        message: '저장에 실패 했습니다.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 찾기'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _searchAddress,
                  icon: const Icon(Icons.search),
                  label: const Text('주소 검색'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '주소를 선택하면 아래에 표시됩니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _postcodeController,
                  decoration: const InputDecoration(
                    labelText: '우편번호',
                    hintText: '주소 검색에서 선택',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '기본주소',
                    hintText: '주소 검색에서 선택',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressDetailController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '상세주소',
                    hintText: '동/호수 등 상세주소 입력 (선택)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: _geocodeLoading ? null : _fetchCoordinates,
                  icon: _geocodeLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : const Icon(Icons.location_on),
                  label: Text(_geocodeLoading ? '변환 중...' : '좌표 변환'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _canSave ? _saveAddress : null,
                  icon: const Icon(Icons.save),
                  label: const Text('저장하기'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (_lat != null && _lng != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '위경도',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SelectableText('lat: $_lat'),
                          SelectableText('lng: $_lng'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
