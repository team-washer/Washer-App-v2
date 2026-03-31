import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/core/utils/background_task.dart';
import 'package:washer/features/alarm/data/models/response/alarm_list_response.dart';

part 'alarm_data_source.g.dart';

abstract class AlarmDataSource {
  Future<AlarmListResponse> getAlarmList();
}

@RestApi()
abstract class AlarmApiService {
  factory AlarmApiService(Dio dio, {String baseUrl}) = _AlarmApiService;

  @GET('/api/v2/notifications')
  Future<HttpResponse<dynamic>> getAlarmList();
}

class AlarmDataSourceImpl implements AlarmDataSource {
  const AlarmDataSourceImpl(this._api);

  final AlarmApiService _api;

  @override
  Future<AlarmListResponse> getAlarmList() async {
    final response = await _api.getAlarmList();
    final data = extractDataMap(castJsonMap(response.data));

    return runInBackground(() => AlarmListResponse.fromJson(data));
  }
}

final alarmDataSourceProvider = Provider<AlarmDataSource>((ref) {
  return AlarmDataSourceImpl(AlarmApiService(ref.watch(dioProvider)));
});
