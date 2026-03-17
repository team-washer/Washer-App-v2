import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/data/repositories/user_repository.dart';

final myUserProvider = AsyncNotifierProvider<MyUserNotifier, MyUserModel?>(
  MyUserNotifier.new,
);

class MyUserNotifier extends AsyncNotifier<MyUserModel?> {
  @override
  Future<MyUserModel?> build() async {
    ref.keepAlive();
    return ref.read(userRepositoryProvider).getMyUser();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getMyUser(),
    );
  }

  void setUser(MyUserModel? user) {
    state = AsyncData(user);
  }

  void clear() {
    state = const AsyncData(null);
  }
}
