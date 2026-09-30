import 'package:flutter/material.dart';
import 'package:washer/core/network/error.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 화면 전체에 하나만 떠 있도록 관리하는 현재 토스트.
OverlayEntry? _currentToastEntry;

/// 토스트 종류.
enum _WasherToastKind { error, success, info }

/// 사용자에게 보여줄 토스트 한 건. 종류는 factory로 구분한다.
///
/// - [WasherToast.error]: 실패 안내. 에러를 [AppException]으로 정규화해 보여준다.
/// - [WasherToast.success]: 요청 성공 안내.
/// - [WasherToast.info]: 진행 상황 등 일반 안내.
class WasherToast {
  const WasherToast._(this._kind, this._message, {AppException? error})
    : _error = error;

  factory WasherToast.error(Object? error) {
    final appException = AppException.from(error);
    return WasherToast._(
      _WasherToastKind.error,
      appException.message,
      error: appException,
    );
  }

  factory WasherToast.success(String message) =>
      WasherToast._(_WasherToastKind.success, message);

  factory WasherToast.info(String message) =>
      WasherToast._(_WasherToastKind.info, message);

  final _WasherToastKind _kind;
  final String _message;
  final AppException? _error;

  /// 앱이 스스로 취소한 요청([AppException.isCancelled])은 사용자가 조치할 오류가
  /// 아니므로 띄우지 않는다.
  bool get _isSilent => _error?.isCancelled ?? false;

  _WasherToastStyle get _style => switch (_kind) {
    _WasherToastKind.error => _WasherToastStyle.error,
    _WasherToastKind.success => _WasherToastStyle.success,
    _WasherToastKind.info => _WasherToastStyle.info,
  };
}

/// 종류별 모양과 동작.
class _WasherToastStyle {
  const _WasherToastStyle({
    required this.color,
    required this.icon,
    required this.blocksScreen,
    required this.duration,
    required this.showsContact,
  });

  /// 실패는 사용자가 반드시 읽도록 화면을 막고 오래 보여준다.
  static const error = _WasherToastStyle(
    color: WasherColor.errorColor,
    icon: WasherIconType.triangleWarning,
    blocksScreen: true,
    duration: Duration(seconds: 5),
    showsContact: true,
  );

  // TODO(design): 성공 토스트 디자인 요청 중(#362). 확정되면 색·아이콘·노출 시간·
  //  화면 차단 여부를 디자인에 맞춰 바꾼다. 디자인 시스템에 성공 색·체크 아이콘이
  //  아직 없어 임시로 브랜드 색을 쓰고 아이콘은 두지 않는다.
  static const success = _WasherToastStyle(
    color: WasherColor.mainColor500,
    icon: null,
    blocksScreen: false,
    duration: Duration(seconds: 3),
    showsContact: false,
  );

  // TODO(design): 안내 토스트 디자인 요청 중(#362). 확정되면 색·아이콘·노출 시간·
  //  화면 차단 여부를 디자인에 맞춰 바꾼다. 임시로 브랜드 색과 warningCircle을 쓴다.
  static const info = _WasherToastStyle(
    color: WasherColor.mainColor500,
    icon: WasherIconType.warningCircle,
    blocksScreen: false,
    duration: Duration(seconds: 3),
    showsContact: false,
  );

  final Color color;
  final WasherIconType? icon;

  /// true면 딤 배경으로 뒤 화면 조작을 막는다.
  final bool blocksScreen;

  /// 자동으로 닫히기까지의 시간.
  final Duration duration;

  /// 관리자 문의 안내를 함께 보여줄지 여부.
  final bool showsContact;
}

/// [BuildContext]에서 바로 토스트를 띄우는 확장.
///
/// 호출 시점의 context가 유효해야 한다(비동기 작업 이후라면 미리
/// [Overlay.of]로 [OverlayState]를 캡처해 [WasherToastOverlayExtension]을 쓴다).
extension WasherToastContextExtension on BuildContext {
  void showToast(WasherToast toast) {
    Overlay.of(this, rootOverlay: true).showToast(toast);
  }
}

