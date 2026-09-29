// Claude Code PostToolUse 훅: lib/ 아래 Dart 파일의 아키텍처·파일명·중복 규칙을 검사한다.
//
// - 파일명: snake_case
// - 위치: lib/{core,features,shared}, feature 안은 data/{data_sources,models,repositories},
//   presentation/{models,providers,screens,states,widgets}
// - 레이어: UI(screens·widgets·shared/ui)는 dio·retrofit·data source·repository를 직접 import하지 않는다.
//   data는 presentation을, core(router 제외)는 features를 import하지 않는다.
// - 위젯: 한 파일에 public 위젯 하나, 클래스명은 파일명의 PascalCase
// - 중복: 같은 파일명, 같은 이름의 public 타입·provider가 lib/ 다른 곳에 이미 있으면 알린다.
//
// 수정 전(HEAD) 파일에 이미 있던 위반은 제외하고 새로 생긴 위반만 보고한다.
// 위반이 있으면 exit 2 + stderr로 Claude에게 전달한다.
//
// 전체 점검: dart .claude/hooks/check_dart_conventions.dart --all
import 'dart:convert';
import 'dart:io';

const _generatedSuffixes = ['.g.dart', '.freezed.dart'];
const _rootFiles = {'main.dart', 'firebase_options.dart', 'splash_screen.dart'};
const _featureKinds = {
  'data': {'data_sources', 'models', 'repositories'},
  'presentation': {'models', 'providers', 'screens', 'states', 'widgets'},
};
const _widgetBases =
    'StatelessWidget|StatefulWidget|ConsumerWidget|ConsumerStatefulWidget|'
    'HookWidget|HookConsumerWidget|StatefulHookConsumerWidget';

final _snakeCase = RegExp(r'^[a-z][a-z0-9_]*\.dart$');
final _publicWidget = RegExp('^class ([A-Z]\\w*) extends (?:$_widgetBases)\\b',
    multiLine: true);
final _publicType = RegExp(
    r'^(?:abstract |final |sealed |base |interface )*'
    r'(?:class|enum|mixin|typedef|extension) ([A-Z]\w*)',
    multiLine: true);
final _publicProvider =
    RegExp(r'^final ([a-z]\w*Provider)\b', multiLine: true);
final _import = RegExp(r'''^import\s+['"]([^'"]+)['"]''', multiLine: true);

Future<void> main(List<String> args) async {
  final root = _normalize(
      Platform.environment['CLAUDE_PROJECT_DIR'] ?? Directory.current.path);
  final index = _LibIndex.build(root);

  if (args.contains('--all')) {
    var count = 0;
    for (final rel in index.files) {
      final problems = _check(rel, File('$root/$rel').readAsStringSync(), index);
      for (final p in problems) {
        stdout.writeln('$rel: $p');
        count++;
      }
    }
    stdout.writeln('위반 $count건');
    exit(count == 0 ? 0 : 1);
  }

  final input = jsonDecode(await stdin.transform(utf8.decoder).join());
  final rawPath = (input['tool_response']?['filePath'] ??
      input['tool_input']?['file_path']) as String?;
  if (rawPath == null) return;

  final path = _normalize(rawPath);
  if (!path.startsWith('$root/')) return;
  final rel = path.substring(root.length + 1);
  if (!rel.startsWith('lib/') ||
      !rel.endsWith('.dart') ||
      _generatedSuffixes.any(rel.endsWith) ||
      !File(path).existsSync()) {
    return;
  }

  final current = _check(rel, File(path).readAsStringSync(), index);
  if (current.isEmpty) return;

  final before = await _headContent(root, rel);
  final existing =
      before == null ? <String>{} : _check(rel, before, index).toSet();
  final introduced = current.where((p) => !existing.contains(p)).toList();
  if (introduced.isEmpty) return;

  stderr.writeln('[$rel] 프로젝트 규칙 위반 (AGENTS.md 참고):');
  for (final p in introduced) {
    stderr.writeln('- $p');
  }
  stderr.writeln('기존 코드를 재사용하거나 규칙에 맞게 수정하세요.');
  exit(2);
}

