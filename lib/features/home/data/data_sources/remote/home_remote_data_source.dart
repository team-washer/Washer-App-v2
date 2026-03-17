import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

abstract class HomeRemoteDataSource {
  Future<MachineStatusResponse> getMachineStatus();
  Future<ActiveReservationModel?> getActiveReservation();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<MachineStatusResponse> getMachineStatus() async {
    final response = await _client.get('/api/v2/machines/status');
    final data = Map<String, dynamic>.from(response.data['data'] as Map);

    return runInBackground(() => MachineStatusResponse.fromJson(data));
  }

  @override
  Future<ActiveReservationModel?> getActiveReservation() async {
    try {
      final response = await _client.get('/api/v2/reservations/active');
      final rawData = response.data['data'];
      if (rawData == null) return null;

      final data = Map<String, dynamic>.from(rawData as Map);
      return runInBackground(() => ActiveReservationModel.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(ref.watch(dioClientProvider));
});