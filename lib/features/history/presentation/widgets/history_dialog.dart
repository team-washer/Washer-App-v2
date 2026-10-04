import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/shared/ui/washer_toast.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_error_message.dart';
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
      // 콜백이 실행되기 전에 다이얼로그가 닫혔으면 조회를 시작하지 않는다.
      if (!mounted) return;
      ref.read(historyProvider(widget.machineId).notifier).fetchRecentHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = historyProvider(widget.machineId);
    ref.listen<Object?>(provider.select((state) => state.error), (
      previous,
      next,
    ) {
      if (next != null) {
        context.showToast(WasherToast.error(next));
      }
    });

    final state = ref.watch(provider);

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

    if (state.error != null) {
      return _HistoryErrorView(
        onRetry: () => ref
            .read(historyProvider(widget.machineId).notifier)
            .fetchRecentHistory(),
      );
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

/// 기록 조회 실패 시 다이얼로그 본문에 남는 오류 안내 + 재시도 버튼
class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              WasherErrorMessage.historyLoadFailed,
              style: WasherTypography.body1(WasherColor.baseGray500),
              textAlign: TextAlign.center,
            ),
            AppGap.v12,
            TextButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
