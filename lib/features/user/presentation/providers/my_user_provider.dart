import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/session_generation_provider.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';

/// 내 정보 상태 Provider (앱 실행 중 유지되고 세션이 바뀌면 clear 한다)
final myUserProvider = AsyncNotifierProvider<MyUserNotifier, MyUserModel?>(
  MyUserNotifier.new,
);

class MyUserNotifier extends AsyncNotifier<MyUserModel?> {
  @override
  Future<MyUserModel?> build() async {
    ref.keepAlive();
    ref.listen(sessionGenerationProvider, (_, _) => clear());
    final session = ref.read(sessionGenerationProvider);
    bool isStale() => ref.read(sessionGenerationProvider) != session;

    // 조회 중에 세션이 바뀌었으면 이전 사용자의 결과(값·오류)를 반영하지 않고,
    // 그 사이 새 세션이 설정한 현재 값을 유지한다.
    final MyUserModel? user;
    try {
      user = await ref.read(userRemoteDataSourceProvider).getMyUser();
    } catch (_) {
      if (isStale()) return state.value;
      rethrow;
    }
    return isStale() ? state.value : user;
  }

  /// 서버에서 내 정보를 다시 조회한다.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final session = ref.read(sessionGenerationProvider);
    final result = await AsyncValue.guard(
      () => ref.read(userRemoteDataSourceProvider).getMyUser(),
    );
    if (ref.read(sessionGenerationProvider) != session) {
      return;
    }
    state = result;
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
