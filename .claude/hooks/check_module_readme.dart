// Claude Code Stop 훅: 모듈 구조가 바뀌었는데 그 모듈의 README.md가 그대로면
// 응답을 끝내기 전에 README 갱신 여부를 확인하게 한다.
//
// 모듈: lib/features/<feature>, lib/core, lib/shared (각 폴더의 README.md)
// 구조 변경(커밋되지 않은 변경 기준, 생성 파일 제외):
// - Dart 파일 추가·삭제·이름 변경
// - feature의 data_sources/, repositories/, providers/ 파일 수정 (API·provider·흐름에 영향)
//
// 이번 턴에 Write/Edit로 수정한 모듈만 본다. 셸 명령(Bash/PowerShell)을 썼거나
// 입력에 tool_calls가 없으면 변경된 모든 모듈을 본다.
// 이미 한 번 막은 턴(stop_hook_active)에는 다시 막지 않는다.
// 확인이 필요하면 exit 2 + stderr로 Claude에게 전달한다.
import 'dart:convert';
import 'dart:io';

const _generatedSuffixes = ['.g.dart', '.freezed.dart'];
const _fileEditTools = {'Write', 'Edit', 'MultiEdit', 'NotebookEdit'};
const _shellTools = {'Bash', 'PowerShell'};
const _featureFlowDirs = [
  '/data/data_sources/',
  '/data/repositories/',
  '/presentation/providers/',
];

Future<void> main() async {
  final input = jsonDecode(await stdin.transform(utf8.decoder).join());
  if (input is! Map || input['stop_hook_active'] == true) return;

  final root = _normalize(
    Platform.environment['CLAUDE_PROJECT_DIR'] ?? Directory.current.path,
  );

  // 이번 턴에 수정한 모듈. null이면 전체 모듈을 본다.
  final editedModules = _editedModules(input['tool_calls'], root);
  if (editedModules != null && editedModules.isEmpty) return;

  final changes = await _gitChanges(root);
  if (changes == null) return;

  final changedReadmes = <String>{};
  final reasons = <String, List<String>>{};
  for (final change in changes) {
    final module = _moduleOf(change.path);
    if (module == null) continue;
    if (change.path == '$module/README.md') {
      changedReadmes.add(module);
      continue;
    }
    if (editedModules != null && !editedModules.contains(module)) continue;
    final reason = _structuralReason(module, change);
    if (reason != null) {
      reasons.putIfAbsent(module, () => []).add('${change.path} ($reason)');
    }
  }

  final pending =
      reasons.keys.where((m) => !changedReadmes.contains(m)).toList()..sort();
  if (pending.isEmpty) return;

  stderr.writeln(
    '모듈 구조가 바뀌었지만 README.md가 갱신되지 않았습니다 (AGENTS.md "모듈 README" 참고):',
  );
  for (final module in pending) {
    stderr.writeln('- $module/README.md');
    for (final reason in reasons[module]!) {
      stderr.writeln('    $reason');
    }
  }
  stderr.writeln(
    'README의 기능·구조·provider·API·동작 흐름·의존성에 영향이 있으면 갱신하세요. '
    '영향이 없으면 그대로 두고 끝내도 됩니다.',
  );
  exit(2);
}

/// tool_calls에서 이번 턴에 수정한 모듈을 찾는다. 판단할 수 없으면 null(전체).
Set<String>? _editedModules(Object? toolCalls, String root) {
  if (toolCalls is! List) return null;

  final modules = <String>{};
  for (final call in toolCalls) {
    if (call is! Map) continue;
    final name = call['tool_name'];
    if (_shellTools.contains(name)) return null;
    if (!_fileEditTools.contains(name)) continue;

    final toolInput = call['tool_input'];
    final rawPath = toolInput is Map
        ? (toolInput['file_path'] ?? toolInput['notebook_path'])
        : null;
    if (rawPath is! String) continue;

    final path = _normalize(rawPath);
    if (!path.startsWith('$root/')) continue;
    final module = _moduleOf(path.substring(root.length + 1));
    if (module != null) modules.add(module);
  }
  return modules;
}

/// 구조 변경이면 사유를, 아니면 null을 반환한다.
String? _structuralReason(String module, _Change change) {
  final path = change.path;
  if (!path.endsWith('.dart') || _generatedSuffixes.any(path.endsWith)) {
    return null;
  }

  final status = change.status;
  if (status == '??' || status.contains('A')) return '추가';
  if (status.contains('D')) return '삭제';
  if (status.contains('R') || status.contains('C')) return '이름 변경';

  final isFeature = module.startsWith('lib/features/');
  if (isFeature && _featureFlowDirs.any(path.contains)) return '수정';
  return null;
}

/// `lib/features/<feature>`, `lib/core`, `lib/shared` 중 [rel]이 속한 모듈.
String? _moduleOf(String rel) {
  final segments = rel.split('/');
  if (segments.length < 3 || segments[0] != 'lib') return null;
  if (segments[1] == 'core' || segments[1] == 'shared') {
    return 'lib/${segments[1]}';
  }
  if (segments[1] == 'features' && segments.length >= 4) {
    return 'lib/features/${segments[2]}';
  }
  return null;
}

/// 커밋되지 않은 변경(`git status --porcelain -z`). git을 쓸 수 없으면 null.
Future<List<_Change>?> _gitChanges(String root) async {
  final ProcessResult result;
  try {
    result = await Process.run(
      'git',
      ['status', '--porcelain=v1', '-z', '-uall'],
      workingDirectory: root,
      stdoutEncoding: utf8,
    );
  } on ProcessException {
    return null;
  }
  if (result.exitCode != 0) return null;

  final entries = (result.stdout as String).split('\x00');
  final changes = <_Change>[];
  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    if (entry.length < 4) continue;
    final status = entry.substring(0, 2);
    changes.add(_Change(status, entry.substring(3)));
    // 이름 변경·복사는 다음 항목이 원래 경로다.
    if (status.contains('R') || status.contains('C')) i++;
  }
  return changes;
}

class _Change {
  const _Change(this.status, this.path);

  final String status;
  final String path;
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
