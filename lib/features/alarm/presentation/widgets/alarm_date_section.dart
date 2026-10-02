import 'package:flutter/material.dart';
import 'package:washer/features/alarm/data/models/alarm_type.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_dot.dart';

/// 화면 표시용으로 가공된 알람 항목 (시간은 포맷된 문자열)
class AlarmDisplayItem {
  final AlarmType status;
  final String time;
  final String description;
  final DateTime? createdAt;

  const AlarmDisplayItem({
    required this.status,
    required this.time,
    required this.description,
    required this.createdAt,
  });
}

/// 특정 날짜의 알람 섹션 위젯 - 날짜 구분선과 알람 카드 나열
class AlarmDateSection extends StatelessWidget {
  final String date;
  final List<AlarmDisplayItem> alarms;

  const AlarmDateSection({super.key, required this.date, required this.alarms});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlarmDateDivider(date: date),
        AppGap.v8,
        ...alarms.map(
          (alarm) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.contentPadding),
            child: _AlarmCard(
              alarmType: alarm.status,
              date: alarm.time,
              descriptionText: alarm.description,
            ),
          ),
        ),
      ],
    );
  }
}

/// 날짜 텍스트를 가운데 두고 양옆에 선을 그려 알람 그룹을 구분하는 위젯
class _AlarmDateDivider extends StatelessWidget {
  final String date;

  const _AlarmDateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              date,
              style: WasherTypography.body4(WasherColor.baseGray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: WasherColor.baseGray500, thickness: 1),
        ),
      ],
    );
  }
}

/// 알람 한 건을 카드 형태로 표시하는 위젯
///
/// 기능:
/// - 알람 종류별 제목 표시 (완료 알람은 파란 점 추가)
/// - 날짜 및 설명 표시
class _AlarmCard extends StatelessWidget {
  final AlarmType alarmType;
  final String date;
  final String descriptionText;

  const _AlarmCard({
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
