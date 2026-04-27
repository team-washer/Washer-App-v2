import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';

part 'alarm_data_source.g.dart';

abstract class AlarmDataSource {
  Future<AlarmListResponse> getAlarmList();
  Future<void> registerFcmToken(String token);
  Future<void> deleteFcmToken();
}

@RestApi()
abstract class AlarmApiService {
  factory AlarmApiService(Dio dio, {String baseUrl}) = _AlarmApiService;

  @GET('/api/v2/notifications')
  Future<HttpResponse<dynamic>> getAlarmList();

  @POST('/api/v2/notifications/fcm-token')
  Future<void> registerFcmToken(@Body() Map<String, dynamic> payload);

  @DELETE('/api/v2/notifications/fcm-token')
  Future<void> deleteFcmToken();
}

class AlarmDataSourceImpl implements AlarmDataSource {
  const AlarmDataSourceImpl(this._api);

  final AlarmApiService _api;

  @override
  Future<AlarmListResponse> getAlarmList() async {
    final response = await _api.getAlarmList();
    final data = castJsonMap(response.data);

    return AlarmListResponse.fromJson(data);
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
