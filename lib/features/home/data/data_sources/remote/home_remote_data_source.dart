import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';

abstract class HomeRemoteDataSource {
  Future<MachineStatusResponse> getMachineStatus();
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
}

final homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
