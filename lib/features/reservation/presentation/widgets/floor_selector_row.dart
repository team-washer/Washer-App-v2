import 'package:flutter/material.dart';
import 'package:washer/shared/theme/washer_color.dart';
import 'package:washer/shared/theme/washer_icon.dart';
import 'package:washer/shared/theme/app_spacing.dart';
import 'package:washer/shared/theme/washer_typography.dart';

/// 층 선택 칩 목록과 '배치도 보기' 버튼이 한 줄로 놓인 행.
class FloorSelectorRow extends StatelessWidget {
  const FloorSelectorRow({
    super.key,
    required this.floors,
    required this.selectedFloor,
    required this.onFloorChanged,
    this.onMapTap,
  });

  final List<int> floors;
  final int selectedFloor;
  final ValueChanged<int> onFloorChanged;
  final VoidCallback? onMapTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: floors
              .map(
                (floor) => Padding(
                  padding: EdgeInsets.only(
                    right: floor != floors.last ? AppSpacing.h8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onFloorChanged(floor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selectedFloor == floor
                            ? WasherColor.mainColor500
                            : WasherColor.baseGray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$floor층',
                        style: WasherTypography.subTitle3(
                          selectedFloor == floor
                              ? Colors.white
                              : WasherColor.baseGray800,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GestureDetector(
          onTap: onMapTap,
          child: Row(
            children: [
              Text(
                '배치도 보기',
                style: WasherTypography.body2(WasherColor.baseGray500),
              ),
              AppGap.h4,
              const WasherIcon(
                type: WasherIconType.map,
                size: 20,
                color: WasherColor.baseGray500,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
