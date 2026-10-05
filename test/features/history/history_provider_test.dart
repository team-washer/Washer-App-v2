import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/history/data/data_sources/history_remote_data_source.dart';
import 'package:washer/features/history/presentation/providers/history_provider.dart';

import 'controlled_history_data_source.dart';

void main() {
  late ControlledHistoryDataSource dataSource;
  late ProviderContainer container;

  setUp(() {
    dataSource = ControlledHistoryDataSource();
    container = ProviderContainer(
      overrides: [
        historyRemoteDataSourceProvider.overrideWithValue(dataSource),
      ],
    );
  });

  tearDown(() => container.dispose());

  List<int> historyIds(int machineId) => container
      .read(historyProvider(machineId))
      .historyList
      .map((item) => item.id)
      .toList();

  group('기기별 사용 기록 상태', () {
    for (final outcome in ['성공', '실패']) {
      test('닫힌 A 기기의 늦은 $outcome 응답은 B 기기의 기록·오류를 바꾸지 않는다', () async {
        // A 다이얼로그를 열어 조회를 시작한 뒤 응답 전에 닫는다.
        final subscriptionA = container.listen(historyProvider(1), (_, _) {});
        final fetchA = container
            .read(historyProvider(1).notifier)
            .fetchRecentHistory();
        subscriptionA.close();
        await container.pump();

        // B 다이얼로그를 열고 B 응답이 먼저 도착한다.
        container.listen(historyProvider(2), (_, _) {});
        final fetchB = container
            .read(historyProvider(2).notifier)
            .fetchRecentHistory();
        dataSource.requests[1].succeed([20]);
        await fetchB;

        // A 응답이 뒤늦게 도착한다.
        final requestA = dataSource.requests[0];
        outcome == '성공' ? requestA.succeed([10]) : requestA.fail();
        await fetchA;

        expect(dataSource.requests.map((r) => r.machineId), [1, 2]);
        expect(historyIds(2), [20]);
        expect(container.read(historyProvider(2)).error, isNull);
        expect(container.read(historyProvider(2)).isLoading, isFalse);
      });
    }

    test('열려 있는 다른 기기의 응답도 서로의 상태에 섞이지 않는다', () async {
      container.listen(historyProvider(1), (_, _) {});
      container.listen(historyProvider(2), (_, _) {});
      final fetchA = container
          .read(historyProvider(1).notifier)
          .fetchRecentHistory();
      final fetchB = container
          .read(historyProvider(2).notifier)
          .fetchRecentHistory();

      dataSource.requests[1].succeed([20]);
      dataSource.requests[0].fail();
      await Future.wait([fetchA, fetchB]);

      expect(historyIds(2), [20]);
      expect(container.read(historyProvider(2)).error, isNull);
      expect(historyIds(1), isEmpty);
      expect(container.read(historyProvider(1)).error, isNotNull);
    });

    test('같은 기기를 다시 조회하면 먼저 보낸 요청의 늦은 응답은 버린다', () async {
      container.listen(historyProvider(1), (_, _) {});
      final notifier = container.read(historyProvider(1).notifier);
      final first = notifier.fetchRecentHistory();
      final second = notifier.fetchRecentHistory();

      dataSource.requests[1].succeed([2]);
      await second;
      dataSource.requests[0].fail();
      await first;

      expect(historyIds(1), [2]);
      expect(container.read(historyProvider(1)).error, isNull);
      expect(container.read(historyProvider(1)).isLoading, isFalse);
    });
  });
}
