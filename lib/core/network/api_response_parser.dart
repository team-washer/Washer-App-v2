Map<String, dynamic> castJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw const FormatException('Expected a JSON object.');
}

Map<String, dynamic> extractDataMap(Map<String, dynamic> response) {
  return castJsonMap(response['data']);
}

Map<String, dynamic>? extractNullableDataMap(Map<String, dynamic> response) {
  final data = response['data'];
  if (data == null) {
    return null;
  }

  return castJsonMap(data);
}
