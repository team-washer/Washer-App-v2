import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';

/// 예약 취소 패널티 만료시각을 로컬에 보관한다.
///
/// 패널티 기간에는 서버가 예약 요청을 거부하므로, 만료시각을 저장해 두고
/// 그 사이의 예약 시도는 서버로 보내지 않고 클라이언트에서 곧바로 막는다.
/// 앱을 재시작해도 유지되도록 secure storage에 영속화한다.
class ReservationPenaltyNotifier extends AsyncNotifier<DateTime?> {
  static const _storageKey = 'reservation_penalty_expires_at';

  @override
  Future<DateTime?> build() async {
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
  }

  /// 서버가 알려준 패널티 만료시각을 저장한다.
  Future<void> record(DateTime expiresAt) async {
    await ref
        .read(secureStorageProvider)
        .write(key: _storageKey, value: expiresAt.toIso8601String());
    state = AsyncData(expiresAt);
  }

  /// 만료된 패널티를 비운다.
  Future<void> clear() async {
    await _delete();
    state = const AsyncData(null);
  }

  Future<void> _delete() =>
      ref.read(secureStorageProvider).delete(key: _storageKey);
}

final reservationPenaltyProvider =
    AsyncNotifierProvider<ReservationPenaltyNotifier, DateTime?>(
      ReservationPenaltyNotifier.new,
    );
