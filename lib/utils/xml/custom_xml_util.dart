import 'package:xml/xml.dart';

// XML 유틸리티 클래스
// 저장소와 무관한 순수 XML 변환 유틸리티입니다.
//
// 주요 기능:
// - 안전한 XML 파싱 (에러 처리)
// - XML ↔ Map 변환
// - XML 검증
// - XML 포맷팅
// - XML 생성/수정
//
// JsonUtil과의 차이점:
// - JsonUtil: JSON 문자열 변환 (JSON 형식)
// - XmlUtil: XML 문자열 변환 (XML 형식)
class CustomXmlUtil {
  // ============================================
  // 기본 XML 파싱
  // ============================================

  // XML 문자열을 XmlDocument로 파싱
  //
  // 사용 예시:
  // ```dart
  // final xml = CustomXmlUtil.parse('<root><name>홍길동</name></root>');
  // final name = CustomXmlUtil.getText('<root><name>홍길동</name></root>', tag: 'name');
  // print(name); // 홍길동
  // ```
  static XmlDocument? parse(String xmlString) {
    try {
      return XmlDocument.parse(xmlString);
    } catch (e) {
      return null;
    }
  }

  // XML 문자열이 유효한지 검증
  //
  // 사용 예시:
  // ```dart
  // if (CustomXmlUtil.isValid('<root><name>홍길동</name></root>')) {
  //   print('유효한 XML입니다');
  // }
  // ```
  static bool isValid(String xmlString) {
    try {
      XmlDocument.parse(xmlString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // XML ↔ Map 변환
  // ============================================

  // XML 문자열을 Map으로 변환
  //
  // 사용 예시:
  // ```dart
  // final xmlString = '<user><name>홍길동</name><age>25</age></user>';
  // final map = CustomXmlUtil.toMap(xmlString);
  // print(map?['name']); // 홍길동
  // ```
  static Map<String, dynamic>? toMap(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;
      return _elementToMap(root);
    } catch (e) {
      return null;
    }
  }

  // Map을 XML 문자열로 변환
  //
  // 사용 예시:
  // ```dart
  // final map = {'name': '홍길동', 'age': 25};
  // final xmlString = CustomXmlUtil.fromMap(map, rootTag: 'user');
  // ```
  static String? fromMap(
    Map<String, dynamic> map, {
    String rootTag = 'root',
  }) {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element(rootTag, nest: () {
        _mapToElement(builder, map);
      });
      final document = builder.buildDocument();
      return document.toXmlString(pretty: false);
    } catch (e) {
      return null;
    }
  }

  // XML 문자열을 List<Map>으로 변환 (같은 태그의 여러 요소)
  //
  // 사용 예시:
  // ```dart
  // final xmlString = '<users><user><name>홍길동</name></user><user><name>김철수</name></user></users>';
  // final list = CustomXmlUtil.toList(xmlString, tag: 'user');
  // ```
  static List<Map<String, dynamic>>? toList(
    String xmlString, {
    required String tag,
  }) {
    try {
      final document = XmlDocument.parse(xmlString);
      final elements = document.findAllElements(tag);
      return elements.map((e) => _elementToMap(e)).toList();
    } catch (e) {
      return null;
    }
  }

  // List<Map>을 XML 문자열로 변환
  //
  // 사용 예시:
  // ```dart
  // final list = [
  //   {'name': '홍길동', 'age': 25},
  //   {'name': '김철수', 'age': 30},
  // ];
  // final xmlString = CustomXmlUtil.fromList(list, rootTag: 'users', itemTag: 'user');
  // ```
  static String? fromList(
    List<Map<String, dynamic>> list, {
    String rootTag = 'root',
    String itemTag = 'item',
  }) {
    try {
      final builder = XmlBuilder();
      builder.processing('xml', 'version="1.0" encoding="UTF-8"');
      builder.element(rootTag, nest: () {
        for (final item in list) {
          builder.element(itemTag, nest: () {
            _mapToElement(builder, item);
          });
        }
      });
      final document = builder.buildDocument();
      return document.toXmlString(pretty: false);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // XML 요소 접근
  // ============================================

  // 특정 태그의 첫 번째 요소의 텍스트 가져오기
  //
  // 사용 예시:
  // ```dart
  // final xmlString = '<user><name>홍길동</name><age>25</age></user>';
  // final name = CustomXmlUtil.getText(xmlString, tag: 'name');
  // // 홍길동
  // ```
  static String? getText(String xmlString, {required String tag}) {
    try {
      final document = XmlDocument.parse(xmlString);
      final element = document.findAllElements(tag).firstOrNull;
      return element?.innerText;
    } catch (e) {
      return null;
    }
  }

  // 특정 태그의 모든 요소의 텍스트 리스트 가져오기
  //
  // 사용 예시:
  // ```dart
  // final xmlString = '<users><name>홍길동</name><name>김철수</name></users>';
  // final names = CustomXmlUtil.getTextList(xmlString, tag: 'name');
  // // ['홍길동', '김철수']
  // ```
  static List<String>? getTextList(String xmlString, {required String tag}) {
    try {
      final document = XmlDocument.parse(xmlString);
      final elements = document.findAllElements(tag);
      return elements.map((e) => e.innerText).toList();
    } catch (e) {
      return null;
    }
  }

  // 특정 태그의 속성 값 가져오기
  //
  // 사용 예시:
  // ```dart
  // final xmlString = '<user id="1" name="홍길동"><age>25</age></user>';
  // final id = CustomXmlUtil.getAttribute(xmlString, tag: 'user', attribute: 'id');
  // // 1
  // ```
  static String? getAttribute(
    String xmlString, {
    required String tag,
    required String attribute,
  }) {
    try {
      final document = XmlDocument.parse(xmlString);
      final element = document.findAllElements(tag).firstOrNull;
      return element?.getAttribute(attribute);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // XML 포맷팅
  // ============================================

  // XML 문자열을 보기 좋게 포맷팅 (들여쓰기)
  //
  // 사용 예시:
  // ```dart
  // final formatted = CustomXmlUtil.format('<root><name>홍길동</name></root>');
  // ```
  static String? format(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return document.toXmlString(pretty: true);
    } catch (e) {
      return null;
    }
  }

  // XML 문자열을 압축 (공백 제거)
  //
  // 사용 예시:
  // ```dart
  // final compressed = CustomXmlUtil.compress(formattedXml);
  // ```
  static String? compress(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return document.toXmlString(pretty: false);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // XML 생성
  // ============================================

  // 간단한 XML 요소 생성
  //
  // 사용 예시:
  // ```dart
  // final xml = CustomXmlUtil.createElement('user', text: '홍길동');
  // // <user>홍길동</user>
  // ```
  static String createElement(
    String tag, {
    String? text,
    Map<String, String>? attributes,
    Map<String, dynamic>? children,
  }) {
    final builder = XmlBuilder();
    builder.element(tag, nest: () {
      if (attributes != null) {
        for (final entry in attributes.entries) {
          builder.attribute(entry.key, entry.value);
        }
      }
      if (text != null) {
        builder.text(text);
      }
      if (children != null) {
        _mapToElement(builder, children);
      }
    });
    return builder.buildDocument().toXmlString(pretty: false);
  }

  // ============================================
  // 내부 헬퍼 메서드
  // ============================================

  // XmlElement를 Map으로 변환
  static Map<String, dynamic> _elementToMap(XmlElement element) {
    final map = <String, dynamic>{};

    // 속성 추가
    for (final attribute in element.attributes) {
      map['@${attribute.name.local}'] = attribute.value;
    }

    // 자식 요소 처리
    final children = <String, List<dynamic>>{};
    for (final child in element.children) {
      if (child is XmlElement) {
        final tagName = child.name.local;
        if (!children.containsKey(tagName)) {
          children[tagName] = [];
        }
        children[tagName]!.add(_elementToMap(child));
      } else if (child is XmlText && child.value.trim().isNotEmpty) {
        // 텍스트 노드가 있으면 직접 추가
        if (map['#text'] == null) {
          map['#text'] = child.value.trim();
        } else {
          // 여러 텍스트 노드가 있는 경우
          if (map['#text'] is String) {
            map['#text'] = [map['#text'], child.value.trim()];
          } else {
            (map['#text'] as List).add(child.value.trim());
          }
        }
      }
    }

    // 자식 요소가 하나만 있으면 리스트가 아닌 단일 값으로 저장
    for (final entry in children.entries) {
      if (entry.value.length == 1) {
        final childMap = entry.value.first;
        // 자식이 텍스트만 있는 경우 (#text만 있는 경우) 값을 직접 반환
        if (childMap is Map<String, dynamic> &&
            childMap.length == 1 &&
            childMap.containsKey('#text')) {
          map[entry.key] = childMap['#text'];
        } else {
          map[entry.key] = childMap;
        }
      } else {
        // 리스트인 경우 각 항목도 확인
        map[entry.key] = entry.value.map((item) {
          if (item is Map<String, dynamic> &&
              item.length == 1 &&
              item.containsKey('#text')) {
            return item['#text'];
          }
          return item;
        }).toList();
      }
    }

    // 텍스트만 있고 자식 요소도 없고 속성도 없으면 텍스트 값만 반환
    // 하지만 부모 요소에서 사용할 때를 위해 Map 형태로 유지
    // 단, 속성이 있으면 속성과 텍스트를 함께 보존
    if (map.length == 1 && map.containsKey('#text')) {
      // 속성이 없고 텍스트만 있으면 텍스트 값만 반환하도록 특별 처리
      // 하지만 이 경우 부모에서 사용할 때 문제가 될 수 있으므로
      // 실제로는 부모에서 처리하도록 위의 로직에서 처리함
      return {'#text': map['#text']};
    }

    return map;
  }

  // Map을 XmlElement로 변환
  static void _mapToElement(XmlBuilder builder, Map<String, dynamic> map) {
    for (final entry in map.entries) {
      final key = entry.key;
      final value = entry.value;

      // 속성 처리 (@로 시작)
      if (key.startsWith('@')) {
        continue; // 속성은 별도로 처리
      }

      // 텍스트 노드 처리 (#text)
      if (key == '#text') {
        builder.text(value.toString());
        continue;
      }

      if (value is Map<String, dynamic>) {
        builder.element(key, nest: () {
          // 속성 추가
          for (final attrEntry in value.entries) {
            if (attrEntry.key.startsWith('@')) {
              builder.attribute(
                attrEntry.key.substring(1),
                attrEntry.value.toString(),
              );
            }
          }
          _mapToElement(builder, value);
        });
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            builder.element(key, nest: () {
              // 속성 추가
              for (final attrEntry in item.entries) {
                if (attrEntry.key.startsWith('@')) {
                  builder.attribute(
                    attrEntry.key.substring(1),
                    attrEntry.value.toString(),
                  );
                }
              }
              _mapToElement(builder, item);
            });
          } else {
            builder.element(key, nest: () {
              builder.text(item.toString());
            });
          }
        }
      } else {
        builder.element(key, nest: () {
          builder.text(value.toString());
        });
      }
    }
  }
}

