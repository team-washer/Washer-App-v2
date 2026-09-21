import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';

/// 요청 경로별로 고정된 상태 코드/본문을 돌려주는 어댑터.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responses);

  /// 경로 → (상태 코드, JSON 본문 문자열 또는 null)
  final Map<String, (int, String?)> _responses;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = _responses[options.path] ?? (404, null);
    return ResponseBody.fromString(
      body ?? '',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ReservationStatusRemoteDataSourceImpl _dataSource(
  Map<String, (int, String?)> responses,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v2/'))
    ..httpClientAdapter = _StubAdapter(responses);
  return ReservationStatusRemoteDataSourceImpl(
    ReservationStatusApiService(dio),
  );
}

String _envelope(Object? data) =>
    jsonEncode({'status': 'OK', 'code': 200, 'message': '완료', 'data': data});

const _reservationJson = {
  'id': 114,
  'userId': 15,
  'userName': '이주언',
  'userRoomNumber': '420',
  'machineId': 83,
  'machineName': 'Washer-4F-L1',
  'status': 'RUNNING',
};

void main() {
  group('getMyActiveReservation (reservations/active)', () {
    test('활성 예약이 있으면 모델로 변환한다', () async {
      final source = _dataSource({
        'reservations/active': (200, _envelope(_reservationJson)),
      });

      final result = await source.getMyActiveReservation();

      expect(result?.id, 114);
      expect(result?.status, 'RUNNING');
    });

    test('서버가 data를 null로 내려주면 null을 반환한다', () async {
      final source = _dataSource({
        'reservations/active': (200, _envelope(null)),
      });

      expect(await source.getMyActiveReservation(), isNull);
    });

    test('204 응답도 없음으로 처리한다', () async {
      final source = _dataSource({'reservations/active': (204, null)});

      expect(await source.getMyActiveReservation(), isNull);
    });

    test('404는 없음이 아니라 조회 실패로 던진다', () async {
      final source = _dataSource({'reservations/active': (404, '{}')});

      expect(source.getMyActiveReservation(), throwsA(isA<DioException>()));
    });

    test('451(이용 대상이 아닌 사용자)은 활성 예약 없음으로 본다', () async {
      final source = _dataSource({'reservations/active': (451, '{}')});

      expect(await source.getMyActiveReservation(), isNull);
    });

    test('401·403·409·502·503은 그대로 던진다', () async {
      for (final code in [401, 403, 409, 502, 503]) {
        final source = _dataSource({'reservations/active': (code, '{}')});

        await expectLater(
          source.getMyActiveReservation(),
          throwsA(isA<DioException>()),
          reason: 'status $code',
        );
      }
    });
  });

  group('getActiveReservations (reservations/active/room)', () {
    test('{reservations: [...]} 형태를 목록으로 변환한다', () async {
      final source = _dataSource({
        'reservations/active/room': (
          200,
          _envelope({
            'reservations': [_reservationJson],
          }),
        ),
      });

      final result = await source.getActiveReservations();

      expect(result.map((item) => item.id), [114]);
    });

    test('data가 배열 그대로여도 목록으로 변환한다', () async {
      final source = _dataSource({
        'reservations/active/room': (200, _envelope([_reservationJson])),
      });

      final result = await source.getActiveReservations();

      expect(result.map((item) => item.id), [114]);
    });

    test('빈 배열이면 빈 목록을 반환한다', () async {
      final source = _dataSource({
        'reservations/active/room': (200, _envelope(<Object>[])),
      });

      expect(await source.getActiveReservations(), isEmpty);
    });

    // 서버 계약: 활성 예약이 없으면 200 + data.reservations [] 이다.
    test('서버 계약대로 200 + data.reservations 빈 배열이면 빈 목록이다', () async {
      final source = _dataSource({
        'reservations/active/room': (
          200,
          _envelope({'reservations': <Object>[]}),
        ),
      });

      expect(await source.getActiveReservations(), isEmpty);
    });

    test('404(사용자·예약·기기 없음)는 "없음"이 아니라 오류로 던진다', () async {
      final source = _dataSource({'reservations/active/room': (404, '{}')});

      await expectLater(
        source.getActiveReservations(),
        throwsA(isA<DioException>()),
      );
    });

    test('451(이용 대상이 아닌 사용자)은 빈 목록으로 본다', () async {
      final source = _dataSource({'reservations/active/room': (451, '{}')});

      expect(await source.getActiveReservations(), isEmpty);
    });

    test('204는 서버가 보장하지 않는 응답이지만 방어적으로 빈 목록으로 본다', () async {
      final source = _dataSource({'reservations/active/room': (204, null)});

      expect(await source.getActiveReservations(), isEmpty);
    });

    test('401·403·409·502·503은 그대로 던진다', () async {
      for (final code in [401, 403, 409, 502, 503]) {
        final source = _dataSource({'reservations/active/room': (code, '{}')});

        await expectLater(
          source.getActiveReservations(),
          throwsA(isA<DioException>()),
          reason: 'status $code',
        );
      }
    });

    test('{reservations: []} 도 빈 목록을 반환한다', () async {
      final source = _dataSource({
        'reservations/active/room': (
          200,
          _envelope({'reservations': <Object>[]}),
        ),
      });

      expect(await source.getActiveReservations(), isEmpty);
    });
  });
}
