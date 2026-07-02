import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/app_logger.dart';

/// 예약 취소 패널티 만료시각을 로컬에 보관한다.
///
/// 패널티 기간에는 서버가 예약 요청을 거부하므로, 만료시각을 저장해 두고
/// 그 사이의 예약 시도는 서버로 보내지 않고 클라이언트에서 곧바로 막는다.
/// 앱을 재시작해도 유지되도록 secure storage에 영속화한다.
///
/// secure storage는 기기 환경(Android Keystore, iOS Keychain 등)에 따라 예외를
/// 던질 수 있다. 저장소 실패가 예약/취소 흐름을 깨지 않도록 모든 저장소 접근을
/// 이 클래스 안에서 방어적으로 처리한다.
class ReservationPenaltyNotifier extends AsyncNotifier<DateTime?> {
  static const _storageKey = 'reservation_penalty_expires_at';

  @override
  Future<DateTime?> build() async {
    try {
      final raw = await ref.read(secureStorageProvider).read(key: _storageKey);
      final expiry = raw == null ? null : DateTime.tryParse(raw);

      // 저장된 값이 없거나 이미 만료됐으면 정리하고 없는 상태로 시작한다.
      if (expiry == null || !DateTime.now().isBefore(expiry)) {
        if (raw != null) {
          unawaited(_delete());
        }
        return null;
      }
      return expiry;
    } catch (error, stackTrace) {
      AppLogger.error(
        '패널티 만료 시각을 불러오는 중 오류가 발생했습니다.',
        name: 'ReservationPenaltyNotifier',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// 서버가 알려준 패널티 만료시각을 저장한다.
  ///
  /// 저장소 쓰기가 실패하더라도 서버가 이미 부과한 패널티이므로, 최소한 현재
  /// 세션 동안은 차단이 유지되도록 상태는 항상 갱신한다.
  Future<void> record(DateTime expiresAt) async {
    try {
      await ref
          .read(secureStorageProvider)
          .write(key: _storageKey, value: expiresAt.toIso8601String());
    } catch (error, stackTrace) {
      AppLogger.error(
        '패널티 만료 시각을 기록하는 중 오류가 발생했습니다.',
        name: 'ReservationPenaltyNotifier',
        error: error,
        stackTrace: stackTrace,
      );
    }
    state = AsyncData(expiresAt);
  }

  /// 만료된 패널티를 비운다.
  Future<void> clear() async {
    await _delete();
    state = const AsyncData(null);
  }

  Future<void> _delete() async {
    try {
      await ref.read(secureStorageProvider).delete(key: _storageKey);
    } catch (error, stackTrace) {
      AppLogger.error(
        '패널티 만료 시각을 삭제하는 중 오류가 발생했습니다.',
        name: 'ReservationPenaltyNotifier',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final reservationPenaltyProvider =
    AsyncNotifierProvider<ReservationPenaltyNotifier, DateTime?>(
      ReservationPenaltyNotifier.new,
    );
