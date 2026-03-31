import 'package:washer/features/user/data/models/my_user_model.dart';

abstract class UserRepository {
  Future<MyUserModel?> getMyUser();
  Future<void> withdraw();
}
