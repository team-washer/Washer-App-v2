part of '../reservation_list_widget.dart';

class _MachineData {
  final String name;
  final ReservationState state;
  final String? finishedAt;
  final String? room;
  final String? reservedAt;
  final String? remainDuration;

  _MachineData(
    this.name,
    this.state, {
    this.finishedAt,
    this.room,
    this.reservedAt,
    this.remainDuration,
  });
}
