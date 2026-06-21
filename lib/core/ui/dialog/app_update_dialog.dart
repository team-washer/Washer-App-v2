import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';

/// 서버 버전 정책에 따라 노출되는 업데이트 안내 팝업.
///
/// 권장·강제 구분 없이 업데이트가 필요하면 반드시 진행해야 하며,
/// 버튼은 "업데이트 하기" 하나뿐이고 바깥 영역 탭이나 뒤로가기로 닫을 수 없다.
class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.onUpdatePressed,
    this.message,
  });

  final VoidCallback onUpdatePressed;

  /// 서버가 내려준 사용자 안내 메시지. 없으면 기본 문구를 노출한다.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: WasherDialog(
          title: '현재 앱은 최신 버전이 아닙니다!',
          backText: '업데이트 하기',
          backColor: WasherColor.mainColor400,
          confirmText: '',
          confirmColor: WasherColor.mainColor400,
          onBackPressed: onUpdatePressed,
          onConfirmPressed: null,
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
            child: _UpdateMessage(message: message),
          ),
        ),
      ),
    );
  }
}

class _UpdateMessage extends StatelessWidget {
  const _UpdateMessage({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = (message == null || message!.isEmpty)
        ? '원활한 사용을 위해 최신 버전으로 업데이트해 주세요.'
        : message!;

    return Text(
      text,
      style: WasherTypography.body2(),
    );
  }
}
