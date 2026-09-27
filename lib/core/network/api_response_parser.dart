/// JSON 객체(Map)를 `Map<String, dynamic>`으로 변환한다. Map이 아니면 [FormatException].
Map<String, dynamic> castJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw const FormatException('Expected a JSON object.');
}

/// 응답 본문에서 `data` 객체를 꺼낸다.
Map<String, dynamic> extractDataMap(Map<String, dynamic> response) {
  return castJsonMap(response['data']);
}

/// 응답 본문에서 `data` 객체를 꺼내되, `data`가 null이면 null을 반환한다.
Map<String, dynamic>? extractNullableDataMap(Map<String, dynamic> response) {
  final data = response['data'];
  if (data == null) {
    return null;
  }

  return castJsonMap(data);
}
