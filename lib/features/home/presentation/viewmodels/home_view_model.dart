import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/home/data/repositories/home_repository.dart';
import 'package:washer/features/reservation/data/models/laundry_machine_model.dart';

final machineStatusProvider =
    AsyncNotifierProvider<MachineStatusNotifier, MachineStatusResponse>(
  MachineStatusNotifier.new,
);

class MachineStatusNotifier extends AsyncNotifier<MachineStatusResponse> {
  @override
  Future<MachineStatusResponse> build() {
    return ref.read(homeRepositoryProvider).getMachineStatus();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).getMachineStatus(),
    );
  }
}
