import 'package:flutter/material.dart';
import 'package:washer/shared/theme/color.dart';
import 'package:washer/shared/theme/spacing.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';

/// 앱이 최신 버전이 아닐 때 초기 진입에서 강제로 노출되는 업데이트 팝업.
///
/// 선택지는 "업데이트 하기" 단 하나이며, 바깥 영역 탭이나
/// 뒤로가기로 닫을 수 없다.
class ForceUpdateDialog extends StatelessWidget {
  const ForceUpdateDialog({super.key, required this.onUpdatePressed});

  final VoidCallback onUpdatePressed;

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
          onBackPressed: onUpdatePressed,
          content: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.v16),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
