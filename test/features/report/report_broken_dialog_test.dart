import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/report/data/data_sources/remote/report_remote_data_source.dart';
import 'package:washer/features/report/presentation/widgets/report_broken_dialog.dart';

class _FakeReportRemoteDataSource implements ReportRemoteDataSource {
  _FakeReportRemoteDataSource({this.error});

  final Object? error;
  String? lastDescription;

  @override
  Future<void> createMalfunctionReport({
    required int machineId,
    required String description,
  }) async {
    lastDescription = description;
    final nextError = error;
    if (nextError != null) {
      throw nextError;
    }
  }
}

/// 버튼을 눌러 [ReportBrokenDialog]를 여는 화면을 띄운다.
Future<void> _pumpAndOpenDialog(
  WidgetTester tester, {
  required ReportRemoteDataSource dataSource,
  required VoidCallback onReported,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportRemoteDataSourceProvider.overrideWith((ref) => dataSource),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 917),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(
                    child: ReportBrokenDialog(
                      machineId: 1,
                      deviceId: 'Washer-3F-L1',
                      onReported: onReported,
                    ),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  group('ReportBrokenDialog onReported', () {
    testWidgets('신고가 접수되면 호출한 쪽이 넘긴 콜백이 실행된다', (tester) async {
      final dataSource = _FakeReportRemoteDataSource();
      var reportedCount = 0;
      await _pumpAndOpenDialog(
        tester,
        dataSource: dataSource,
        onReported: () => reportedCount += 1,
      );

      await tester.enterText(find.byType(TextField), '물이 새요');
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      expect(dataSource.lastDescription, '물이 새요');
      expect(reportedCount, 1);
    });

    testWidgets('신고가 실패하면 콜백을 실행하지 않는다', (tester) async {
      final dataSource = _FakeReportRemoteDataSource(
        error: DioException(
          requestOptions: RequestOptions(path: '/malfunction-reports'),
          type: DioExceptionType.connectionError,
        ),
      );
      var reportedCount = 0;
      await _pumpAndOpenDialog(
        tester,
        dataSource: dataSource,
        onReported: () => reportedCount += 1,
      );

      await tester.enterText(find.byType(TextField), '물이 새요');
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      expect(dataSource.lastDescription, '물이 새요');
      expect(reportedCount, 0);
    });

    testWidgets('내용이 비어 있으면 요청도 콜백도 없다', (tester) async {
      final dataSource = _FakeReportRemoteDataSource();
      var reportedCount = 0;
      await _pumpAndOpenDialog(
        tester,
        dataSource: dataSource,
        onReported: () => reportedCount += 1,
      );

      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      expect(dataSource.lastDescription, isNull);
      expect(reportedCount, 0);
    });
  });
}
