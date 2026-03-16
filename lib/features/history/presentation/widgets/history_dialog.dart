import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/core/ui/dialog/washer_dialog.dart';
import 'package:washer/core/ui/reservation_state_widget.dart';
import 'package:washer/core/utils/date_time_formatter.dart';
import 'package:washer/features/history/data/models/machine_history_response.dart';
import 'package:washer/features/history/domain/enum/history_status_enum.dart';
import 'package:washer/features/history/presentation/viewmodels/history_view_model.dart';

class HistoryDialog extends ConsumerStatefulWidget {
  final String machineName;
  final int machineId;

  const HistoryDialog({
    super.key,
    required this.machineName,
    required this.machineId,
  });

  @override
  ConsumerState<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends ConsumerState<HistoryDialog> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(historyViewModelProvider.notifier)
          .fetchTodayHistory(widget.machineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: WasherDialog(
        title: '사용 기록',
        confirmText: '',
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGap.v16,
            Text(
              '기기명 ${widget.machineName} ${widget.machineId}',
              style: WasherTypography.body1(
                WasherColor.baseGray800,
              ),
            ),
            AppGap.v16,
            _buildContent(state),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(HistoryState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            state.errorMessage!,
            style: WasherTypography.body1(
              WasherColor.errorColor,
            ),
          ),
        ),
      );
    }

    if (state.historyList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '당일 사용 기록이 없습니다.',
            style: WasherTypography.body1(
              WasherColor.baseGray500,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: state.historyList.length,
        separatorBuilder: (_, __) => AppGap.v12,
        itemBuilder: (context, index) {
          final item = state.historyList[index];

          return _HistoryCard(
            machineName: widget.machineName,
            item: item,
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String machineName;
  final HistoryContent item;

  const _HistoryCard({
    required this.machineName,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final status = HistoryStatusX.fromString(item.status);

    final statusColor = status.color;
    final statusText = status.label;
    final timeLabel = status.timeLabel;

    final timeValue = DateTimeFormatter.formatToShortWithTime(
      status == HistoryStatus.cancelled ? item.createdAt : item.completionTime,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: WasherColor.baseGray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                machineName,
                style: WasherTypography.body1(
                  WasherColor.baseGray700,
                ),
              ),
              ReservationStateWidget(
                label: statusText,
                color: statusColor,
              ),
            ],
          ),
          AppGap.v8,
          Divider(color: WasherColor.baseGray200, height: 1),
          AppGap.v8,
          _buildInfoRow('예약호실', '${item.userRoomNumber}호'),
          AppGap.v8,
          _buildInfoRow(
            '예약시간',
            DateTimeFormatter.formatToShortWithTime(item.startTime),
          ),
          AppGap.v8,
          _buildInfoRow(timeLabel, timeValue),
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
          style: WasherTypography.body2(
            WasherColor.baseGray600,
          ),
        ),
        Text(
          value,
          style: WasherTypography.body2(
            WasherColor.baseGray500,
          ),
        ),
      ],
    );
  }
}
