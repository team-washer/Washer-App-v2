import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';

abstract class ReservationRemoteDataSource {
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

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  const ReservationRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    final payload = {
      'machineId': machineId,
      'startTime': startTime,
    };
    final response = await _client.post(
      '/api/v2/reservations',
      data: payload,
    );
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => ActiveReservationModel.fromJson(data));
  }

  @override
  Future<CancelReservationResponse> cancelReservation({
    required int id,
  }) async {
    final response = await _client.delete('/api/v2/reservations/$id');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => CancelReservationResponse.fromJson(data));
  }

  @override
  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  }) async {
    final response = await _client.put('/api/v2/reservations/$id/confirm');
    final data = Map<String, dynamic>.from(response.data as Map);

    return runInBackground(() => ConfirmReservationResponse.fromJson(data));
  }
}

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
      return ReservationRemoteDataSourceImpl(ref.watch(dioClientProvider));
    });
