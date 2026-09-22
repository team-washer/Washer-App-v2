import 'package:flutter/material.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_dot.dart';

/// 알람 한 건을 카드 형태로 표시하는 위젯
///
/// 기능:
/// - 알람 종류별 제목 표시 (완료 알람은 파란 점 추가)
/// - 날짜 및 설명 표시
class AlarmCard extends StatelessWidget {
  final AlarmType alarmType;
  final String date;
  final String descriptionText;

  const AlarmCard({
    super.key,
    required this.alarmType,
    required this.date,
    required this.descriptionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        borderRadius: AppRadius.medium,
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더: 제목(+완료 표시 점)과 날짜
          Row(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        _titleFor(alarmType),
                        style: WasherTypography.subTitle3(
                          WasherColor.baseGray800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (alarmType == AlarmType.COMPLETION) ...[
                      AppGap.h4,
                      const StatusDot(color: StatusDotColor.blue),
                    ],
                  ],
                ),
              ),
              AppGap.h4,
              Text(
                date,
                style: WasherTypography.body4(WasherColor.baseGray500),
              ),
            ],
          ),
          AppGap.v8,
          Text(
            descriptionText,
            style: WasherTypography.body1(WasherColor.baseGray500),
          ),
        ],
      ),
    );
  }

  /// 알람 종류에 대응하는 카드 제목
  String _titleFor(AlarmType type) {
    switch (type) {
      case AlarmType.COMPLETION:
        return '세탁 완료';
      case AlarmType.MALFUNCTION:
        return '세탁기 이상';
      case AlarmType.WARNING:
        return '사용 경고';
      case AlarmType.INTERRUPTION:
        return '중단';
      case AlarmType.AUTO_CANCELLED:
        return '자동 취소';
      case AlarmType.PAUSE_TIMEOUT:
        return '일시정지 종료';
      case AlarmType.STARTED:
        return '시작';
      case AlarmType.TIMEOUT_WARNING:
        return '시간 초과 경고';
      case AlarmType.CANCELLATION_BLOCKED:
        return '취소 제한';
      case AlarmType.CANCELLATION_BLOCK_EXTENDED:
        return '취소 제한 연장';
      case AlarmType.FORCE_STOPPED:
        return '강제 종료';
      case AlarmType.ADMIN_PENALTY_BLOCKED:
        return '관리자 패널티';
      case AlarmType.unknown:
        return '알림';
    }
  }
}
