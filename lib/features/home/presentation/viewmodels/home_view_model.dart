import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/data/repositories/reservation_repository.dart';

/// 1초마다 시간을 업데이트하는 스트림 — 카운트다운 위젯에서 사용
/// (예: 세탁 완료까지 남은 시간 표시)
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// 데이터 갱신 중 발생한 에러 메시지 저장 (null이면 에러 없음)
/// AuthInterceptor와 refresh() 메서드에서 세팅됨
final pollingErrorProvider = StateProvider<String?>((ref) => null);

/// 세탁기/건조기 기기 상태 조회용 Notifier
/// 초기 요청 시만 API 호출, 이후 캐시 유지
final machineStatusProvider =
    AsyncNotifierProvider<MachineStatusNotifier, MachineStatusResponse>(
      MachineStatusNotifier.new,
    );

/// 기기 상태 조회 비즈니스 로직
/// - build(): 초기 로드 시 서버에서 데이터 조회
/// - refresh(): 사용자가 새로고침 요청 시 데이터 갱신
class MachineStatusNotifier extends AsyncNotifier<MachineStatusResponse> {
  /// 초기 로드 — 서버에서 기기 상태 조회
  @override
  Future<MachineStatusResponse> build() async {
    ref.keepAlive(); // 위젯이 언마운트되어도 캐시 유지
    try {
      return await ref.read(homeRepositoryProvider).getMachineStatus();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500) {
        ref.read(pollingErrorProvider.notifier).state =
            '서버 오류가 발생했습니다. ($statusCode)';
      } else if (e.response == null) {
        ref.read(pollingErrorProvider.notifier).state = '네트워크 오류가 발생했습니다.';
      }
      rethrow;
    }
  }

  /// Pull-to-Refresh 또는 앱 포그라운드 진입 시 호출 — 데이터 갱신
  Future<void> refresh() async {
    state = const AsyncLoading(); // 로딩 상태로 변경
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getMachineStatus(),
    );
  }
}

/// 현재 사용자의 활성 예약 정보 조회용 Notifier
/// (예약 중, 사용 중, 완료 등)
final activeReservationProvider =
    AsyncNotifierProvider<ActiveReservationNotifier, ActiveReservationModel?>(
      ActiveReservationNotifier.new,
    );

/// 활성 예약 조회 비즈니스 로직
/// - build(): 초기 로드 시 현재 예약 정보 조회
/// - refresh(): 사용자가 새로고침 요청 시 예약 상태 갱신
/// - cancelReservation(): 예약 취소
/// - confirmReservation(): 예약 확인
class ActiveReservationNotifier extends AsyncNotifier<ActiveReservationModel?> {
  /// 초기 로드 — 서버에서 현재 예약 조회
  @override
  Future<ActiveReservationModel?> build() async {
    ref.keepAlive(); // 위젯이 언마운트되어도 캐시 유지
    try {
      return await ref.read(homeRepositoryProvider).getActiveReservation();
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode >= 500) {
        ref.read(pollingErrorProvider.notifier).state =
            '서버 오류가 발생했습니다. ($statusCode)';
      } else if (e.response == null) {
        ref.read(pollingErrorProvider.notifier).state = '네트워크 오류가 발생했습니다.';
      }
      rethrow;
    }
  }

  /// Pull-to-Refresh 또는 앱 포그라운드 진입 시 호출 — 예약 정보 갱신
  Future<void> refresh() async {
    state = const AsyncLoading(); // 로딩 상태로 변경
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getActiveReservation(),
    );
  }

  /// 예약 취소 — reservationViewModel으로 이동됨
  Future<void> cancelReservation(int machineId) async {
    await ref
        .read(reservationRepositoryProvider)
        .cancelReservation(id: machineId);
    // 예약 취소 후 정보를 다시 조회
    await refresh();
    // 기계 상태도 함께 갱신
    await ref.read(machineStatusProvider.notifier).refresh();
  }

  /// 예약 확인 (세탁/건조 시작) — reservationViewModel으로 이동됨
  Future<void> confirmReservation(int machineId) async {
    await ref
        .read(reservationRepositoryProvider)
        .confirmReservation(id: machineId);
    // 예약 확인 후 정보를 다시 조회
    await refresh();
    // 기계 상태도 함께 갱신
    await ref.read(machineStatusProvider.notifier).refresh();
  }
}
