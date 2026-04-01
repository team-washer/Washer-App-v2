abstract class AuthRepository {
  Future<void> login(String code);
  Future<void> logout();
  Future<void> refresh();
}