/// 루트 [Overlay] 위에 토스트를 그리는 확장.
///
/// 다이얼로그를 닫은 직후처럼 호출부 context가 사라지는 상황에서도 안전하게
/// 동작한다. 새 토스트를 띄우면 이전 토스트는 교체된다.
extension WasherToastOverlayExtension on OverlayState {
  void showToast(WasherToast toast) {
    if (!mounted || toast._isSilent) return;

    _currentToastEntry?.remove();
    _currentToastEntry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _WasherToastOverlay(
        toast: toast,
        onDismiss: () {
          // 현재 토스트가 아니면 이미 교체·닫힘으로 제거된 entry다.
          // 늦게 도착한 타이머/닫기 콜백이 remove()를 두 번 부르지 않도록 무시한다.
          if (!identical(_currentToastEntry, entry)) return;
          _currentToastEntry = null;
          entry.remove();
        },
      ),
    );
    _currentToastEntry = entry;
    insert(entry);
  }
}

/// 상단에 토스트 카드를 보여주고, 노출 시간이 지나면 자동으로 닫는다.
/// 화면을 막는 종류면 딤 배경으로 뒤 화면 조작을 막는다.
class _WasherToastOverlay extends StatefulWidget {
  const _WasherToastOverlay({required this.toast, required this.onDismiss});

  final WasherToast toast;
  final VoidCallback onDismiss;

  @override
  State<_WasherToastOverlay> createState() => _WasherToastOverlayState();
}

class _WasherToastOverlayState extends State<_WasherToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: widget.toast._style.duration,
          )
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
    final card = SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 12,
        ).add(AppPadding.screenHPadding),
        child: Material(
          color: Colors.transparent,
          child: _WasherToastCard(
            toast: widget.toast,
            progress: _controller,
            onClose: widget.onDismiss,
          ),
        ),
      ),
    );

    // 화면을 막지 않는 토스트는 카드 영역만 차지해 뒤 화면을 그대로 쓸 수 있다.
    if (!widget.toast._style.blocksScreen) {
      return Positioned(top: 0, left: 0, right: 0, child: card);
    }

    return Positioned.fill(
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
          card,
        ],
      ),
    );
  }
}

class _WasherToastCard extends StatelessWidget {
  const _WasherToastCard({
    required this.toast,
    required this.progress,
    required this.onClose,
  });

  static const _contactMessage =
      '지속적으로 오류가 나올시 워셔 관리자에게 문의 주시기 바랍니다.\n(대표 관리자: 한의준, @e.jxn_2)';

  final WasherToast toast;
  final Animation<double> progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final style = toast._style;
    final error = toast._error;
    final icon = style.icon;
    final statusCode = error?.statusCode;
    final fieldErrorMessages = error?.fieldErrorMessages ?? const <String>[];
    final traceId = error?.traceId;

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
                  if (icon != null)
                    WasherIcon(type: icon, size: 28, color: style.color),
                  if (statusCode != null) ...[
                    AppGap.h8,
                    Text(
                      '$statusCode',
                      style: WasherTypography.subTitle1(style.color),
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
            toast._message,
            style: WasherTypography.body1(style.color),
          ),
          // 입력 검증 오류면 어떤 값을 고쳐야 하는지 함께 보여준다.
          for (final fieldError in fieldErrorMessages) ...[
            AppGap.v4,
            Text(
              '· $fieldError',
              style: WasherTypography.body3(style.color),
            ),
          ],
          if (style.showsContact) ...[
            AppGap.v4,
            Text(
              _contactMessage,
              style: WasherTypography.body4(WasherColor.baseGray500),
            ),
          ],
          // 문의 시 서버 로그와 대조할 수 있도록 추적 ID만 보여준다(개인정보 없음).
          if (traceId != null)
            Text(
              '오류 ID: $traceId',
              style: WasherTypography.caption(WasherColor.baseGray500),
            ),
          AppGap.v10,
          _WasherToastProgressBar(progress: progress, color: style.color),
        ],
      ),
    );
  }
}

/// 자동 소멸까지 남은 시간을 보여주는 진행 바. 왼쪽부터 줄어든다.
class _WasherToastProgressBar extends StatelessWidget {
  const _WasherToastProgressBar({required this.progress, required this.color});

  final Animation<double> progress;
  final Color color;

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
              child: ColoredBox(color: color.withValues(alpha: 0.4)),
            ),
            AnimatedBuilder(
              animation: progress,
              builder: (_, _) => Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1 - progress.value,
                  child: ColoredBox(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
