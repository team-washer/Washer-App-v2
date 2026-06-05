import 'package:flutter/material.dart';

/// 비동기 작업이 진행되는 동안 화면 위에 로딩 인디케이터를 표시합니다.
///
/// 라우트가 아닌 루트 [Overlay] 위에 그려지므로, 다이얼로그를 닫은 직후처럼
/// 호출부 컨텍스트가 사라지는 상황에서도 안전하게 동작합니다.
Future<T> showLoadingWhile<T>(
  BuildContext context,
  Future<T> Function() action,
) {
  return runWithLoadingOverlay(
    Overlay.of(context, rootOverlay: true),
    action,
  );
}

/// 미리 확보한 [OverlayState] 위에서 인디케이터를 표시하며 작업을 수행합니다.
///
/// 다이얼로그를 먼저 닫은 뒤 작업을 이어가는 경우, 닫기 전에 루트 오버레이를
/// 캡처해 두고 이 함수에 넘기면 됩니다.
Future<T> runWithLoadingOverlay<T>(
  OverlayState overlay,
  Future<T> Function() action,
) async {
  final entry = OverlayEntry(
    builder: (_) => const _LoadingOverlay(),
  );
  overlay.insert(entry);
  try {
    return await action();
  } finally {
    entry.remove();
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: ColoredBox(
        color: Color(0x66000000),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
