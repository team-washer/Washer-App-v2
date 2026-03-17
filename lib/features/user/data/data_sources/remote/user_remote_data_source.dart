import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';

abstract class UserRemoteDataSource {
  Future<MyUserModel?> getMyUser();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  const UserRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<MyUserModel?> getMyUser() async {
    try {
      final response = await _client.get('/api/v2/users/my');
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return MyUserModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(ref.watch(dioClientProvider));
});
