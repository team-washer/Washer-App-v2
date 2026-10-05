// Claude Code PostToolUse 훅: 수정된 Dart 파일에 `dart format`을 적용한다.
//
// stdin으로 들어오는 훅 입력 JSON에서 파일 경로를 읽는다.
// 생성 파일(*.g.dart, *.freezed.dart)과 Dart가 아닌 파일은 건너뛴다.
// FVM이 있으면 프로젝트 고정 버전(`fvm dart`)으로, 없으면 PATH의 `dart`로 포맷한다.
//
// 포맷에 실패하면(문법 오류, FVM SDK 미설치 등) stderr + exit 2로 Claude에게 알린다.
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final input = jsonDecode(await stdin.transform(utf8.decoder).join());
  final path = (input['tool_response']?['filePath'] ??
      input['tool_input']?['file_path']) as String?;

  if (path == null ||
      !path.endsWith('.dart') ||
      path.endsWith('.g.dart') ||
      path.endsWith('.freezed.dart') ||
      !File(path).existsSync()) {
    return;
  }

  final useFvm = await _hasCommand('fvm');
  final command = useFvm ? 'fvm dart format' : 'dart format';
  final ProcessResult result;
  try {
    result = await Process.run(
      useFvm ? 'fvm' : 'dart',
      [if (useFvm) 'dart', 'format', path],
      runInShell: true,
    );
  } on ProcessException catch (e) {
    stderr.writeln('`$command` 실행 실패: ${e.message}');
    exit(2);
  }
  if (result.exitCode != 0) {
    stderr.writeln('`$command` 실패 (exit ${result.exitCode}): $path');
    stderr.write(result.stderr);
    stderr.write(result.stdout);
    exit(2);
  }
}

Future<bool> _hasCommand(String name) async {
  try {
    final result = await Process.run(
      Platform.isWindows ? 'where' : 'which',
      [name],
      runInShell: true,
    );
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
