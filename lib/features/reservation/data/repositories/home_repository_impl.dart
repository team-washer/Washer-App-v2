import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/laundry_machine_model.dart';
import 'package:washer/features/reservation/domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _dataSource;

  const HomeRepositoryImpl(this._dataSource);

  @override
  Future<MachineStatusResponse> getMachineStatus() {
    return _dataSource.getMachineStatus();
  }

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() {
    return _dataSource.getActiveReservations();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.watch(homeRemoteDataSourceProvider));
});
