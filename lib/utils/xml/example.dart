import 'package:flutter/material.dart';
import 'custom_xml_util.dart';

// XmlUtil 사용 예제 페이지
class XmlUtilExamplePage extends StatefulWidget {
  const XmlUtilExamplePage({super.key});

  @override
  State<XmlUtilExamplePage> createState() => _XmlUtilExamplePageState();
}

class _XmlUtilExamplePageState extends State<XmlUtilExamplePage> {
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XmlUtil 예제')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _basicExample,
              child: const Text('기본 XML 파싱'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _mapExample,
              child: const Text('XML ↔ Map 변환'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _validationExample,
              child: const Text('XML 검증'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _formattingExample,
              child: const Text('XML 포맷팅'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _accessExample,
              child: const Text('XML 요소 접근'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _listExample,
              child: const Text('XML 리스트 변환'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _createExample,
              child: const Text('XML 생성'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result.isEmpty ? '위 버튼을 눌러 예제를 실행하세요' : _result,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 기본 XML 파싱 예제
  void _basicExample() {
    setState(() {
      _result = '=== 기본 XML 파싱 ===\n\n';

      final xmlString = '<?xml version="1.0" encoding="UTF-8"?><user><name>홍길동</name><age>25</age></user>';
      final document = CustomXmlUtil.parse(xmlString);

      _result += '원본 XML:\n$xmlString\n\n';
      _result += '파싱 성공: ${document != null}\n';
      if (document != null) {
        final name = CustomXmlUtil.getText(xmlString, tag: 'name');
        final age = CustomXmlUtil.getText(xmlString, tag: 'age');
        _result += 'name: $name\n';
        _result += 'age: $age\n';
      }
    });
  }

  // XML ↔ Map 변환 예제
  void _mapExample() {
    setState(() {
      _result = '=== XML ↔ Map 변환 ===\n\n';

      // XML → Map
      final xmlString = '<?xml version="1.0" encoding="UTF-8"?><user><name>홍길동</name><age>25</age><email>hong@example.com</email></user>';
      final map = CustomXmlUtil.toMap(xmlString);

      _result += '원본 XML:\n$xmlString\n\n';
      _result += 'Map 변환:\n$map\n\n';

      // Map → XML
      final mapData = {
        'name': '김철수',
        'age': 30,
        'email': 'kim@example.com',
      };
      final xmlFromMap = CustomXmlUtil.fromMap(mapData, rootTag: 'user');
      _result += '원본 Map:\n$mapData\n\n';
      _result += 'XML 변환:\n${CustomXmlUtil.format(xmlFromMap ?? '')}\n';
    });
  }

  // XML 검증 예제
  void _validationExample() {
    setState(() {
      _result = '=== XML 검증 ===\n\n';

      final validXml = '<?xml version="1.0"?><root><name>홍길동</name></root>';
      final invalidXml = '<root><name>홍길동</name></root>'; // 닫는 태그 없음

      _result += '유효한 XML:\n$validXml\n';
      _result += '검증 결과: ${CustomXmlUtil.isValid(validXml)}\n\n';

      _result += '유효하지 않은 XML:\n$invalidXml\n';
      _result += '검증 결과: ${CustomXmlUtil.isValid(invalidXml)}\n';
    });
  }

  // XML 포맷팅 예제
  void _formattingExample() {
    setState(() {
      _result = '=== XML 포맷팅 ===\n\n';

      final xmlString = '<?xml version="1.0"?><user><name>홍길동</name><age>25</age><email>hong@example.com</email></user>';
      _result += '원본 (압축):\n$xmlString\n\n';

      final formatted = CustomXmlUtil.format(xmlString);
      _result += '포맷팅 (들여쓰기):\n$formatted\n\n';

      final compressed = CustomXmlUtil.compress(formatted ?? '');
      _result += '압축 (공백 제거):\n$compressed\n';
    });
  }

  // XML 요소 접근 예제
  void _accessExample() {
    setState(() {
      _result = '=== XML 요소 접근 ===\n\n';

      final xmlString = '<?xml version="1.0"?><user id="1" name="홍길동"><age>25</age><email>hong@example.com</email></user>';

      _result += '원본 XML:\n${CustomXmlUtil.format(xmlString)}\n\n';

      // 텍스트 가져오기
      final name = CustomXmlUtil.getText(xmlString, tag: 'name');
      final age = CustomXmlUtil.getText(xmlString, tag: 'age');
      _result += 'getText("name"): $name\n';
      _result += 'getText("age"): $age\n\n';

      // 속성 가져오기
      final id = CustomXmlUtil.getAttribute(
        xmlString,
        tag: 'user',
        attribute: 'id',
      );
      final nameAttr = CustomXmlUtil.getAttribute(
        xmlString,
        tag: 'user',
        attribute: 'name',
      );
      _result += 'getAttribute("user", "id"): $id\n';
      _result += 'getAttribute("user", "name"): $nameAttr\n';
    });
  }

  // XML 리스트 변환 예제
  void _listExample() {
    setState(() {
      _result = '=== XML 리스트 변환 ===\n\n';

      // XML → List<Map>
      final xmlString = '<?xml version="1.0"?><users><user><name>홍길동</name><age>25</age></user><user><name>김철수</name><age>30</age></user></users>';
      final list = CustomXmlUtil.toList(xmlString, tag: 'user');

      _result += '원본 XML:\n${CustomXmlUtil.format(xmlString)}\n\n';
      _result += 'List 변환:\n$list\n\n';

      // List<Map> → XML
      final listData = [
        {'name': '이영희', 'age': 28},
        {'name': '박민수', 'age': 32},
      ];
      final xmlFromList = CustomXmlUtil.fromList(
        listData,
        rootTag: 'users',
        itemTag: 'user',
      );
      _result += '원본 List:\n$listData\n\n';
      _result += 'XML 변환:\n${CustomXmlUtil.format(xmlFromList ?? '')}\n';
    });
  }

  // XML 생성 예제
  void _createExample() {
    setState(() {
      _result = '=== XML 생성 ===\n\n';

      // 간단한 요소 생성
      final simpleXml = CustomXmlUtil.createElement('user', text: '홍길동');
      _result += '간단한 요소:\n${CustomXmlUtil.format(simpleXml)}\n\n';

      // 속성이 있는 요소 생성
      final xmlWithAttr = CustomXmlUtil.createElement(
        'user',
        text: '홍길동',
        attributes: {'id': '1', 'role': 'admin'},
      );
      _result += '속성이 있는 요소:\n${CustomXmlUtil.format(xmlWithAttr)}\n\n';

      // 자식 요소가 있는 요소 생성
      final xmlWithChildren = CustomXmlUtil.createElement(
        'user',
        children: {
          'name': '홍길동',
          'age': '25',
          'email': 'hong@example.com',
        },
      );
      _result += '자식 요소가 있는 요소:\n${CustomXmlUtil.format(xmlWithChildren)}\n';
    });
  }
}

