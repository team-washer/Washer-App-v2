import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';

enum ReservationActionStatus { idle, loading, success, error }

class ReservationActionState {
  const ReservationActionState({
    this.status = ReservationActionStatus.idle,
    this.errorMessage,
    this.reservation,
  });

  final ReservationActionStatus status;
  final String? errorMessage;
  final ActiveReservationModel? reservation;
}
