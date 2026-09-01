import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';

part 'alarm_data_source.g.dart';

abstract class AlarmDataSource {
  Future<AlarmListResponse> getAlarmList();
  Future<void> deleteAllNotifications();
  Future<void> registerFcmToken(String token);
  Future<void> deleteFcmToken();
}

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

class AlarmDataSourceImpl implements AlarmDataSource {
  const AlarmDataSourceImpl(this._api);

  final AlarmApiService _api;

  @override
  Future<AlarmListResponse> getAlarmList() async {
    final response = await _api.getAlarmList();
    if (response.data == null) {
      return const AlarmListResponse(data: []);
    }

    final body = castJsonMap(response.data);
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
