# CustomXmlUtil

저장소와 무관한 순수 XML 변환 유틸리티 클래스입니다.

## JsonUtil과의 차이점

- **JsonUtil**: JSON 문자열 변환 (JSON 형식)
- **XmlUtil**: XML 문자열 변환 (XML 형식)

## 주요 기능

### 1. 기본 XML 파싱

```dart
// XML 파싱
final xml = CustomXmlUtil.parse('<root><name>홍길동</name></root>');
final name = CustomXmlUtil.getText('<root><name>홍길동</name></root>', tag: 'name');
print(name); // 홍길동

// XML 검증
if (CustomXmlUtil.isValid('<root><name>홍길동</name></root>')) {
  print('유효한 XML입니다');
}
```

### 2. XML ↔ Map 변환

```dart
// XML → Map
final xmlString = '<user><name>홍길동</name><age>25</age></user>';
final map = CustomXmlUtil.toMap(xmlString);
print(map?['name']); // 홍길동

// Map → XML
final mapData = {'name': '홍길동', 'age': 25};
final xmlString = CustomXmlUtil.fromMap(mapData, rootTag: 'user');
```

### 3. XML 요소 접근

```dart
// 텍스트 가져오기
final name = CustomXmlUtil.getText(xmlString, tag: 'name');
// 홍길동

// 속성 가져오기
final id = CustomXmlUtil.getAttribute(
  xmlString,
  tag: 'user',
  attribute: 'id',
);

// 텍스트 리스트 가져오기
final names = CustomXmlUtil.getTextList(xmlString, tag: 'name');
```

### 4. XML 포맷팅

```dart
// 포맷팅 (들여쓰기)
final formatted = CustomXmlUtil.format('<root><name>홍길동</name></root>');
// <?xml version="1.0" encoding="UTF-8"?>
// <root>
//   <name>홍길동</name>
// </root>

// 압축 (공백 제거)
final compressed = CustomXmlUtil.compress(formatted);
```

### 5. XML 리스트 변환

```dart
// XML → List<Map>
final xmlString = '<users><user><name>홍길동</name></user><user><name>김철수</name></user></users>';
final list = CustomXmlUtil.toList(xmlString, tag: 'user');

// List<Map> → XML
final listData = [
  {'name': '홍길동', 'age': 25},
  {'name': '김철수', 'age': 30},
];
final xmlString = CustomXmlUtil.fromList(
  listData,
  rootTag: 'users',
  itemTag: 'user',
);
```

### 6. XML 생성

```dart
// 간단한 요소 생성
final xml = CustomXmlUtil.createElement('user', text: '홍길동');
// <user>홍길동</user>

// 속성이 있는 요소 생성
final xmlWithAttr = CustomXmlUtil.createElement(
  'user',
  text: '홍길동',
  attributes: {'id': '1', 'role': 'admin'},
);

// 자식 요소가 있는 요소 생성
final xmlWithChildren = CustomXmlUtil.createElement(
  'user',
  children: {
    'name': '홍길동',
    'age': '25',
  },
);
```

## 사용 사례

### API 응답 파싱

```dart
// HTTP 응답 파싱
final response = await http.get(url);
final map = CustomXmlUtil.toMap(response.body);
final userName = map?['user']?['name'];
```

### 네트워크 통신

```dart
// 요청 데이터 XML 변환
final requestData = {'name': '홍길동', 'age': 25};
final xmlBody = CustomXmlUtil.fromMap(requestData, rootTag: 'user');

// 응답 데이터 파싱
final responseMap = CustomXmlUtil.toMap(response.body);
```

### RSS 피드 파싱

```dart
// RSS 피드에서 아이템 리스트 추출
final rssXml = await http.get(rssUrl);
final items = CustomXmlUtil.toList(
  rssXml.body,
  tag: 'item',
);
```

## 메서드 목록

### 기본 파싱

- `parse(String xmlString)` - XML 문자열 → XmlDocument
- `isValid(String xmlString)` - XML 유효성 검증

### Map 변환

- `toMap(String xmlString)` - XML → Map
- `fromMap(Map map, {String rootTag})` - Map → XML
- `toList(String xmlString, {String tag})` - XML → List<Map>
- `fromList(List<Map> list, {String rootTag, String itemTag})` - List<Map> → XML

### 요소 접근

- `getText(String xmlString, {String tag})` - 태그의 텍스트 가져오기
- `getTextList(String xmlString, {String tag})` - 태그의 텍스트 리스트 가져오기
- `getAttribute(String xmlString, {String tag, String attribute})` - 속성 값 가져오기

### 포맷팅

- `format(String xmlString)` - XML 포맷팅 (들여쓰기)
- `compress(String xmlString)` - XML 압축 (공백 제거)

### 생성

- `createElement(String tag, {String? text, Map<String, String>? attributes, Map<String, dynamic>? children})` - XML 요소 생성

## 의존성

- `xml: ^6.5.0` (pub.dev 패키지)

## 참고

- JsonUtil과 함께 사용하면 JSON과 XML 형식을 모두 처리할 수 있습니다.
- 네트워크 통신 클래스와 함께 사용하면 API 요청/응답 처리가 용이합니다.
- RSS 피드나 SOAP API와 같은 XML 기반 서비스와 통신할 때 유용합니다.

