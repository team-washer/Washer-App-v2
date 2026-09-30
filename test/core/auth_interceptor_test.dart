import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/core/env/app_environment.dart';
import 'package:washer/core/network/auth_interceptor.dart';

const _newAccess = 'new-access';
const _newRefresh = 'new-refresh';

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// 일반 API. 새 access token이 붙은 요청만 [retryStatus]로 응답하고 나머지는 401을 준다.
class _ApiAdapter implements HttpClientAdapter {
  final List<String?> authorizations = [];

  /// 새 토큰으로 재요청했을 때의 응답 코드. 200이 아니면 재요청 실패를 흉내 낸다.
  int retryStatus = 200;

  /// true면 새 토큰으로 재요청할 때 네트워크 오류로 실패한다.
  bool failRetryWithNetworkError = false;

  /// 기존 토큰으로 보낸 요청의 응답. 기본은 인증 실패(401)다.
  int rejectStatus = 401;
  Map<String, Object?> rejectBody = {'message': 'Unauthorized'};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final authorization = options.headers['Authorization'] as String?;
    authorizations.add(authorization);
    if (authorization == 'Bearer $_newAccess') {
      if (failRetryWithNetworkError) {
        throw const SocketException('Connection reset by peer');
      }
      return _json(retryStatus, {'ok': retryStatus == 200});
    }
    return _json(rejectStatus, rejectBody);
  }

  @override
  void close({bool force = false}) {}
}

/// 토큰 갱신 API. 테스트가 [respond]/[fail]을 부를 때까지 응답을 미룬다.
class _RefreshAdapter implements HttpClientAdapter {
  final List<Completer<ResponseBody>> _pending = [];
  final List<Completer<void>> _started = [Completer<void>()];

  int get calls => _pending.length;

  /// [index]번째 갱신 요청이 서버에 도착할 때까지 기다린다.
  Future<void> started(int index) {
    while (_started.length <= index) {
      _started.add(Completer<void>());
    }
    return _started[index].future;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    final completer = Completer<ResponseBody>();
    _pending.add(completer);
    final index = _pending.length - 1;
    while (_started.length <= index) {
      _started.add(Completer<void>());
    }
    _started[index].complete();
    return completer.future;
  }

  void respond(int index) => _pending[index].complete(
    _json(200, {
      'data': {'accessToken': _newAccess, 'refreshToken': _newRefresh},
    }),
  );

  void fail(int index) =>
      _pending[index].complete(_json(401, {'message': 'expired'}));

  void networkError(int index) => _pending[index].completeError(
    const SocketException('Failed host lookup'),
  );

  @override
  void close({bool force = false}) {}
}

/// 만료 시각이 이미 지난 JWT.
String _expiredJwt() {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'none'})}.${encode({'exp': 1})}.sig';
}

/// 쓰기를 테스트가 [finishWrites]를 부를 때 반영하는 저장소.
/// 플랫폼 저장소에서 쓰기가 늦게 끝나 로그아웃 삭제보다 뒤에 반영되는 상황을 흉내 낸다.
class _SlowWriteStorage extends Fake implements FlutterSecureStorage {
  _SlowWriteStorage(Map<String, String> initial) : values = {...initial};

  final Map<String, String> values;
  final List<Completer<void>> _writes = [];
  final Completer<void> _firstWriteStarted = Completer<void>();

  Future<void> get firstWriteStarted => _firstWriteStarted.future;

  bool _released = false;

