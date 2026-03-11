class LoginRequest {
  final String code;

  const LoginRequest({required this.code});

  Map<String, dynamic> toJson() => {'authCode': code};
}
