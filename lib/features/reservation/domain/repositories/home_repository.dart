import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

abstract class HomeRepository {
  Future<MachineStatusResponse> getMachineStatus();
  Future<List<ActiveReservationModel>> getActiveReservations();
}
