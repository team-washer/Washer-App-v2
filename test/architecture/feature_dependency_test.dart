import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// feature 간 의존 방향을 검사한다. 순환 의존이 생기면 실패한다.
///
/// 규칙
/// - feature 사이의 import는 비순환(DAG)이어야 한다.
/// - report는 다른 feature를 import하지 않는 leaf다. (reservation이 report를 쓴다)
/// - shared는 report를 import하지 않는다.
final _featureImport = RegExp(
  r'''import\s+['"]package:washer/features/(\w+)/''',
);

/// `lib/features/<from>` 안의 파일이 import하는 다른 feature 그래프.
Map<String, Set<String>> _featureGraph() {
  final graph = <String, Set<String>>{};
  final root = Directory('lib/features');

  for (final featureDir in root.listSync().whereType<Directory>()) {
    final from = featureDir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final targets = graph.putIfAbsent(from, () => <String>{});

    final files = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      for (final match in _featureImport.allMatches(file.readAsStringSync())) {
        final to = match.group(1)!;
        if (to != from) {
          targets.add(to);
        }
      }
    }
  }
  return graph;
}

/// 그래프의 순환 하나를 찾아 경로로 반환한다. 없으면 null.
List<String>? _findCycle(Map<String, Set<String>> graph) {
  final visiting = <String>[];
  final done = <String>{};

  List<String>? visit(String node) {
    final index = visiting.indexOf(node);
    if (index >= 0) {
      return [...visiting.sublist(index), node];
    }
    if (done.contains(node)) {
      return null;
    }

    visiting.add(node);
    for (final next in graph[node] ?? const <String>{}) {
      final cycle = visit(next);
      if (cycle != null) {
        return cycle;
      }
    }
    visiting.removeLast();
    done.add(node);
    return null;
  }

  for (final node in graph.keys) {
    final cycle = visit(node);
    if (cycle != null) {
      return cycle;
    }
  }
  return null;
}

void main() {
  final graph = _featureGraph();

  test('feature 간 순환 의존이 없다', () {
    final cycle = _findCycle(graph);

    expect(
      cycle,
      isNull,
      reason: '순환 의존: ${cycle?.join(' -> ')}',
    );
  });

  test('report는 다른 feature를 import하지 않는다', () {
    expect(graph['report'], isEmpty);
  });

  test('shared는 report feature를 import하지 않는다', () {
    final offenders = Directory('lib/shared')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.readAsStringSync().contains(
            'package:washer/features/report/',
          ),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('순환 탐지기가 실제 순환을 잡아낸다', () {
    final cycle = _findCycle({
      'a': {'b'},
      'b': {'c'},
      'c': {'a'},
    });

    expect(cycle, ['a', 'b', 'c', 'a']);
  });
}
