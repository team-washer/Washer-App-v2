import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/user/data/models/my_user_model.dart';

part 'user_remote_data_source.g.dart';

/// 사용자 API를 추상화한 데이터 소스 (내 정보 조회, 회원 탈퇴)
abstract class UserRemoteDataSource {
  Future<MyUserModel?> getMyUser();
  Future<void> withdraw();
}

/// Retrofit이 구현을 생성하는 사용자 REST API 정의
@RestApi()
abstract class UserApiService {
  factory UserApiService(Dio dio, {String baseUrl}) = _UserApiService;

  @GET('users/my')
  Future<HttpResponse<dynamic>> getMyUser();

  @DELETE('users/me')
  Future<HttpResponse<dynamic>> withdraw();
}

/// [UserApiService]를 사용하는 [UserRemoteDataSource] 구현체
class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  const UserRemoteDataSourceImpl(this._api);

  final UserApiService _api;

  @override
  /// 내 정보를 조회한다. 응답이 비었거나 404이면 null을 반환한다.
  Future<MyUserModel?> getMyUser() async {
    try {
      final response = await _api.getMyUser();
      final data = extractNullableDataMap(castJsonMap(response.data));
      if (data == null) {
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

  @override
  Future<void> withdraw() async {
    await _api.withdraw();
  }
}

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSourceImpl(UserApiService(ref.watch(dioProvider)));
});
