import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';

abstract class ReportRepository {
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  });
}

class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _dataSource;

  const ReportRepositoryImpl(this._dataSource);

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) {
    return _dataSource.createMalfunctionReport(
      machineId: machineId,
      description: description,
    );
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(reportRemoteDataSourceProvider));
});
