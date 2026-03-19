/// 세탁기/건조기의 현재 작동 상태를 나타내는 enum
enum MachineState {
  // 공통
  none, // 작업 없음
  pause, // 일시 정지
  run, // 작동 중
  stop, // 정지
  // 세탁 관련
  wash, // 세탁
  aIWash, // AI 세탁
  preWash, // 애벌 세탁
  rinse, // 헹굼
  aIRinse, // AI 헹굼
  spin, // 탈수
  aISpin, // AI 탈수
  delayWash, // 예약 세탁
  // 건조 관련
  drying, // 건조
  aIDrying, // AI 건조
  // 완료/후처리
  finished, // 완료
  cooling, // 냉각
  wrinklePrevent, // 구김 방지
  // 특수 기능
  weightSensing, // 무게 감지
  refreshing, // 탈취/리프레시
  airWash, // 에어워시
  sanitizing, // 살균
  // 제습 관련
  dehumidifying, // 제습
  continuousDehumidifying, // 지속 제습
  // 유지보수
  internalCare, // 내부 관리
  freezeProtection, // 동결 방지
  thawingFrozenInside, // 결빙 해동
}

extension MachineStateExt on MachineState {
  String get text {
    switch (this) {
      case MachineState.none:
        return "작업 없음";
      case MachineState.pause:
        return "일시 정지";
      case MachineState.run:
        return "작동 중";
      case MachineState.stop:
        return "정지";

      case MachineState.wash:
        return "세탁 중";
      case MachineState.aIWash:
        return "AI 세탁 중";
      case MachineState.preWash:
        return "애벌 세탁 중";
      case MachineState.rinse:
        return "헹굼 중";
      case MachineState.aIRinse:
        return "AI 헹굼 중";
      case MachineState.spin:
        return "탈수 중";
      case MachineState.aISpin:
        return "AI 탈수 중";
      case MachineState.delayWash:
        return "예약 세탁 대기 중";

      case MachineState.drying:
        return "건조 중";
      case MachineState.aIDrying:
        return "AI 건조 중";

      case MachineState.finished:
        return "완료";
      case MachineState.cooling:
        return "냉각 중";
      case MachineState.wrinklePrevent:
        return "구김 방지 중";

      case MachineState.weightSensing:
        return "무게 측정 중";
      case MachineState.refreshing:
        return "탈취 중";
      case MachineState.airWash:
        return "에어워시 중";
      case MachineState.sanitizing:
        return "살균 중";

      case MachineState.dehumidifying:
        return "제습 중";
      case MachineState.continuousDehumidifying:
        return "지속 제습 중";

      case MachineState.internalCare:
        return "내부 관리 중";
      case MachineState.freezeProtection:
        return "동결 방지 중";
      case MachineState.thawingFrozenInside:
        return "결빙 해동 중";
    }
  }

  /// API 문자열을 MachineState로 매핑하는 Map
  static const Map<String, MachineState> _stringToStateMap = {
    // 공통
    'none': MachineState.none,
    'pause': MachineState.pause,
    'run': MachineState.run,
    'stop': MachineState.stop,

    // 세탁 관련
    'wash': MachineState.wash,
    'aiwash': MachineState.aIWash,
    'prewash': MachineState.preWash,
    'rinse': MachineState.rinse,
    'airinse': MachineState.aIRinse,
    'spin': MachineState.spin,
    'aispin': MachineState.aISpin,
    'delaywash': MachineState.delayWash,

    // 건조 관련
    'drying': MachineState.drying,
    'aidrying': MachineState.aIDrying,

    // 완료/후처리
    'finished': MachineState.finished,
    'finish': MachineState.finished,
    'cooling': MachineState.cooling,
    'wrinkleprevent': MachineState.wrinklePrevent,

    // 특수 기능
    'weightsensing': MachineState.weightSensing,
    'refreshing': MachineState.refreshing,
    'airwash': MachineState.airWash,
    'sanitizing': MachineState.sanitizing,

    // 제습 관련
    'dehumidifying': MachineState.dehumidifying,
    'continuousdehumidifying': MachineState.continuousDehumidifying,

    // 유지보수
    'internalcare': MachineState.internalCare,
    'freezeprotection': MachineState.freezeProtection,
    'thawingfrozeninside': MachineState.thawingFrozenInside,
  };

  /// API에서 받은 문자열을 MachineState로 변환
  static MachineState? fromString(String? value) {
    if (value == null) return null;
    return _stringToStateMap[value.toLowerCase()];
  }
}
