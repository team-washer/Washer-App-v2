import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/remote/cancel_reservation_response.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';

abstract class ReservationRemoteDataSource {
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

class ReservationRemoteDataSourceImpl implements ReservationRemoteDataSource {
  final DioClient _client;

  const ReservationRemoteDataSourceImpl(this._client);

  @override
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  }) async {
    final response = await _client.post(
      '/api/v2/reservations',
      data: {
        'machineId': machineId,
        'startTime': startTime,
      },
    );
    // 예약 생성 성공 시 응답의 data 부분을 모델로 변환하여 리턴
    return ActiveReservationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  @override
  Future<CancelReservationResponse> cancelReservation({
    required int id,
  }) async {
    final response = await _client.delete(
      '/api/v2/reservations/$id',
    );
    return CancelReservationResponse.fromJson(response.data['data']);
  }

  @override
  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  }) async {
    final response = await _client.put(
      '/api/v2/reservations/$id/confirm',
    );
    return ConfirmReservationResponse.fromJson(response.data);
  }
}

final reservationRemoteDataSourceProvider =
    Provider<ReservationRemoteDataSource>((ref) {
      return ReservationRemoteDataSourceImpl(ref.watch(dioClientProvider));
    });
