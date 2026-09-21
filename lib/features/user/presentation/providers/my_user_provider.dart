import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';

/// 내 정보 상태 Provider (앱 실행 중 유지되고 로그아웃/탈퇴 시 clear 한다)
final myUserProvider = AsyncNotifierProvider<MyUserNotifier, MyUserModel?>(
  MyUserNotifier.new,
);

class MyUserNotifier extends AsyncNotifier<MyUserModel?> {
  @override
  Future<MyUserModel?> build() async {
    ref.keepAlive();
    return ref.read(userRemoteDataSourceProvider).getMyUser();
  }

  /// 서버에서 내 정보를 다시 조회한다.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRemoteDataSourceProvider).getMyUser(),
    );
  }

  /// 이미 확보한 사용자 정보로 상태를 직접 갱신한다.
  void setUser(MyUserModel? user) {
    state = AsyncData(user);
  }

  /// 사용자 정보를 비운다.
  void clear() {
    state = const AsyncData(null);
  }
}