  /// 대기 중인 쓰기를 반영하고, 이후 쓰기는 바로 반영한다.
  void finishWrites() {
    _released = true;
    for (final write in _writes) {
      if (!write.isCompleted) write.complete();
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (!_released) {
      final done = Completer<void>();
      _writes.add(done);
      if (!_firstWriteStarted.isCompleted) _firstWriteStarted.complete();
      await done.future;
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => {...values};
}

/// access token 읽기를 테스트가 [finishReads]를 부를 때 끝내는 저장소.
/// 저장소를 읽는 동안 세션이 바뀌는 상황을 흉내 낸다. 쓰기·삭제는 바로 반영한다.
class _SlowReadStorage extends _SlowWriteStorage {
  _SlowReadStorage(super.initial) {
    finishWrites();
  }

  final List<Completer<void>> _reads = [];
  final Completer<void> _firstReadStarted = Completer<void>();

  Future<void> get firstReadStarted => _firstReadStarted.future;

  /// 대기 중인 읽기를 끝낸다. 읽은 값은 읽기를 시작한 시점의 값이다.
  void finishReads() {
    for (final read in _reads) {
      if (!read.isCompleted) read.complete();
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    final value = values[key];
    if (key != 'access_token') return value;
    final done = Completer<void>();
    _reads.add(done);
    if (!_firstReadStarted.isCompleted) _firstReadStarted.complete();
    await done.future;
    return value;
  }
}

class _Harness {
  _Harness({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage() {
    final environment = AppEnvironment.test();
    dio = Dio(BaseOptions(baseUrl: environment.apiBaseUrl))
      ..httpClientAdapter = api;
    interceptor = AuthInterceptor(
      dio,
      this.storage,
      environment,
      onLogout: () => logoutCalls++,
      refreshDio: Dio(BaseOptions(baseUrl: environment.apiBaseUrl))
        ..httpClientAdapter = refresh,
    );
    dio.interceptors.add(interceptor);
  }

  final FlutterSecureStorage storage;
  final api = _ApiAdapter();
  final refresh = _RefreshAdapter();
  late final Dio dio;
  late final AuthInterceptor interceptor;
  int logoutCalls = 0;

  Future<Map<String, String>> tokens() => storage.readAll();

  /// 결과를 기다리지 않고 요청을 시작한다. 실패는 [DioException]으로 담는다.
  Future<Object> request() => dio
      .get<dynamic>('machines/status')
      .then<Object>((response) => response, onError: (Object e) => e);
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
    });
  });

  group('로그아웃과 진행 중인 토큰 갱신 (#279)', () {
    test('401 갱신 중 로그아웃하면 늦게 온 갱신 응답이 토큰을 저장하지 않고 재시도도 없다', () async {
      final h = _Harness();

      final pending = h.request();
      await h.refresh.started(0);

      await h.interceptor.clearCache();
      h.refresh.respond(0);
      final result = await pending;

      expect(await h.tokens(), isEmpty, reason: '로그아웃한 세션이 되살아나면 안 된다');
      expect(result, isA<DioException>());
      expect((result as DioException).response?.statusCode, 401);
      expect(h.api.authorizations, ['Bearer old-access'], reason: '재시도하지 않는다');
      expect(h.logoutCalls, 0, reason: '이미 로그아웃했으므로 다시 로그아웃하지 않는다');
    });

    test('요청 전 갱신 중 로그아웃하면 요청을 보내지 않고 토큰도 저장하지 않는다', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': _expiredJwt(),
        'refresh_token': 'old-refresh',
      });
      final h = _Harness();

      final pending = h.request();
      await h.refresh.started(0);

      await h.interceptor.clearCache();
      h.refresh.respond(0);
      final result = await pending;

      expect(await h.tokens(), isEmpty);
      expect(result, isA<DioException>());
      expect((result as DioException).type, DioExceptionType.cancel);
      expect(h.api.authorizations, isEmpty, reason: '로그아웃 뒤 API를 호출하지 않는다');
      expect(h.logoutCalls, 0);
    });

    test('이전 세션의 갱신이 끝나도 새 세션의 single-flight 갱신을 지우지 않는다', () async {
      final h = _Harness();

      final oldSession = h.request();
      await h.refresh.started(0);
      await h.interceptor.clearCache();

      // 다시 로그인해 새 토큰을 저장하고, 새 세션에서 401로 갱신이 시작된다.
      await h.storage.write(key: 'access_token', value: 'relogin-access');
      await h.storage.write(key: 'refresh_token', value: 'relogin-refresh');
      final first = h.request();
      await h.refresh.started(1);

      // 이전 세션의 갱신이 뒤늦게 끝난다.
      h.refresh.respond(0);
      await oldSession;

      // 새 세션에서 동시에 들어온 401은 진행 중인 갱신에 합류해야 한다.
      final second = h.request();
      while (h.api.authorizations.length < 3) {
        await _flush();
      }
      await _flush();
      expect(h.refresh.calls, 2, reason: '새 세션의 갱신은 한 번만 나간다');

      h.refresh.respond(1);
      expect(await first, isA<Response<dynamic>>());
      expect(await second, isA<Response<dynamic>>());
      expect(await h.tokens(), {
        'access_token': _newAccess,
        'refresh_token': _newRefresh,
      });
    });
  });

  group('토큰 저장과 로그아웃 삭제의 직렬화', () {
    test('세대 확인을 통과한 저장이 끝나기 전에 로그아웃해도 저장이 삭제보다 늦게 반영되지 않는다', () async {
      final storage = _SlowWriteStorage({
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
      });
      final h = _Harness(storage: storage);

      final pending = h.request();
      await h.refresh.started(0);
      h.refresh.respond(0);
      // 갱신 응답이 세대 확인을 통과하고 저장을 시작했다.
      await storage.firstWriteStarted;

      final logout = h.interceptor.clearCache();
      await _flush();
      storage.finishWrites();
      await logout;
      await pending;

      expect(storage.values, isEmpty, reason: '늦게 끝난 저장이 로그아웃한 세션을 되살리면 안 된다');
      expect(h.logoutCalls, 0);
    });
  });

  group('기존 갱신 동작 회귀', () {
    test('동시에 들어온 401은 한 번의 갱신으로 처리하고 새 토큰으로 재시도한다', () async {
      final h = _Harness();

      final results = [h.request(), h.request(), h.request()];
      await h.refresh.started(0);
      await _flush();
      h.refresh.respond(0);

      for (final result in await Future.wait(results)) {
        expect(result, isA<Response<dynamic>>());
      }
      expect(h.refresh.calls, 1);
      expect(await h.tokens(), {
        'access_token': _newAccess,
        'refresh_token': _newRefresh,
      });
      expect(h.logoutCalls, 0);
    });

    test('갱신이 실패하면 토큰을 지우고 로그아웃을 한 번만 호출한다', () async {
      final h = _Harness();

      final results = [h.request(), h.request()];
      await h.refresh.started(0);
      await _flush();
      h.refresh.fail(0);

      for (final result in await Future.wait(results)) {
        expect(result, isA<DioException>());
      }
      expect(await h.tokens(), isEmpty);
      expect(h.logoutCalls, 1);
    });
  });

  group('갱신 성공 여부를 먼저 확정한 뒤 재요청', () {
    for (final status in [500, 409]) {
      test('갱신 후 재요청이 $status로 실패해도 로그아웃하지 않고 그 오류를 전달한다', () async {
        final h = _Harness();
        h.api.retryStatus = status;

        final pending = h.request();
        await h.refresh.started(0);
        h.refresh.respond(0);
        final result = await pending;

        expect(result, isA<DioException>());
        expect((result as DioException).response?.statusCode, status);
        expect(h.logoutCalls, 0, reason: '재요청 실패는 인증 실패가 아니다');
        expect(await h.tokens(), {
          'access_token': _newAccess,
          'refresh_token': _newRefresh,
        }, reason: '갱신한 토큰을 지우면 안 된다');
      });
    }

    test('갱신 후 재요청이 네트워크 오류로 실패해도 로그아웃하지 않는다', () async {
      final h = _Harness();
      h.api.failRetryWithNetworkError = true;

      final pending = h.request();
      await h.refresh.started(0);
      h.refresh.respond(0);
      final result = await pending;

      expect(result, isA<DioException>());
      expect(h.logoutCalls, 0);
      expect(await h.tokens(), {
        'access_token': _newAccess,
        'refresh_token': _newRefresh,
      });
    });

    test('원인별 코드가 있는 403은 권한·정책 거부라 토큰을 갱신하지 않는다', () async {
      for (final code in [
        'FORBIDDEN',
        'ROOM_WASHING_BANNED',
        'RESERVATION_ACCESS_DENIED',
      ]) {
        final h = _Harness();
        h.api
          ..rejectStatus = 403
          ..rejectBody = {
            'message': '접근 권한이 없습니다.',
            'data': {'errorCode': code},
          };

        final result = await h.request();

        expect(result, isA<DioException>(), reason: code);
        expect((result as DioException).response?.statusCode, 403);
        expect(h.refresh.calls, 0, reason: '$code: 갱신하지 않는다');
        expect(h.logoutCalls, 0, reason: code);
        expect(await h.tokens(), {
          'access_token': 'old-access',
          'refresh_token': 'old-refresh',
        }, reason: code);
      }
    });

    test('원인별 코드가 없는 403은 구버전 인증 실패로 보고 갱신한다', () async {
      final h = _Harness();
      h.api
        ..rejectStatus = 403
        ..rejectBody = {'message': 'Forbidden'};

      final pending = h.request();
      await h.refresh.started(0);
      h.refresh.respond(0);

      expect(await pending, isA<Response<dynamic>>());
      expect(h.refresh.calls, 1);
    });

    test('갱신 자체가 네트워크 오류로 실패하면 재요청 없이 로그아웃한다', () async {
      final h = _Harness();

      final pending = h.request();
      await h.refresh.started(0);
      h.refresh.networkError(0);
      final result = await pending;

      expect(result, isA<DioException>());
      expect((result as DioException).response?.statusCode, 401);
      expect(h.api.authorizations, ['Bearer old-access'], reason: '재요청하지 않는다');
      expect(h.logoutCalls, 1);
      expect(await h.tokens(), isEmpty);
    });
  });

  group('세션 전환과 인증 캐시 (#319)', () {
    test('저장소만 지워져 캐시에 이전 토큰이 남아 있어도 새 세션의 첫 요청부터 새 토큰을 쓴다', () async {
      final h = _Harness();
      // 이전 세션의 토큰으로 요청이 성공해 메모리 캐시에 올라간 상태.
      h.api
        ..rejectStatus = 200
        ..rejectBody = {'ok': true};
      await h.request();
      // 강제 로그인 이동이 저장소만 지운 것처럼 만든다.
      await h.storage.delete(key: 'access_token');
      await h.storage.delete(key: 'refresh_token');

      await h.interceptor.startSession(
        accessToken: _newAccess,
        refreshToken: _newRefresh,
      );
      final result = await h.request();

      expect(result, isA<Response<dynamic>>());
      expect(h.api.authorizations, ['Bearer old-access', 'Bearer $_newAccess']);
      expect(await h.tokens(), {
        'access_token': _newAccess,
        'refresh_token': _newRefresh,
      });
    });

    test('세션 종료는 메모리 캐시와 저장소를 함께 정리한다', () async {
      final h = _Harness();
      h.api
        ..rejectStatus = 200
        ..rejectBody = {'ok': true};
      await h.request();

      await h.interceptor.clearCache();
      h.api.rejectStatus = 401;
      final result = await h.request();

      expect(await h.tokens(), isEmpty);
      expect(result, isA<DioException>());
      expect(h.api.authorizations, [
        'Bearer old-access',
      ], reason: '이전 토큰으로 요청하지 않는다');
    });

    test('저장소를 읽는 중에 세션이 끝나면 읽은 토큰을 캐시에 올리지 않고 요청도 보내지 않는다', () async {
      final storage = _SlowReadStorage({
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
      });
      final h = _Harness(storage: storage);

      final pending = h.request();
      await storage.firstReadStarted;
      await h.interceptor.clearCache();
      storage.finishReads();
      final result = await pending;

      expect(result, isA<DioException>());
      expect((result as DioException).type, DioExceptionType.cancel);
      expect(h.api.authorizations, isEmpty);
      expect(h.logoutCalls, 0, reason: '이미 끝난 세션을 다시 로그아웃하지 않는다');
      expect(storage.values, isEmpty);
    });

    test('저장소를 읽는 중에 새 세션이 시작되면 이전 토큰 대신 새 토큰으로 요청한다', () async {
      final storage = _SlowReadStorage({
        'access_token': 'old-access',
        'refresh_token': 'old-refresh',
      });
      final h = _Harness(storage: storage);

      final pending = h.request();
      await storage.firstReadStarted;
      await h.interceptor.startSession(
        accessToken: _newAccess,
        refreshToken: _newRefresh,
      );
      storage.finishReads();

      expect(await pending, isA<Response<dynamic>>());
      expect(h.api.authorizations, ['Bearer $_newAccess']);
    });
  });
}
