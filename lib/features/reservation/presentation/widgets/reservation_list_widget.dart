import 'package:flutter/material.dart';
import 'package:washer/core/enums/laundry_machine_type.dart';
import 'package:washer/core/enums/reservation_state.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_floor_selector_widget.dart';
import 'package:washer/features/reservation/presentation/widgets/reservation_widget.dart';

part 'local_widgets/machine_data.dart';

class ReservationListWidget extends StatefulWidget {
  final LaundryMachineType laundryMachineType;

  const ReservationListWidget({super.key, required this.laundryMachineType});

  @override
  State<ReservationListWidget> createState() => _ReservationListWidgetState();
}

class _ReservationListWidgetState extends State<ReservationListWidget> {
  int _selectedFloor = 3;

  static const _floors = [3, 4];

  Map<int, List<_MachineData>> _machinesByFloor(String prefix) => {
    3: [
      _MachineData(
        '$prefix-3F-L1',
        ReservationState.inUse,
        finishedAt: '25.08.18. 01:24',
        room: '301호',
      ),
      _MachineData(
        '$prefix-3F-L2',
        ReservationState.reservedByMe,
        reservedAt: '25.8.18. 00:45:03',
        remainDuration: '00:02:32',
        room: '301호',
      ),
      _MachineData('$prefix-3F-L3', ReservationState.unavailable),
      _MachineData(
        '$prefix-3F-L4',
        ReservationState.reservedByOther,
        reservedAt: '25.8.18. 00:30:15',
        remainDuration: '00:05:45',
        room: '305호',
      ),
      _MachineData('$prefix-3F-L5', ReservationState.available),
      _MachineData(
        '$prefix-3F-L6',
        ReservationState.inUse,
        finishedAt: '25.08.18. 01:24',
        room: '301호',
      ),
    ],
    4: [
      _MachineData(
        '$prefix-4F-L1',
        ReservationState.inUse,
        finishedAt: '25.08.18. 01:24',
        room: '401호',
      ),
      _MachineData('$prefix-4F-L2', ReservationState.available),
      _MachineData(
        '$prefix-4F-L3',
        ReservationState.reservedByOther,
        reservedAt: '25.8.18. 00:35:20',
        remainDuration: '00:08:15',
        room: '402호',
      ),
      _MachineData(
        '$prefix-4F-L4',
        ReservationState.reservedByOther,
        reservedAt: '25.8.18. 00:40:10',
        remainDuration: '00:12:05',
        room: '403호',
      ),
      _MachineData(
        '$prefix-4F-L5',
        ReservationState.reservedByOther,
        reservedAt: '25.8.18. 00:42:30',
        remainDuration: '00:14:25',
        room: '404호',
      ),
      _MachineData(
        '$prefix-4F-L6',
        ReservationState.inUse,
        finishedAt: '25.08.18. 01:24',
        room: '401호',
      ),
    ],
  };

  List<_MachineData> get _currentMachines {
    final prefix = widget.laundryMachineType == LaundryMachineType.washer
        ? 'Washer'
        : 'Dryer';
    return _machinesByFloor(prefix)[_selectedFloor] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReservationFloorSelectorWidget(
          selectedFloor: _selectedFloor,
          floors: _floors,
          onFloorChanged: (floor) => setState(() => _selectedFloor = floor),
        ),
        AppGap.v16,
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _currentMachines.length,
            separatorBuilder: (_, __) => AppGap.v24,
            itemBuilder: (_, index) {
              final data = _currentMachines[index];
              return ReservationWidget(
                laundryMachineType: widget.laundryMachineType,
                reservationState: data.state,
                machineName: data.name,
                finishedAt: data.finishedAt,
                room: data.room,
                reservedAt: data.reservedAt,
                remainDuration: data.remainDuration,
              );
            },
          ),
        ),
      ],
    );
  }
}
