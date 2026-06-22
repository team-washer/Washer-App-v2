/// SmartThings `GET /v1/devices/{deviceId}/status` 응답에서
/// 세탁기/건조기의 운전 상태만 추출한 모델.
///
/// 응답 구조는 `components.main.<capability>.<attribute>.value` 형태다.
class SmartThingsDeviceStatus {
  const SmartThingsDeviceStatus({
    this.machineState,
    this.jobState,
    this.switchStatus,
    this.completionTime,
  });

  /// 기기 동작 단계(run/pause/stop).
  final String? machineState;

  /// 세부 작업 상태(wash/rinse/spin/drying/finish/none ...).
  final String? jobState;

  /// 전원 상태(on/off).
  final String? switchStatus;

  /// 완료 예정 시각(ISO 8601 문자열).
  final String? completionTime;

  bool get isEmpty =>
      machineState == null &&
      jobState == null &&
      switchStatus == null &&
      completionTime == null;

  factory SmartThingsDeviceStatus.fromJson(Map<String, dynamic> json) {
    final main = _asMap(_asMap(json['components'])?['main']);
    if (main == null) {
      return const SmartThingsDeviceStatus();
    }

    // 세탁기는 washerOperatingState, 건조기는 dryerOperatingState 를 사용한다.
    // 삼성 커스텀 capability(samsungce.*)도 함께 살핀다.
    final operating =
        _asMap(main['washerOperatingState']) ??
        _asMap(main['dryerOperatingState']) ??
        _asMap(main['samsungce.washerOperatingState']) ??
        _asMap(main['samsungce.dryerOperatingState']);

    return SmartThingsDeviceStatus(
      machineState: _attr(operating, 'machineState'),
      jobState:
          _attr(operating, 'washerJobState') ??
          _attr(operating, 'dryerJobState') ??
          _attr(operating, 'jobState'),
      switchStatus: _attr(_asMap(main['switch']), 'switch'),
      completionTime: _attr(operating, 'completionTime'),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  /// SmartThings 속성은 `{ "value": ..., "timestamp": ... }` 형태로 내려온다.
  static String? _attr(Map<String, dynamic>? capability, String attribute) {
    if (capability == null) {
      return null;
    }
    final value = _asMap(capability[attribute])?['value'];
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
