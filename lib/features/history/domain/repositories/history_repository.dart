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
