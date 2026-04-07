abstract class AuthRepository {
  Future<void> login({
    required String authCode,
    required String redirectUri,
  });
  Future<void> logout();
  Future<void> refresh();
}
