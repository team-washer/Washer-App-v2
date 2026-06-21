// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version_status_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppVersionStatusModel _$AppVersionStatusModelFromJson(
  Map<String, dynamic> json,
) => _AppVersionStatusModel(
  updateStatus: $enumDecode(
    _$AppUpdateStatusEnumMap,
    json['updateStatus'],
    unknownValue: AppUpdateStatus.unknown,
  ),
  updateRequired: json['updateRequired'] as bool? ?? false,
  updateAvailable: json['updateAvailable'] as bool? ?? false,
  latestVersionName: _trimmedOrNull(json['latestVersionName']),
  storeUrl: _trimmedOrNull(json['storeUrl']),
  updateMessage: _trimmedOrNull(json['updateMessage']),
);

Map<String, dynamic> _$AppVersionStatusModelToJson(
  _AppVersionStatusModel instance,
) => <String, dynamic>{
  'updateStatus': _$AppUpdateStatusEnumMap[instance.updateStatus]!,
  'updateRequired': instance.updateRequired,
  'updateAvailable': instance.updateAvailable,
  'latestVersionName': instance.latestVersionName,
  'storeUrl': instance.storeUrl,
  'updateMessage': instance.updateMessage,
};

const _$AppUpdateStatusEnumMap = {
  AppUpdateStatus.supported: 'SUPPORTED',
  AppUpdateStatus.updateAvailable: 'UPDATE_AVAILABLE',
  AppUpdateStatus.updateRequired: 'UPDATE_REQUIRED',
  AppUpdateStatus.unknown: 'unknown',
};
