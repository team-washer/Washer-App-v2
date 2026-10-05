/// 앱 전역 오류 안내 문구 (에러 토스트·스낵바에 그대로 노출).
///
/// 문구만 모아 둔다. 어떤 오류에 어떤 문구를 쓸지는 `AppException`
/// (`core/network/error.dart`)이 서버 errorCode·상태 코드로 결정한다.
class WasherErrorMessage {
  WasherErrorMessage._();

  // ============================================
  // Common - 공통
  // ============================================

  static const validation = '입력한 정보를 다시 확인해주세요.';
  static const conflict = '다른 요청과 겹쳤어요.\n최신 상태를 확인한 뒤 다시 시도해주세요.';
  static const unprocessable = '요청을 처리할 수 없어요.\n잠시 후 다시 시도해주세요.';
  static const network = '네트워크 연결을 확인해주세요.';
  static const cancelled = '요청이 취소되었어요.';
  static const dataParsing = '데이터를 불러오는 중 오류가 발생했습니다.';
  static const unknown = '알 수 없는 오류가 발생했습니다.';
  static const serverError = '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  static const serviceUnavailable = '서비스가 잠시 불안정해요.\n잠시 후 다시 시도해주세요.';
  static const deviceConnection = '기기와 연결할 수 없어요.\n잠시 후 다시 시도해주세요.';

  // ============================================
  // Auth / User - 인증·사용자
  // ============================================

  static const loginRequired = '로그인이 필요해요. 다시 로그인해주세요.';
  static const forbidden = '이 기능을 이용할 수 없어요.';
  static const withdrawnRejoinRestricted = '탈퇴 후 30일이 지나야 다시 가입할 수 있어요.';
  static const userNotFound = '사용자 정보를 찾을 수 없어요.\n다시 로그인해주세요.';
  static const userNotEligible = '현재 예약 서비스를 이용할 수 없는 사용자예요.';
  static const userFloorRestricted = '5층 기숙사생은 워셔를 이용할 수 없어요.';

  // ============================================
  // Room - 호실
  // ============================================

  static const roomNotFound = '호실 정보를 찾을 수 없어요.\n관리자에게 문의해주세요.';
  static const roomWashingBanned = '우리 호실은 지금 세탁이 금지된 상태예요.\n관리자에게 문의해주세요.';
  static const roomReservationRestricted = '최근 취소 횟수가 많아 우리 호실의 예약이 제한됐어요.';
  static const roomMachineTypeReserved =
      '우리 호실에 같은 종류의 기기 예약이 이미 있어요.\n'
      '다른 종류의 기기를 고르거나 기존 예약이 끝난 뒤 다시 시도해주세요.';

  // ============================================
  // Reservation - 예약
  // ============================================

  static const reservationNotFound = '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.';
  static const userActiveReservation =
      '이미 진행 중인 내 예약이 있어요.\n홈에서 기존 예약을 확인해주세요.';
  static const userPenaltyActive = '지금은 예약이 제한된 상태예요.\n제한이 풀린 뒤 다시 시도해주세요.';
  static const reservationCooldownActive =
      '예약을 취소한 직후라 같은 종류의 기기는 잠시 예약할 수 없어요.';
  static const reservationTimeRestricted = '지금은 예약할 수 있는 시간이 아니에요.';
  static const reservationAlreadyStarted = '이미 사용이 시작된 예약은 취소할 수 없어요.';
  static const reservationStateChanged = '예약 상태가 바뀌었어요.\n최신 상태를 확인해주세요.';
  static const reservationAccessDenied = '이 예약을 처리할 권한이 없어요.';

  // ============================================
  // Machine - 기기
  // ============================================

  static const machineNotFound = '기기 정보를 찾을 수 없어요.\n기기 목록을 새로고침해주세요.';
  static const machineUnavailable = '지금은 이 기기를 사용할 수 없어요.\n다른 기기를 선택해주세요.';
  static const machineTaken =
      '이미 사용 중이거나 예약된 기기예요.\n기기 상태를 새로고침한 뒤 다른 기기를 선택해주세요.';
  static const machineShuttingDown = '기기가 종료되는 중이에요.\n잠시 후 다시 시도해주세요.';

  // ============================================
  // History - 사용 기록
  // ============================================

  static const historyLoadFailed = '사용 기록을 불러오지 못했어요.';

  // ============================================
  // Report - 고장 신고
  // ============================================

  static const reportDescriptionRequired = '고장 내용을 입력해주세요.';
}
