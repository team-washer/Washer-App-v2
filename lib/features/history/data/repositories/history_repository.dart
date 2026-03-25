import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

abstract class HistoryRepository {
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  });
}

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource _dataSource;

  const HistoryRepositoryImpl(this._dataSource);

  @override
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  }) {
    return _dataSource.getMachineHistory(
      machineId: machineId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      size: size,
    );
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(historyRemoteDataSourceProvider));
});
