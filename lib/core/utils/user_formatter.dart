class UserFormatter {
  const UserFormatter._();

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
