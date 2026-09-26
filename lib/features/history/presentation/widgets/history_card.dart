import 'package:flutter/material.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';
import 'package:washer/features/history/presentation/models/history_status.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/indicators/status_badge.dart';

/// 사용 기록 1건을 표시하는 카드 (취소는 생성 시각, 그 외는 완료 시각 기준)
class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.machineName,
    required this.item,
  });

  final String machineName;
  final HistoryContent item;

  @override
  Widget build(BuildContext context) {
    final status = HistoryStatusX.fromString(item.status);
    final rawTime = status == HistoryStatus.cancelled
        ? item.createdAt
        : item.completionTime;
    final timeValue = rawTime == null
        ? '-'
        : DateTimeFormatter.formatToShortWithTime(rawTime);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WasherColor.baseGray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  machineName,
                  style: WasherTypography.body1(WasherColor.baseGray700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge(
                label: status.label,
                color: status.color,
              ),
            ],
          ),
          AppGap.v8,
          Divider(color: WasherColor.baseGray300, height: 1),
          AppGap.v8,
          _buildInfoRow('예약 호실', '${item.userRoomNumber}호'),
          AppGap.v8,
          _buildInfoRow(
            '예약 시간',
            DateTimeFormatter.formatToShortWithTime(item.startTime),
          ),
          AppGap.v8,
          _buildInfoRow(status.timeLabel, timeValue),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WasherTypography.body2(WasherColor.baseGray600),
        ),
        AppGap.h8,
        Expanded(
          child: Text(
            value,
            style: WasherTypography.body2(WasherColor.baseGray500),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
