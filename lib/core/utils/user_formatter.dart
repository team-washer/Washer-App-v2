/// 사용자 표시 문자열 유틸.
class UserFormatter {
  const UserFormatter._();

  /// '학번 이름' 형태로 만든다. 이름이 없으면 null, 학번이 없으면 이름만 반환.
  static String? formatUserLabel({
    required String? studentId,
    required String? userName,
  }) {
    final normalizedStudentId = studentId?.trim();
    final normalizedUserName = userName?.trim();

    if (normalizedUserName == null || normalizedUserName.isEmpty) {
      return null;
    }

    if (normalizedStudentId == null || normalizedStudentId.isEmpty) {
      return normalizedUserName;
    }

    return '$normalizedStudentId $normalizedUserName';
  }
}
