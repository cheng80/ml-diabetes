/// 공공데이터 API 병원 정보 모델
class Hospital {
  final String name;
  final String distance;
  final String address;
  final String type;
  final String tel;

  Hospital({
    required this.name,
    required this.distance,
    required this.address,
    required this.type,
    required this.tel,
  });
}
