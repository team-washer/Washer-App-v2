import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/reservation/data/repositories/reservation_repository.dart';

/// 예약 생성 작업의 상태 열거형
/// - idle: 초기 상태
/// - loading: 요청 중
/// - success: 예약 완료
/// - error: 예약 실패
enum ReservationActionStatus { idle, loading, success, error }

/// 예약 작업의 상태 정보 클래스
class ReservationActionState {
  final ReservationActionStatus status;
  final String? errorMessage;

  const ReservationActionState({
    this.status = ReservationActionStatus.idle,
    this.errorMessage,
  });

  ReservationActionState copyWith({
    ReservationActionStatus? status,
    String? errorMessage,
  }) {
    return ReservationActionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 예약 생성 비즈니스 로직을 관리하는 뷰모델
/// - reserve(): 기계 예약 요청
/// - reset(): 상태 초기화
class ReservationViewModel extends Notifier<ReservationActionState> {
  @override
  ReservationActionState build() => const ReservationActionState();

  /// 기계 예약 요청 — 서버에 예약 정보 전송
  Future<void> reserve({
    required int machineId,
    required DateTime startTime,
  }) async {
    state = state.copyWith(status: ReservationActionStatus.loading);
    try {
      final isoString = startTime.toIso8601String();
      await ref
          .read(reservationRepositoryProvider)
          .createReservation(
            machineId: machineId,
            startTime: isoString,
          );
      state = state.copyWith(status: ReservationActionStatus.success);
    } catch (e) {
      // 서버 에러 응답에서 message 추출
      String errorMessage = '예약에 실패했습니다. 다시 시도해주세요.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
          print('❌ 예약 실패: $errorMessage');
        }
      }

      state = state.copyWith(
        status: ReservationActionStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  /// 상태 초기화 — 예약 완료 후 상태 리셋
  void reset() {
    state = const ReservationActionState();
  }
}

final reservationViewModelProvider =
    NotifierProvider<ReservationViewModel, ReservationActionState>(
      ReservationViewModel.new,
    );
