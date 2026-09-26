import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:washer/features/reservation/data/data_sources/remote/reservation_status_remote_data_source.dart';
import 'package:washer/features/reservation/data/models/local/active_reservation_model.dart';
import 'package:washer/features/reservation/data/models/local/machine_model.dart';
import 'package:washer/features/reservation/data/models/remote/reservation_availability_response.dart';
import 'package:washer/features/reservation/presentation/providers/reservation_status_provider.dart';

/// 기기 현황 조회가 지정한 오류로 실패하는 fake.
class _FailingServer implements ReservationStatusRemoteDataSource {
  _FailingServer(this.error);

  final DioException error;

  @override
  Future<MachineStatusResponse> getMachineStatus() => Future.error(error);

  @override
  Future<List<ActiveReservationModel>> getActiveReservations() async =>
      const [];

  @override
  Future<ActiveReservationModel?> getMyActiveReservation() async => null;

  @override
  Future<ReservationAvailabilityResponse> getReservationAvailability() async =>
      const ReservationAvailabilityResponse();
}

DioException _serverError(int statusCode, {String? message}) {
  final options = RequestOptions(path: '/machines/status');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: {
        'status': '$statusCode',
        'code': statusCode,
        if (message != null) 'message': message,
        'data': {'errorCode': 'E_$statusCode', 'traceId': 'trace-$statusCode'},
      },
    ),
  );
}

/// [error]로 기기 현황 조회를 실패시키고, 그때 사용자에게 안내될 문구를 돌려준다.
Future<String?> _pollingMessageFor(DioException error) async {
  final container = ProviderContainer(
    // Riverpod 3는 실패한 provider를 자동 재시도해 `.future`가 오래 끝나지 않는다.
    // 실패 직후의 안내 문구를 검증하려고 재시도를 끈다.
    retry: (_, __) => null,
    overrides: [
      reservationStatusRemoteDataSourceProvider.overrideWith(
        (ref) => _FailingServer(error),
      ),
    ],
  );
  addTearDown(container.dispose);

  await expectLater(
    container.read(machineStatusProvider.future),
    throwsA(isA<DioException>()),
  );
  return container.read(pollingErrorProvider)?.message;
}

void main() {
  group('조회 실패 시 사용자 안내 문구 (서버 오류 응답 계약)', () {
    test('502는 기기 서비스 연결 실패 문구', () async {
      expect(
        await _pollingMessageFor(
          _serverError(502, message: 'SmartThings down'),
        ),
        '기기와 연결할 수 없어요.\n잠시 후 다시 시도해주세요.',
      );
    });

    test('503은 일시 장애 문구이고 서버의 기술적 메시지를 노출하지 않는다', () async {
      final message = await _pollingMessageFor(
        _serverError(503, message: 'Redis connection failed'),
      );

      expect(message, '서비스가 잠시 불안정해요.\n잠시 후 다시 시도해주세요.');
      expect(message, isNot(contains('Redis')));
    });

    test('그 밖의 5xx는 상태 코드를 함께 보여준다', () async {
      expect(
        await _pollingMessageFor(_serverError(500)),
        '서버 오류가 발생했습니다. (500)',
      );
    });

    test('403은 더 이상 조용히 실패하지 않고 안내한다', () async {
      expect(
        await _pollingMessageFor(_serverError(403)),
        '이 기능을 이용할 수 없어요.',
      );
    });

    test('404는 서버 메시지와 무관하게 고정 문구를 안내한다', () async {
      expect(
        await _pollingMessageFor(_serverError(404, message: '기기를 찾을 수 없습니다.')),
        '예약 정보를 찾을 수 없어요.\n다시 확인해주세요.',
      );
    });

    test('409는 서버 메시지와 무관하게 고정 문구를 안내한다', () async {
      expect(
        await _pollingMessageFor(_serverError(409)),
        '이미 사용이 시작된 예약은 취소할 수 없어요.',
      );
    });

    test('인증 갱신 실패로 요청이 취소된 경우에는 "네트워크 오류"로 오안내하지 않는다', () async {
      final options = RequestOptions(path: '/machines/status');

      expect(
        await _pollingMessageFor(
          DioException(
            requestOptions: options,
            type: DioExceptionType.cancel,
            error: '인증 토큰 갱신에 실패했습니다.',
          ),
        ),
        isNull,
      );
    });

    test('응답이 없는 네트워크 오류는 기존 안내를 유지한다', () async {
      final options = RequestOptions(path: '/machines/status');

      expect(
        await _pollingMessageFor(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        '서버 응답 시간이 초과되었습니다.',
      );
    });
  });
}
