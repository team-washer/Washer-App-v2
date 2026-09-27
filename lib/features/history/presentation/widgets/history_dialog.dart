import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/shared/ui/error_toast.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';
import 'package:washer/shared/ui/dialog/washer_dialog.dart';
import 'package:washer/features/history/presentation/states/history_state.dart';
import 'package:washer/features/history/presentation/providers/history_provider.dart';
import 'package:washer/features/history/presentation/widgets/history_card.dart';

/// 기기의 당일 사용 기록을 보여주는 다이얼로그
class HistoryDialog extends ConsumerStatefulWidget {
  const HistoryDialog({
    super.key,
    required this.machineName,
    required this.machineId,
  });

  final String machineName;
  final int machineId;

  @override
  ConsumerState<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends ConsumerState<HistoryDialog> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).fetchTodayHistory(widget.machineId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Object?>(historyErrorProvider, (previous, next) {
      if (next != null) {
        context.showErrorToast(next);
      }
    });

    final state = ref.watch(historyProvider);

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
              style: WasherTypography.body1(WasherColor.baseGray800),
            ),
            AppGap.v16,
            _buildContent(state),
            AppGap.v16,
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
      return const SizedBox.shrink();
    }

    if (state.historyList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            '당일 사용 기록이 없습니다.',
            style: WasherTypography.body1(WasherColor.baseGray500),
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

          return HistoryCard(
            machineName: widget.machineName,
            item: item,
          );
        },
      ),
    );
  }
}
