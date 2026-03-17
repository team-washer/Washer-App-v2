import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';

abstract class UserRepository {
  Future<MyUserModel?> getMyUser();
}

class UserRepositoryImpl implements UserRepository {
  const UserRepositoryImpl(this._dataSource);

  final UserRemoteDataSource _dataSource;

  @override
  Future<MyUserModel?> getMyUser() {
    return _dataSource.getMyUser();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(userRemoteDataSourceProvider));
});
