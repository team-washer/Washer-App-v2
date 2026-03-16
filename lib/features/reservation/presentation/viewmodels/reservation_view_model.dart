import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:washer/features/reservation/data/repositories/reservation_repository.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';

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
  final ActiveReservationModel? reservation; // 생성 완료된 예약 정보

  const ReservationActionState({
    this.status = ReservationActionStatus.idle,
    this.errorMessage,
    this.reservation,
  });

  ReservationActionState copyWith({
    ReservationActionStatus? status,
    String? errorMessage,
    ActiveReservationModel? reservation,
  }) {
    return ReservationActionState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      reservation: reservation ?? this.reservation,
    );
  }
}

/// 예약 생성 비즈니스 로직을 관리하는 뷰모델
/// - reserve(): 기계 예약 요청
/// - reset(): 상태 초기화
class ReservationViewModel extends Notifier<ReservationActionState> {
  Timer? _pollingTimer;
  Timer? _expiryTimer;

  @override
  ReservationActionState build() => const ReservationActionState();

  /// 기계 예약 요청 — 서버에 예약 정보 전송
  Future<void> reserve({
    required int machineId,
  }) async {
    state = state.copyWith(status: ReservationActionStatus.loading);
    try {
      // 현재 시간 + 5분으로 설정 (서버 시간 동기화 문제 해결)
      final startTime = DateTime.now()
          .add(Duration(seconds: 5))
          .toIso8601String();

      print('예약 요청 - machineId: $machineId, startTime: $startTime');

      // 예약 API 호출 및 생성된 예약 정보 수신
      final createdReservation = await ref
          .read(reservationRepositoryProvider)
          .createReservation(
            machineId: machineId,
            startTime: startTime,
          );

      // 서버 응답 대기 - 예약이 DB에 저장될 시간 확보
      await Future.delayed(const Duration(milliseconds: 500));

      // 예약 생성 후 데이터 갱신
      await ref.read(activeReservationProvider.notifier).refresh();
      await ref.read(machineStatusProvider.notifier).refresh();

      // 생성된 예약 정보를 상태에 저장
      state = state.copyWith(
        status: ReservationActionStatus.success,
        reservation: createdReservation,
      );
    } catch (e) {
      // 서버 에러 응답에서 message 추출
      String errorMessage = '예약에 실패했습니다. 다시 시도해주세요.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
        }
      }

      state = state.copyWith(
        status: ReservationActionStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  /// 예약 취소
  Future<void> cancel({required int reservationId}) async {
    state = state.copyWith(status: ReservationActionStatus.loading);
    try {
      await ref
          .read(reservationRepositoryProvider)
          .cancelReservation(id: reservationId);

      await Future.delayed(const Duration(milliseconds: 500));
      await ref.read(activeReservationProvider.notifier).refresh();
      await ref.read(machineStatusProvider.notifier).refresh();

      state = state.copyWith(status: ReservationActionStatus.success);
    } catch (e) {
      String errorMessage = '예약 취소에 실패했습니다.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
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
    _stopPolling();
  }

  /// 예약 확인 시작 - confirm API 1회 호출 후 3분 동안 10초마다 myReservation 폴링
  Future<void> confirmAndWatch({required int reservationId}) async {
    state = state.copyWith(status: ReservationActionStatus.loading);
    try {
      await ref
          .read(reservationRepositoryProvider)
          .confirmReservation(id: reservationId);
      state = state.copyWith(status: ReservationActionStatus.success);
      _startPollingReservation();
    } catch (e) {
      String errorMessage = '예약 확인에 실패했습니다.';
      if (e is DioException && e.response?.data != null) {
        final response = e.response!.data;
        if (response is Map<String, dynamic> &&
            response.containsKey('message')) {
          errorMessage = response['message'] as String;
        }
      }
      state = state.copyWith(
        status: ReservationActionStatus.error,
        errorMessage: errorMessage,
      );
    }
  }

  /// myReservation 폴링 — 3분 동안 10초 주기로 상태 변화만 반영
  void _startPollingReservation() {
    // 기존 타이머 정리
    _stopPolling();

    // 3분 후 폴링 중단
    _expiryTimer = Timer(const Duration(minutes: 3), () {
      _stopPolling();
    });

    // 10초마다 myReservation 호출
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        // 현재 캐시된 활성 예약
        final ActiveReservationModel? current =
            ref.read(activeReservationProvider).maybeWhen(
                  data: (value) => value,
                  orElse: () => null,
                );

        // 서버에서 최신 myReservation 조회
        final ActiveReservationModel? latest =
            await ref.read(homeRepositoryProvider).getActiveReservation();

        // 데이터가 변경된 경우에만 상태 갱신 (로딩 상태 없이)
        if (current != latest) {
          ref.read(activeReservationProvider.notifier).setReservation(latest);
          await ref.read(machineStatusProvider.notifier).refresh();
        }
      } catch (e) {
        // 폴링 중 에러는 무시하고 다음 주기로 넘어감
      }
    });
  }

  /// 폴링 중단
  void _stopPolling() {
    _pollingTimer?.cancel();
    _expiryTimer?.cancel();
    _pollingTimer = null;
    _expiryTimer = null;
  }
}

final reservationViewModelProvider =
    NotifierProvider<ReservationViewModel, ReservationActionState>(
      ReservationViewModel.new,
    );
