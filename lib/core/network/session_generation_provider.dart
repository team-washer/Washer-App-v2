import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/auth_notifier.dart';

/// 로그인 세션 세대. 세션이 끝나거나(로그아웃·탈퇴·강제 로그아웃) 새로 시작될 때마다
/// 1씩 오른다.
///
/// 사용자별 상태를 가진 provider는 이 값이 바뀌면 이전 사용자의 캐시·로드 플래그를
/// 비우고, 요청을 시작할 때의 세대와 응답이 도착했을 때의 세대가 다르면 그 응답을
/// 반영하지 않는다(#317).
class SessionGenerationNotifier extends Notifier<int> {
  @override
  int build() {
    // 세션 종료 경로는 모두 authNotifier.logout()을 거친다.
    authNotifier.addListener(advance);
    ref.onDispose(() => authNotifier.removeListener(advance));
    return 0;
  }

  /// 세션 경계를 표시한다. 이전 세션의 캐시와 진행 중인 요청의 응답은 무효가 된다.
  void advance() => state = state + 1;
}

final sessionGenerationProvider =
    NotifierProvider<SessionGenerationNotifier, int>(
      SessionGenerationNotifier.new,
    );
