import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

abstract class HomeRemoteDataSource {
  Future<MachineStatusResponse> getMachineStatus();
  Future<ActiveReservationModel?> getActiveReservation();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final DioClient _client;

  const HomeRemoteDataSourceImpl(this._client);

  @override
  Future<MachineStatusResponse> getMachineStatus() async {
    final response = await _client.get('/api/v2/machines/status');
    return MachineStatusResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ActiveReservationModel?> getActiveReservation() async {
    try {
      final response = await _client.get('/api/v2/reservations/active');
      final data = response.data['data'];
      if (data == null) return null;
      return ActiveReservationModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
