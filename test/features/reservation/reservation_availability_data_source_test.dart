import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';

/// 고정된 상태 코드/본문을 돌려주는 어댑터.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._body);

  final Object _body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ReservationStatusRemoteDataSourceImpl _dataSource(Object body) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v2/'))
    ..httpClientAdapter = _StubAdapter(body);
  return ReservationStatusRemoteDataSourceImpl(
    ReservationStatusApiService(dio),
  );
}

void main() {
  group('getReservationAvailability (reservations/availability)', () {
    const payload = {
      'canReserve': false,
      'penaltyExpiresAt': '2026-03-12T21:30:00',
      'isBanned': false,
    };

    test('data로 감싸진 응답을 파싱한다', () async {
      final result = await _dataSource({
        'code': 200,
        'message': '완료',
        'data': payload,
      }).getReservationAvailability();

      expect(result.canReserve, isFalse);
      expect(result.penaltyExpiresAt, '2026-03-12T21:30:00');
      expect(result.isBanned, isFalse);
    });

    test('감싸지지 않은 본문도 파싱한다', () async {
      final result = await _dataSource(payload).getReservationAvailability();

      expect(result.canReserve, isFalse);
      expect(result.penaltyExpiresAt, '2026-03-12T21:30:00');
    });

    test('패널티가 없으면 penaltyExpiresAt은 null이고 예약 가능이다', () async {
      final result = await _dataSource({
        'data': {'canReserve': true, 'penaltyExpiresAt': null},
      }).getReservationAvailability();

      expect(result.canReserve, isTrue);
      expect(result.penaltyExpiresAt, isNull);
      expect(result.isBanned, isFalse);
    });

    test('필드가 없으면 막지 않는 기본값(canReserve=true)을 쓴다', () async {
      final result = await _dataSource({
        'data': <String, dynamic>{},
      }).getReservationAvailability();

      expect(result.canReserve, isTrue);
    });
  });
}
