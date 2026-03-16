import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/home/data/data_sources/remote/home_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';

abstract class HomeRepository {
  Future<MachineStatusResponse> getMachineStatus();
  Future<ActiveReservationModel?> getActiveReservation();
}

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _dataSource;

  const HomeRepositoryImpl(this._dataSource);

  @override
  Future<MachineStatusResponse> getMachineStatus() {
    return _dataSource.getMachineStatus();
  }

  @override
  Future<ActiveReservationModel?> getActiveReservation() {
    return _dataSource.getActiveReservation();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.watch(homeRemoteDataSourceProvider));
});
