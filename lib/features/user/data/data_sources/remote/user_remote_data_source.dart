import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';

part 'user_remote_data_source.g.dart';

abstract class UserRemoteDataSource {
  Future<MyUserModel?> getMyUser();
  Future<void> withdraw();
}

@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio, {String baseUrl}) = _UserApiService;

  @GET('/api/v2/users/my')
  Future<HttpResponse<dynamic>> getMyUser();

  @DELETE('/api/v2/users/me')
  Future<HttpResponse<dynamic>> withdraw();
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  const UserRemoteDataSourceImpl(this._api);

  final UserApiService _api;

  @override
  Future<MyUserModel?> getMyUser() async {
    try {
      final response = await _api.getMyUser();
      final data = extractNullableDataMap(castJsonMap(response.data));
      if (data == null) {
        return null;
      }

      return runInBackground(() => MyUserModel.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> withdraw() async {
    await _api.withdraw();
  }
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(UserApiService(ref.watch(dioProvider)));
});
