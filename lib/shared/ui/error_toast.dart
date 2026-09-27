import 'package:flutter/material.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 화면 전체에 하나만 떠 있도록 관리하는 현재 토스트.
OverlayEntry? _currentErrorToastEntry;

/// [BuildContext]에서 바로 에러 토스트를 띄우는 확장.
///
/// 호출 시점의 context가 유효해야 한다(비동기 작업 이후라면 미리
/// [Overlay.of]로 [OverlayState]를 캡처해 [ErrorToastOverlayExtension]을 쓴다).
extension ErrorToastContextExtension on BuildContext {
  void showErrorToast(Object? error) {
    Overlay.of(this, rootOverlay: true).showErrorToast(error);
  }
}

/// 에러를 [AppException]으로 변환해 사용자용 토스트로 보여주는 확장.
///
/// 루트 [Overlay] 위에 그리므로, 다이얼로그를 닫은 직후처럼 호출부 context가
/// 사라지는 상황에서도 안전하게 동작한다.
extension ErrorToastOverlayExtension on OverlayState {
  void showErrorToast(Object? error) {
    if (!mounted) return;

    _currentErrorToastEntry?.remove();
    _currentErrorToastEntry = null;

    final appException = AppException.from(error);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ErrorToastOverlay(
        error: appException,
        onDismiss: () {
          // 현재 토스트가 아니면 이미 교체·닫힘으로 제거된 entry다.
          // 늦게 도착한 타이머/닫기 콜백이 remove()를 두 번 부르지 않도록 무시한다.
          if (!identical(_currentErrorToastEntry, entry)) return;
          _currentErrorToastEntry = null;
          entry.remove();
        },
      ),
    );
    _currentErrorToastEntry = entry;
    insert(entry);
  }
}

/// 화면을 어둡게 덮어 뒤 화면 조작을 막고, 상단에 에러 카드를 보여준다.
/// [_autoDismissDuration]이 지나면 자동으로 닫힌다.
class _ErrorToastOverlay extends StatefulWidget {
  const _ErrorToastOverlay({required this.error, required this.onDismiss});

  final AppException error;
  final VoidCallback onDismiss;

  @override
  State<_ErrorToastOverlay> createState() => _ErrorToastOverlayState();
}

class _ErrorToastOverlayState extends State<_ErrorToastOverlay>
    with SingleTickerProviderStateMixin {
  static const _autoDismissDuration = Duration(seconds: 5);

  static const _contactMessage =
      '지속적으로 오류가 나올시 워셔 관리자에게 문의 주시기 바랍니다.\n(대표 관리자: 한의준, @e.jxn_2)';

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: _autoDismissDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              widget.onDismiss();
            }
          })
          ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned.fill(
              // 뒤 화면 터치를 막는 딤 배경.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: ColoredBox(
                  color: WasherColor.backgroundColor.withValues(alpha: 0.7),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                ).add(AppPadding.screenHPadding),
                child: _ErrorToastCard(
                  error: widget.error,
                  contactMessage: _contactMessage,
                  progress: _controller,
                  onClose: widget.onDismiss,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorToastCard extends StatelessWidget {
  const _ErrorToastCard({
    required this.error,
    required this.contactMessage,
    required this.progress,
    required this.onClose,
  });

  final AppException error;
  final String contactMessage;
  final Animation<double> progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final statusCode = error.statusCode;

    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WasherIcon(
                    type: WasherIconType.triangleWarning,
                    size: 28,
                    color: WasherColor.errorColor,
                  ),
                  if (statusCode != null) ...[
                    AppGap.h8,
                    Text(
                      '$statusCode',
                      style: WasherTypography.subTitle1(
                        WasherColor.errorColor,
                      ),
                    ),
                  ],
                ],
              ),
              WasherIconButton(
                type: WasherIconType.cancel,
                size: 24,
                onTap: onClose,
              ),
            ],
          ),
          AppGap.v12,
          Text(
            error.message,
            style: WasherTypography.body1(WasherColor.errorColor),
          ),
          AppGap.v4,
          Text(
            contactMessage,
            style: WasherTypography.body4(WasherColor.baseGray500),
          ),
          AppGap.v10,
          _ErrorToastProgressBar(progress: progress),
        ],
      ),
    );
  }
}

/// 자동 소멸까지 남은 시간을 보여주는 진행 바. 왼쪽부터 줄어든다.
class _ErrorToastProgressBar extends StatelessWidget {
  const _ErrorToastProgressBar({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.circular,
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: WasherColor.errorColor.withValues(alpha: 0.4),
              ),
            ),
            AnimatedBuilder(
              animation: progress,
              builder: (_, _) => Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - progress.value,
                  child: const ColoredBox(color: WasherColor.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
