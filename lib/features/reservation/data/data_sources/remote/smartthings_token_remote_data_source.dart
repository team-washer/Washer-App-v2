import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:washer/core/network/api_response_parser.dart';
import 'package:washer/core/network/dio_client.dart';
import 'package:washer/features/reservation/data/models/remote/smartthings_token_model.dart';

part 'smartthings_token_remote_data_source.g.dart';

abstract class SmartThingsTokenRemoteDataSource {
  Future<SmartThingsTokenModel> getToken();
}

@RestApi()
abstract class SmartThingsTokenApiService {
  factory SmartThingsTokenApiService(Dio dio, {String baseUrl}) =
      _SmartThingsTokenApiService;

  @GET('smartthings/token')
  Future<HttpResponse<dynamic>> getToken();
}

class SmartThingsTokenRemoteDataSourceImpl
    implements SmartThingsTokenRemoteDataSource {
  const SmartThingsTokenRemoteDataSourceImpl(this._api);

  final SmartThingsTokenApiService _api;

  @override
  Future<SmartThingsTokenModel> getToken() async {
    final response = await _api.getToken();
    final body = castJsonMap(response.data);
    // 다른 엔드포인트와 동일하게 `{ data: {...} }` 봉투를 우선 처리하되,
    // 봉투 없이 DTO를 그대로 내려주는 경우도 안전하게 파싱한다.
    final data = body.containsKey('data') ? extractDataMap(body) : body;
    return SmartThingsTokenModel.fromJson(data);
  }
}

/// 발급받은 SmartThings 토큰을 메모리에 캐시하고 만료 시 자동으로 갱신한다.
///
/// 토큰은 디스크에 저장하지 않는다(단기 토큰이므로 세션 메모리로 충분).
class SmartThingsTokenStore {
  SmartThingsTokenStore(this._dataSource);

  final SmartThingsTokenRemoteDataSource _dataSource;

  /// 만료 직전에 미리 갱신하기 위한 여유 시간.
  static const Duration _expiryMargin = Duration(seconds: 30);

  SmartThingsTokenModel? _cached;
  Future<SmartThingsTokenModel>? _inflight;

  /// 유효한 액세스 토큰을 반환한다.
  ///
  /// [forceRefresh]가 true면 캐시를 무시하고 새로 발급받는다(예: 401 응답 후).
  Future<String> getAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _cached = null;
      // 주의: _inflight는 일부러 비우지 않는다. _fetch()는 항상 서버에서 새
      // 토큰을 받아오므로, 진행 중인 요청을 공유하면 병렬 401 재시도가 토큰을
      // 한 번만 발급받는다(중복 발급 방지). 완료된 요청은 이미 finally에서
      // _inflight=null로 정리된다.
    }

    final cached = _cached;
    if (cached != null && !cached.isExpiringWithin(_expiryMargin)) {
      return cached.accessToken;
    }

    // 동시 호출이 몰려도 발급 요청은 한 번만 나가도록 in-flight Future를 공유한다.
    final inflight = _inflight ??= _fetch();
    try {
      final token = await inflight;
      return token.accessToken;
    } finally {
      _inflight = null;
    }
  }

  void invalidate() {
    _cached = null;
  }

  Future<SmartThingsTokenModel> _fetch() async {
    final token = await _dataSource.getToken();
    _cached = token;
    return token;
  }
}

final smartThingsTokenRemoteDataSourceProvider =
    Provider<SmartThingsTokenRemoteDataSource>((ref) {
      return SmartThingsTokenRemoteDataSourceImpl(
        SmartThingsTokenApiService(ref.watch(dioProvider)),
      );
    });

final smartThingsTokenStoreProvider = Provider<SmartThingsTokenStore>((ref) {
  return SmartThingsTokenStore(
    ref.watch(smartThingsTokenRemoteDataSourceProvider),
  );
});
