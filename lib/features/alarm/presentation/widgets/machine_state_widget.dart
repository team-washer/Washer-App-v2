import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/circle_widget.dart';
import 'package:washer/features/alarm/domain/enums/alarm_type.dart';

/// 기계 상태 알람을 카드 형태로 표시하는 위젯
///
/// 기능:
/// - 알람 상태별 아이콘 표시 (완료, 에러, 경고)
/// - 날짜 및 설명 표시
class MachineStateWidget extends StatelessWidget {
  final AlarmType laundryStatus;
  final String date;
  final String descriptionText;

  const MachineStateWidget({
    super.key,
    required this.laundryStatus,
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
          _HeaderRow(laundryStatus: laundryStatus, date: date),
          AppGap.v8,
          _DescriptionText(descriptionText: descriptionText),
        ],
      ),
    );
  }
}

/// 헤더 행 (상태 및 날짜)
class _HeaderRow extends StatelessWidget {
  final AlarmType laundryStatus;
  final String date;

  const _HeaderRow({required this.laundryStatus, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TitleWithStatus(laundryStatus: laundryStatus)),
        AppGap.h4,
        _DateText(date: date),
      ],
    );
  }
}

/// 상태 텍스트 및 상태 아이콘
class _TitleWithStatus extends StatelessWidget {
  final AlarmType laundryStatus;

  const _TitleWithStatus({required this.laundryStatus});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            _titleFor(laundryStatus),
            style: WasherTypography.subTitle3(
              WasherColor.baseGray700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isCompletionStatus(laundryStatus)) ...[
          AppGap.h4,
          const CircleWidget(color: CircleColor.blue),
        ],
      ],
    );
  }

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
    }
  }

  bool _isCompletionStatus(AlarmType type) {
    switch (type) {
      case AlarmType.COMPLETION:
        return true;
      case AlarmType.MALFUNCTION:
      case AlarmType.WARNING:
      case AlarmType.INTERRUPTION:
      case AlarmType.AUTO_CANCELLED:
      case AlarmType.PAUSE_TIMEOUT:
      case AlarmType.STARTED:
        return false;
    }
  }
}

/// 날짜 텍스트 표시
class _DateText extends StatelessWidget {
  final String date;

  const _DateText({required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(
      date,
      style: WasherTypography.body4(
        WasherColor.baseGray300,
      ),
    );
  }
}

/// 날짜 및 설명 텍스트 렌더링
class _DescriptionText extends StatelessWidget {
  final String descriptionText;

  const _DescriptionText({
    required this.descriptionText,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      descriptionText,
      style: WasherTypography.body1(
        WasherColor.baseGray400,
      ),
    );
  }
}
