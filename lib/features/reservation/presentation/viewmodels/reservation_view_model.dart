import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/home/presentation/viewmodels/home_view_model.dart';
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
          .add(const Duration(minutes: 5))
          .toIso8601String();

      // 예약 API 호출
      await ref
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

      state = state.copyWith(status: ReservationActionStatus.success);
      
      // 30초 폴링 시작 (5분 제한)
      _startPolling();
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

  /// 30초마다 예약 확인 폴링 (5분 제한)
  void _startPolling() {
    // 기존 타이머 정리
    _stopPolling();

    // 5분 후 폴링 중단
    _expiryTimer = Timer(const Duration(minutes: 5), () {
      _stopPolling();
    });

    // 30초마다 폴링
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        // 예약 상태 확인
        final reservation =
            await ref.read(homeRepositoryProvider).getActiveReservation();

        // 예약이 확인되었으면 상태 업데이트
        if (reservation != null) {
          await ref.read(machineStatusProvider.notifier).refresh();
        }
      } catch (e) {
        // 폴링 중 에러는 무시
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
