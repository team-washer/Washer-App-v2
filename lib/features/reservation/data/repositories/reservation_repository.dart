import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';

abstract class ReservationRepository {
  /// 예약 생성 — 성공 시 생성된 예약 전체 정보 반환
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  });

  Future<CancelReservationResponse> cancelReservation({
    required int id,
  });

  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  });
}

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource _dataSource;

  const ReservationRepositoryImpl(this._dataSource);

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) {
    return _dataSource.createReservation(
      machineId: machineId,
      startTime: startTime,
    );
  }

  @override
  Future<CancelReservationResponse> cancelReservation({
    required int id,
  }) {
    return _dataSource.cancelReservation(
      id: id,
    );
  }

  @override
  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  }) {
    return _dataSource.confirmReservation(
      id: id,
    );
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(
    ref.watch(reservationRemoteDataSourceProvider),
  );
});
