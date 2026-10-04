import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/presentation/widgets/history_dialog.dart';
import 'package:washer/shared/theme/washer_error_message.dart';

import 'controlled_history_data_source.dart';

Widget _app(ControlledHistoryDataSource dataSource, Widget child) {
  return ProviderScope(
    overrides: [historyRemoteDataSourceProvider.overrideWithValue(dataSource)],
    child: ScreenUtilInit(
      designSize: const Size(412, 917),
      builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

/// [HistoryDialog]를 띄우고, 다이얼로그의 post-frame 콜백이 실행되기 전에
/// 같은 프레임 안에서 바로 제거한다(열자마자 닫는 상황).
class _OpenThenCloseHost extends StatefulWidget {
  const _OpenThenCloseHost();

  @override
  State<_OpenThenCloseHost> createState() => _OpenThenCloseHostState();
}

class _OpenThenCloseHostState extends State<_OpenThenCloseHost> {
  bool _showDialog = true;

  @override
  Widget build(BuildContext context) {
    if (_showDialog) {
      // 자식인 다이얼로그보다 먼저 등록되므로 다이얼로그 콜백보다 먼저 실행된다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _showDialog = false);
        final binding = WidgetsBinding.instance;
        binding.buildOwner!.buildScope(binding.rootElement!);
        binding.buildOwner!.finalizeTree();
      });
    }

    return _showDialog
        ? const HistoryDialog(machineName: 'Washer-3F-L1', machineId: 1)
        : const SizedBox.shrink();
  }
}

const _emptyMessage = '당일 사용 기록이 없습니다.';

Future<ControlledHistoryDataSource> _pumpDialog(WidgetTester tester) async {
  final dataSource = ControlledHistoryDataSource();
  await tester.pumpWidget(
    _app(
      dataSource,
      const HistoryDialog(machineName: 'Washer-3F-L1', machineId: 1),
    ),
  );
  return dataSource;
}

void main() {
  group('HistoryDialog 조회 시작', () {
    testWidgets('정상적으로 열면 해당 기기의 기록을 조회한다', (tester) async {
      final dataSource = ControlledHistoryDataSource();
      await tester.pumpWidget(
        _app(
          dataSource,
          const HistoryDialog(machineName: 'Washer-3F-L1', machineId: 1),
        ),
      );

      expect(dataSource.requests.map((r) => r.machineId), [1]);

      dataSource.requests.single.succeed([1]);
      await tester.pumpAndSettle();
      expect(find.text('301호'), findsOneWidget);
    });

    testWidgets('조회 콜백 전에 닫히면 조회를 시작하지 않고 오류도 없다', (tester) async {
      final dataSource = ControlledHistoryDataSource();
      await tester.pumpWidget(_app(dataSource, const _OpenThenCloseHost()));
      await tester.pump();

      expect(find.byType(HistoryDialog), findsNothing);
      expect(dataSource.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('HistoryDialog 본문 상태', () {
    testWidgets('응답 전에는 빈 기록 문구 대신 로딩을 보여준다', (tester) async {
      await _pumpDialog(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(_emptyMessage), findsNothing);
    });

    testWidgets('조회 실패 후 토스트가 사라져도 오류 안내와 재시도가 남는다', (tester) async {
      final dataSource = await _pumpDialog(tester);

      dataSource.requests.single.fail();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      expect(find.text(WasherErrorMessage.historyLoadFailed), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text(_emptyMessage), findsNothing);
    });

    testWidgets('재시도하면 다시 조회해 기록을 보여준다', (tester) async {
      final dataSource = await _pumpDialog(tester);
      dataSource.requests.single.fail();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await tester.tap(find.text('다시 시도'));
      await tester.pump();
      expect(dataSource.requests, hasLength(2));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      dataSource.requests.last.succeed([1]);
      await tester.pumpAndSettle();

      expect(find.text('301호'), findsOneWidget);
      expect(find.text(WasherErrorMessage.historyLoadFailed), findsNothing);
    });

    testWidgets('기록이 없으면 오류와 다른 빈 기록 문구를 보여준다', (tester) async {
      final dataSource = await _pumpDialog(tester);

      dataSource.requests.single.succeed([]);
      await tester.pumpAndSettle();

      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text(WasherErrorMessage.historyLoadFailed), findsNothing);
      expect(find.text('다시 시도'), findsNothing);
    });
  });
}
