import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';
import 'package:washer/presentation/reservation/widget/reservation_widget.dart';

class ReservationScreen extends StatefulWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationScreen({
    super.key,
    required this.laundryMachineType,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int _selectedFloor = 3;

  Map<int, List<_WasherData>> get _washersByFloor {
    final prefix = widget.laundryMachineType == LaundryMachineType.washer
        ? 'Washer'
        : 'Dryer';

    return {
      3: [
        _WasherData(
          '$prefix-3F-L1',
          ReservationState.inUse,
          finishedAt: '25.08.18. 01:24',
          room: '301호',
        ),
        _WasherData(
          '$prefix-3F-L2',
          ReservationState.reservedByMe,
          reservedAt: '25.8.18. 00:45:03',
          remainDuration: '00:02:32',
          room: '301호',
        ),
        _WasherData(
          '$prefix-3F-L3',
          ReservationState.unavailable,
        ),
        _WasherData(
          '$prefix-3F-L4',
          ReservationState.reservedByOther,
          reservedAt: '25.8.18. 00:30:15',
          remainDuration: '00:05:45',
          room: '305호',
        ),
        _WasherData('$prefix-3F-L5', ReservationState.available),
        _WasherData(
          '$prefix-3F-L6',
          ReservationState.inUse,
          finishedAt: '25.08.18. 01:24',
          room: '301호',
        ),
      ],
      4: [
        _WasherData(
          '$prefix-4F-L1',
          ReservationState.inUse,
          finishedAt: '25.08.18. 01:24',
          room: '401호',
        ),
        _WasherData('$prefix-4F-L2', ReservationState.available),
        _WasherData(
          '$prefix-4F-L3',
          ReservationState.reservedByOther,
          reservedAt: '25.8.18. 00:35:20',
          remainDuration: '00:08:15',
          room: '402호',
        ),
        _WasherData(
          '$prefix-4F-L4',
          ReservationState.reservedByOther,
          reservedAt: '25.8.18. 00:40:10',
          remainDuration: '00:12:05',
          room: '403호',
        ),
        _WasherData(
          '$prefix-4F-L5',
          ReservationState.reservedByOther,
          reservedAt: '25.8.18. 00:42:30',
          remainDuration: '00:14:25',
          room: '404호',
        ),
        _WasherData(
          '$prefix-4F-L6',
          ReservationState.inUse,
          finishedAt: '25.08.18. 01:24',
          room: '401호',
        ),
      ],
    };
  }

  List<_WasherData> get _currentWashers =>
      _washersByFloor[_selectedFloor] ?? [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.laundryMachineType.text}기 예약 현황',
          style: WasherTypography.h2(),
        ),
        AppGap.v16,
        _buildFloorSelector(),
        AppGap.v16,
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _currentWashers.length,
            separatorBuilder: (_, __) => AppGap.v24,
            itemBuilder: (_, index) => _buildWasherItem(_currentWashers[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildFloorSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildFloorChip(3),
            AppGap.h8,
            _buildFloorChip(4),
          ],
        ),
        Row(
          children: [
            Text(
              '배치도 보기',
              style: WasherTypography.body4(WasherColor.baseGray300),
            ),
            AppGap.h4,
            WasherIcon(
              type: WasherIconType.map,
              color: WasherColor.baseGray300,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloorChip(int floor) {
    final isSelected = _selectedFloor == floor;
    return GestureDetector(
      onTap: () => setState(() => _selectedFloor = floor),
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

  Widget _buildWasherItem(_WasherData data) {
    return ReservationWidget(
      laundryMachineType: widget.laundryMachineType,
      reservationState: data.state,
      machineName: data.name,
      finishedAt: data.finishedAt,
      room: data.room,
      reservedAt: data.reservedAt,
      remainDuration: data.remainDuration,
    );
  }
}

class _WasherData {
  final String name;
  final ReservationState state;
  final String? finishedAt;
  final String? room;
  final String? reservedAt;
  final String? remainDuration;

  _WasherData(
    this.name,
    this.state, {
    this.finishedAt,
    this.room,
    this.reservedAt,
    this.remainDuration,
  });
}
