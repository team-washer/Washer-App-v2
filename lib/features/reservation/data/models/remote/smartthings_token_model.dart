/// 서버(`GET /smartthings/token`)가 발급한 단기 SmartThings 액세스 토큰.
///
/// 클라이언트는 이 토큰으로만 SmartThings API를 직접 호출하며,
/// 만료되면 다시 서버에서 새 토큰을 발급받는다.
class SmartThingsTokenModel {
  const SmartThingsTokenModel({
    required this.accessToken,
    this.expiresAt,
  });

  final String accessToken;
  final DateTime? expiresAt;

  factory SmartThingsTokenModel.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAt'];
    return SmartThingsTokenModel(
      accessToken: json['accessToken'] as String,
      expiresAt: expiresRaw is String ? DateTime.tryParse(expiresRaw) : null,
    );
  }

  /// 만료까지 [margin] 이내로 남았으면 곧 만료될 토큰으로 간주한다.
  bool isExpiringWithin(Duration margin, {DateTime? now}) {
    final expiry = expiresAt;
    if (expiry == null) {
      return false;
    }
    final reference = now ?? DateTime.now();
    return expiry.isBefore(reference.add(margin));
  }
}
