import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

class ReservationFloorSelectorWidget extends StatelessWidget {
  final int selectedFloor;
  final List<int> floors;
  final ValueChanged<int> onFloorChanged;
  final VoidCallback? onMapTap;

  const ReservationFloorSelectorWidget({
    super.key,
    required this.selectedFloor,
    required this.floors,
    required this.onFloorChanged,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: floors
              .map((floor) => Padding(
                    padding: EdgeInsets.only(
                      right: floor != floors.last ? AppSpacing.h8 : 0,
                    ),
                    child: _FloorChipWidget(
                      floor: floor,
                      isSelected: selectedFloor == floor,
                      onTap: () => onFloorChanged(floor),
                    ),
                  ))
              .toList(),
        ),
        GestureDetector(
          onTap: onMapTap,
          child: Row(
            children: [
              Text(
                '배치도 보기',
                style: WasherTypography.body4(WasherColor.baseGray300),
              ),
              AppGap.h4,
            ],
          ),
        ),
      ],
    );
  }
}

class _FloorChipWidget extends StatelessWidget {
  final int floor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloorChipWidget({
    required this.floor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? WasherColor.mainColor600
              : WasherColor.baseGray100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$floor층',
          style: WasherTypography.body4(
            isSelected ? Colors.white : WasherColor.baseGray600,
          ),
        ),
      ),
    );
  }
}
