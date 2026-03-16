import 'package:flutter/foundation.dart';

/// 앱 전역 인증 상태 노티파이어
///
/// GoRouter의 refreshListenable로 등록하여
/// 강제 로그아웃 시 redirect가 자동으로 재실행되도록 한다.
class AuthNotifier extends ChangeNotifier {
  void logout() => notifyListeners();
}

/// 싱글톤 인스턴스 — AuthInterceptor 와 appRouter 에서 공유
final authNotifier = AuthNotifier();
