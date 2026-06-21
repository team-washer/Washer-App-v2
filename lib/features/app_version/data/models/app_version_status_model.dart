// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version_status_model.freezed.dart';
part 'app_version_status_model.g.dart';

/// 서버의 `GET /app-versions/status` 응답(AppVersionStatusResDto)을 표현한다.
///
/// 강제/권장 업데이트 판단은 클라이언트가 버전을 비교하지 않고
/// 전적으로 서버 응답(`updateStatus`)을 따른다.
enum AppUpdateStatus {
  /// 현재 버전으로 계속 사용 가능.
  @JsonValue('SUPPORTED')
  supported,

  /// 더 최신 버전이 있으나 강제는 아님(권장 업데이트).
  @JsonValue('UPDATE_AVAILABLE')
  updateAvailable,

  /// 최소 지원 버전 미만으로 반드시 업데이트해야 함(강제 업데이트).
  @JsonValue('UPDATE_REQUIRED')
  updateRequired,

  /// 서버가 알 수 없는 값을 내려준 경우의 안전한 기본값.
  unknown,
}

@freezed
abstract class AppVersionStatusModel with _$AppVersionStatusModel {
  const AppVersionStatusModel._();

  const factory AppVersionStatusModel({
    @JsonKey(unknownEnumValue: AppUpdateStatus.unknown)
    required AppUpdateStatus updateStatus,
    @Default(false) bool updateRequired,
    @Default(false) bool updateAvailable,
    @JsonKey(fromJson: _trimmedOrNull) String? latestVersionName,
    @JsonKey(fromJson: _trimmedOrNull) String? storeUrl,
    @JsonKey(fromJson: _trimmedOrNull) String? updateMessage,
  }) = _AppVersionStatusModel;

  /// `updateStatus`를 우선 신뢰하되, 누락 시 boolean 플래그로 보강한다.
  bool get isForceUpdate =>
      updateStatus == AppUpdateStatus.updateRequired || updateRequired;

  /// 강제는 아니지만 권장 업데이트가 있는 경우.
  bool get isOptionalUpdate =>
      !isForceUpdate &&
      (updateStatus == AppUpdateStatus.updateAvailable || updateAvailable);

  factory AppVersionStatusModel.fromJson(Map<String, dynamic> json) =>
      _$AppVersionStatusModelFromJson(json);
}

String? _trimmedOrNull(dynamic value) {
  if (value == null) {
    return null;
  }
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}
