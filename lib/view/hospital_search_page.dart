import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:diabetes_app/config.dart';
import 'package:diabetes_app/models/hospital.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:map_launcher/map_launcher.dart';
import 'package:xml/xml.dart';

/// 저장된 위치(lat, lng) 기준으로 주변 병원 목록을 조회하는 화면
class HospitalSearchPage extends StatefulWidget {
  const HospitalSearchPage({super.key, required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  State<HospitalSearchPage> createState() => _HospitalSearchPageState();
}

class _HospitalSearchPageState extends State<HospitalSearchPage> {
  final ScrollController _scrollController = ScrollController();
  final List<Hospital> _hospitals = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMoreData) {
      _fetchHospitals();
    }
  }

  void _refreshHospitals() {
    setState(() {
      _hospitals.clear();
      _currentPage = 1;
      _hasMoreData = true;
    });
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final url =
        '${AppConfig.dataGoKrHospitalBaseUrl}'
        '?ServiceKey=${AppConfig.dataGoKrHospitalServiceKey}'
        '&WGS84_LON=${widget.lng}'
        '&WGS84_LAT=${widget.lat}'
        '&pageNo=$_currentPage'
        '&numOfRows=10';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 공공데이터 API: UTF-8 우선, 파싱 실패 시 EUC-KR 시도
        String body = utf8.decode(response.bodyBytes, allowMalformed: true);
        XmlDocument document;
        try {
          document = XmlDocument.parse(body);
        } catch (_) {
          try {
            body = eucKr.decode(response.bodyBytes);
            document = XmlDocument.parse(body);
          } catch (e) {
            debugPrint('병원 API XML 파싱 오류: $e');
            setState(() => _hasMoreData = false);
            return;
          }
        }
        final items = document.findAllElements('item');

        if (items.isEmpty) {
          setState(() => _hasMoreData = false);
        } else {
          final newHospitals = items.map((node) {
            return Hospital(
              name: _getText(node, 'dutyName') ?? '이름 없음',
              distance: _getText(node, 'distance') ?? '0',
              address: _getText(node, 'dutyAddr') ?? '주소 없음',
              type: _getText(node, 'dutyDivName') ?? '분류 없음',
              tel: _getText(node, 'dutyTel1') ?? '전화번호 없음',
              lat: double.tryParse(_getText(node, 'latitude') ?? ''),
              lng: double.tryParse(_getText(node, 'longitude') ?? ''),
            );
          }).toList();

          setState(() {
            _hospitals.addAll(newHospitals);
            _currentPage++;
          });
        }
      }
    } catch (e) {
      debugPrint('병원 API 호출 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? _getText(XmlElement node, String tagName) {
    final elements = node.findElements(tagName);
    final first = elements.isNotEmpty ? elements.first : null;
    return first?.innerText;
  }

  Future<void> _openDirections(Hospital hospital) async {
    if (hospital.lat == null || hospital.lng == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('해당 병원의 위치 정보가 없습니다.')));
      }
      return;
    }

    final availableMaps = await MapLauncher.installedMaps;

    if (availableMaps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('설치된 지도 앱이 없습니다.')));
      }
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  '길찾기 앱 선택',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...availableMaps.map((map) {
                return ListTile(
                  leading: SvgPicture.asset(map.icon, width: 32, height: 32),
                  title: Text(map.mapName),
                  onTap: () {
                    Navigator.pop(context);
                    map.showDirections(
                      destination: Coords(hospital.lat!, hospital.lng!),
                      destinationTitle: hospital.name,
                    );
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주변 병원 찾기'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _refreshHospitals,
            icon: const Icon(Icons.refresh),
            tooltip: '새로 불러오기',
          ),
        ],
      ),
      body: _hospitals.isEmpty && _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('데이터가 아직 없습니다'),
                ],
              ),
            )
          : _hospitals.isEmpty
          ? const Center(child: Text('주변에 검색된 병원이 없습니다.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _hospitals.length + (_hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _hospitals.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final hospital = _hospitals[index];
                final typeFirst = hospital.type.isNotEmpty
                    ? hospital.type[0]
                    : '?';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(typeFirst)),
                    title: Text(
                      hospital.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('거리: ${hospital.distance} km'),
                        Text('주소: ${hospital.address}'),
                        Text('전화: ${hospital.tel}'),
                      ],
                    ),
                    trailing: hospital.lat != null && hospital.lng != null
                        ? IconButton(
                            icon: const Icon(
                              Icons.directions,
                              size: 36,
                              color: Colors.blue,
                            ),
                            tooltip: '길찾기',
                            onPressed: () => _openDirections(hospital),
                          )
                        : null,
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
