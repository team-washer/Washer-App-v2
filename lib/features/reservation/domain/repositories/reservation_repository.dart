import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/remote/confirm_reservation_response.dart';

abstract class ReservationRepository {
  Future<ActiveReservationModel> createReservation({
    required int machineId,
    required String startTime,
  });

  Future<void> cancelReservation({
    required int id,
  });

  Future<ConfirmReservationResponse> confirmReservation({
    required int id,
  });
}
