import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';

abstract class ReservationRemoteDataSource {
  Future<void> createReservation({
    required int machineId,
    required String startTime,
  });
}

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final DioClient _client;

  const ReservationRemoteDataSourceImpl(this._client);

  @override
  Future<void> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    await _client.post(
      '/api/v2/reservations',
      data: {
        'machineId': machineId,
        'startTime': startTime,
      },
    );
  }
}

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
      return ReservationRemoteDataSourceImpl(ref.watch(dioClientProvider));
    });