List<String> _check(String rel, String content, _LibIndex index) {
  final problems = <String>[];
  final segments = rel.split('/');
  final name = segments.last;

  // 파일명
  if (!_snakeCase.hasMatch(name)) {
    problems.add('파일명은 snake_case여야 합니다: $name');
  }

  // 위치
  final top = segments.length > 2 ? segments[1] : null;
  if (segments.length == 2 && !_rootFiles.contains(name)) {
    problems.add('lib/ 바로 아래에는 새 파일을 두지 않습니다. core/, features/, shared/ 중 한 곳에 두세요.');
  } else if (top != null && !{'core', 'features', 'shared'}.contains(top)) {
    problems.add('lib/ 하위 폴더는 core/, features/, shared/만 사용합니다: lib/$top');
  } else if (top == 'features') {
    final layer = segments.length > 3 ? segments[3] : null;
    final kind = segments.length > 5 ? segments[4] : null;
    final kinds = _featureKinds[layer];
    if (kinds == null || kind == null || !kinds.contains(kind)) {
      problems.add('feature 파일은 data/{${_featureKinds['data']!.join(',')}} 또는 '
          'presentation/{${_featureKinds['presentation']!.join(',')}} 안에 둡니다.');
    }
  }

  // 레이어 import
  final imports = _import
      .allMatches(content)
      .map((m) => _resolveImport(rel, m.group(1)!))
      .toList();
  final isUi = rel.contains('/presentation/screens/') ||
      rel.contains('/presentation/widgets/') ||
      rel.startsWith('lib/shared/ui/');
  for (final imp in imports) {
    if (isUi &&
        (imp.startsWith('package:dio/') ||
            imp.startsWith('package:retrofit/') ||
            imp.contains('/data/data_sources/') ||
            imp.contains('/data/repositories/'))) {
      problems.add('UI는 provider만 사용합니다. 직접 import 금지: $imp');
    }
    if (rel.contains('/data/') && imp.contains('/presentation/')) {
      problems.add('data 레이어는 presentation을 import하지 않습니다: $imp');
    }
    if (rel.startsWith('lib/core/') &&
        !rel.startsWith('lib/core/router/') &&
        imp.startsWith('package:washer/features/')) {
      problems.add('core는 features를 import하지 않습니다: $imp');
    }
  }

  // 위젯 파일 규칙
  final widgets = _publicWidget.allMatches(content).map((m) => m.group(1)!);
  if (widgets.length > 1) {
    problems.add('한 파일에 public 위젯은 하나만 둡니다: ${widgets.join(', ')}');
  }
  final expected = _pascal(name.replaceAll('.dart', ''));
  final isEntryPoint = segments.length == 2 && _rootFiles.contains(name);
  if (widgets.isNotEmpty && !isEntryPoint && !widgets.contains(expected)) {
    problems.add('위젯 클래스명은 파일명과 맞춰야 합니다: $expected (현재 ${widgets.join(', ')})');
  }

  // 중복
  final sameName = index.byBasename[name]?.where((f) => f != rel) ?? [];
  if (sameName.isNotEmpty) {
    problems.add('같은 파일명이 이미 있습니다: ${sameName.join(', ')}');
  }
  final declared = {
    ..._publicType.allMatches(content).map((m) => m.group(1)!),
    ..._publicProvider.allMatches(content).map((m) => m.group(1)!),
  };
  for (final symbol in declared) {
    final others = index.declarations[symbol]?.where((f) => f != rel) ?? [];
    if (others.isNotEmpty) {
      problems.add('$symbol 이(가) 이미 선언돼 있습니다: ${others.join(', ')} — 재사용하세요.');
    }
  }

  return problems;
}

class _LibIndex {
  _LibIndex(this.files, this.byBasename, this.declarations);

  final List<String> files;
  final Map<String, List<String>> byBasename;
  final Map<String, List<String>> declarations;

  static _LibIndex build(String root) {
    final files = <String>[];
    final byBasename = <String, List<String>>{};
    final declarations = <String, List<String>>{};
    final lib = Directory('$root/lib');
    if (!lib.existsSync()) return _LibIndex(files, byBasename, declarations);

    for (final entity in lib.listSync(recursive: true)) {
      if (entity is! File) continue;
      final path = _normalize(entity.path);
      if (!path.endsWith('.dart') || _generatedSuffixes.any(path.endsWith)) {
        continue;
      }
      final rel = path.substring(root.length + 1);
      files.add(rel);
      byBasename.putIfAbsent(rel.split('/').last, () => []).add(rel);
      final content = entity.readAsStringSync();
      for (final m in [
        ..._publicType.allMatches(content),
        ..._publicProvider.allMatches(content),
      ]) {
        declarations.putIfAbsent(m.group(1)!, () => []).add(rel);
      }
    }
    return _LibIndex(files, byBasename, declarations);
  }
}

Future<String?> _headContent(String root, String rel) async {
  try {
    final result = await Process.run('git', ['show', 'HEAD:$rel'],
        workingDirectory: root, stdoutEncoding: utf8);
    return result.exitCode == 0 ? result.stdout as String : null;
  } on ProcessException {
    return null;
  }
}

/// 상대 경로 import를 `package:washer/...` 형태로 바꿔 규칙 검사가 같은 기준으로 동작하게 한다.
String _resolveImport(String rel, String imp) {
  if (imp.contains(':')) return imp; // package:, dart: 등
  final parts = rel.split('/')..removeLast();
  for (final segment in imp.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      parts.add(segment);
    }
  }
  final resolved = parts.join('/');
  return resolved.startsWith('lib/')
      ? 'package:washer/${resolved.substring(4)}'
      : resolved;
}

String _normalize(String path) {
  var p = path.replaceAll('\\', '/');
  if (p.endsWith('/')) p = p.substring(0, p.length - 1);
  // Windows 드라이브 문자 대소문자 차이 흡수
  if (RegExp(r'^[A-Za-z]:/').hasMatch(p)) {
    p = p[0].toLowerCase() + p.substring(1);
  }
  return p;
}

String _pascal(String snake) => snake
    .split('_')
    .where((s) => s.isNotEmpty)
    .map((s) => s[0].toUpperCase() + s.substring(1))
    .join();
