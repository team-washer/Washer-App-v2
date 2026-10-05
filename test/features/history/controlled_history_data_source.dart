import 'dart:async';

import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';

/// 사용 기록 요청의 응답 시점을 테스트가 직접 제어하는 fake.
class ControlledHistoryDataSource implements HistoryRemoteDataSource {
  final requests = <HistoryRequest>[];

  @override
  Future<MachineHistoryResponse> getMachineHistory({
    required int machineId,
    required String startDate,
    required String endDate,
    int page = 0,
    int size = 20,
  }) {
    final request = HistoryRequest(machineId);
    requests.add(request);
    return request.completer.future;
  }
}

/// 요청 한 건. [succeed] 또는 [fail]로 응답을 돌려준다.
class HistoryRequest {
  HistoryRequest(this.machineId);

  final int machineId;
  final completer = Completer<MachineHistoryResponse>();

  void succeed(List<int> ids) => completer.complete(historyPage(ids));

  void fail() => completer.completeError(Exception('history failed'));
}

/// [ids]를 기록 id로 갖는 마지막 페이지 응답.
MachineHistoryResponse historyPage(List<int> ids) => MachineHistoryResponse(
  content: [
    for (final id in ids)
      HistoryContent(
        id: id,
        userRoomNumber: '30$id',
        startTime: '2026-10-04T21:30:00',
        completionTime: '2026-10-04T23:00:00',
        status: 'COMPLETED',
        createdAt: '2026-10-04T21:00:00',
      ),
  ],
  pageNumber: 0,
  pageSize: 50,
  totalElements: ids.length,
  totalPages: 1,
  last: true,
);
