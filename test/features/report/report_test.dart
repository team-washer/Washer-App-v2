import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';
import 'package:washer/features/report/presentation/providers/report_provider.dart';

class FakeReportRemoteDataSource implements ReportRemoteDataSource {
  FakeReportRemoteDataSource({this.error});

  final Object? error;
  int? lastMachineId;
  String? lastDescription;

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    lastMachineId = machineId;
    lastDescription = description;
    final nextError = error;
    if (nextError != null) {
      throw nextError;
    }
  }
}

void main() {
  test('고장 신고 성공 시 요청값을 전달하고 success 상태가 된다', () async {
    final dataSource = FakeReportRemoteDataSource();
    final container = ProviderContainer(
      overrides: [
        reportRemoteDataSourceProvider.overrideWith((ref) => dataSource),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(reportProvider.notifier)
        .createMalfunctionReport(machineId: 1, description: '물이 새요');

    expect(dataSource.lastMachineId, 1);
    expect(dataSource.lastDescription, '물이 새요');
    expect(result, isTrue);
    expect(container.read(reportProvider).hasValue, isTrue);
  });

  test('서버 메시지가 있으면 고장 신고 실패 메시지로 사용한다', () async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/reports'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/reports'),
        data: {'message': '이미 접수된 신고입니다.'},
      ),
    );
    final container = ProviderContainer(
      overrides: [
        reportRemoteDataSourceProvider.overrideWith(
          (ref) => FakeReportRemoteDataSource(error: error),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(reportProvider.notifier)
        .createMalfunctionReport(machineId: 1, description: '물이 새요');

    expect(result, isFalse);
    expect(
      reportErrorMessage(container.read(reportProvider).error),
      '이미 접수된 신고입니다.',
    );
  });
}
