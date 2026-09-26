import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';

part 'alarm_data_source.g.dart';

/// 알림 API 호출을 추상화한 데이터 소스 (알림 조회/삭제, FCM 토큰 등록/삭제)
abstract class AlarmDataSource {
  Future<AlarmListResponse> getAlarmList();
  Future<void> deleteAllNotifications();
  Future<void> registerFcmToken(String token);
  Future<void> deleteFcmToken();
}

/// Retrofit이 구현을 생성하는 알림 REST API 정의
@RestApi()
abstract class AlarmApiService {
  factory AlarmApiService(Dio dio, {String baseUrl}) = _AlarmApiService;

  @GET('notifications')
  Future<HttpResponse<dynamic>> getAlarmList();

  @DELETE('notifications')
  Future<void> deleteAllNotifications();

  @POST('notifications/fcm-token')
  Future<void> registerFcmToken(@Body() Map<String, dynamic> payload);

  @DELETE('notifications/fcm-token')
  Future<void> deleteFcmToken();
}

/// [AlarmApiService]를 사용하는 [AlarmDataSource] 구현체
class AlarmDataSourceImpl implements AlarmDataSource {
  const AlarmDataSourceImpl(this._api);

  final AlarmApiService _api;

  @override
  Future<AlarmListResponse> getAlarmList() async {
    final response = await _api.getAlarmList();
    // 응답 본문이 없으면 빈 목록으로 처리한다.
    if (response.data == null) {
      return const AlarmListResponse(data: []);
    }

    final body = castJsonMap(response.data);
    // 'data'로 감싼 응답과 감싸지 않은 응답을 모두 허용한다.
    final data = body.containsKey('data') ? extractDataMap(body) : body;
    return AlarmListResponse.fromJson(data);
  }

  @override
  Future<void> deleteAllNotifications() {
    return _api.deleteAllNotifications();
  }

  @override
  Future<void> registerFcmToken(String token) {
    return _api.registerFcmToken({'token': token});
  }

  @override
  Future<void> deleteFcmToken() {
    return _api.deleteFcmToken();
  }
}

final alarmDataSourceProvider = Provider<AlarmDataSource>((ref) {
  return AlarmDataSourceImpl(AlarmApiService(ref.watch(dioProvider)));
});
