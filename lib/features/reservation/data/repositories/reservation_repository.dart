import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_remote_data_source.dart';

abstract class ReservationRepository {
  Future<void> createReservation({
    required int machineId,
    required String startTime,
  });
}

class ReservationRepositoryImpl implements ReservationRepository {
  final ReservationRemoteDataSource _dataSource;

  const ReservationRepositoryImpl(this._dataSource);

  @override
  Future<void> createReservation({
    required int machineId,
    required String startTime,
  }) {
    return _dataSource.createReservation(
      machineId: machineId,
      startTime: startTime,
    );
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepositoryImpl(
    ref.watch(reservationRemoteDataSourceProvider),
  );
});
