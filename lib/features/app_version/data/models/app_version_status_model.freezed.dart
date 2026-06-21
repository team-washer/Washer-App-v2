// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version_status_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppVersionStatusModel {

@JsonKey(unknownEnumValue: AppUpdateStatus.unknown) AppUpdateStatus get updateStatus; bool get updateRequired; bool get updateAvailable;@JsonKey(fromJson: _trimmedOrNull) String? get latestVersionName;@JsonKey(fromJson: _trimmedOrNull) String? get storeUrl;@JsonKey(fromJson: _trimmedOrNull) String? get updateMessage;
/// Create a copy of AppVersionStatusModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionStatusModelCopyWith<AppVersionStatusModel> get copyWith => _$AppVersionStatusModelCopyWithImpl<AppVersionStatusModel>(this as AppVersionStatusModel, _$identity);

  /// Serializes this AppVersionStatusModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionStatusModel&&(identical(other.updateStatus, updateStatus) || other.updateStatus == updateStatus)&&(identical(other.updateRequired, updateRequired) || other.updateRequired == updateRequired)&&(identical(other.updateAvailable, updateAvailable) || other.updateAvailable == updateAvailable)&&(identical(other.latestVersionName, latestVersionName) || other.latestVersionName == latestVersionName)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl)&&(identical(other.updateMessage, updateMessage) || other.updateMessage == updateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updateStatus,updateRequired,updateAvailable,latestVersionName,storeUrl,updateMessage);

@override
String toString() {
  return 'AppVersionStatusModel(updateStatus: $updateStatus, updateRequired: $updateRequired, updateAvailable: $updateAvailable, latestVersionName: $latestVersionName, storeUrl: $storeUrl, updateMessage: $updateMessage)';
}


}

/// @nodoc
abstract mixin class $AppVersionStatusModelCopyWith<$Res>  {
  factory $AppVersionStatusModelCopyWith(AppVersionStatusModel value, $Res Function(AppVersionStatusModel) _then) = _$AppVersionStatusModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: AppUpdateStatus.unknown) AppUpdateStatus updateStatus, bool updateRequired, bool updateAvailable,@JsonKey(fromJson: _trimmedOrNull) String? latestVersionName,@JsonKey(fromJson: _trimmedOrNull) String? storeUrl,@JsonKey(fromJson: _trimmedOrNull) String? updateMessage
});




}
/// @nodoc
class _$AppVersionStatusModelCopyWithImpl<$Res>
    implements $AppVersionStatusModelCopyWith<$Res> {
  _$AppVersionStatusModelCopyWithImpl(this._self, this._then);

  final AppVersionStatusModel _self;
  final $Res Function(AppVersionStatusModel) _then;

/// Create a copy of AppVersionStatusModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? updateStatus = null,Object? updateRequired = null,Object? updateAvailable = null,Object? latestVersionName = freezed,Object? storeUrl = freezed,Object? updateMessage = freezed,}) {
  return _then(_self.copyWith(
updateStatus: null == updateStatus ? _self.updateStatus : updateStatus // ignore: cast_nullable_to_non_nullable
as AppUpdateStatus,updateRequired: null == updateRequired ? _self.updateRequired : updateRequired // ignore: cast_nullable_to_non_nullable
as bool,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,latestVersionName: freezed == latestVersionName ? _self.latestVersionName : latestVersionName // ignore: cast_nullable_to_non_nullable
as String?,storeUrl: freezed == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String?,updateMessage: freezed == updateMessage ? _self.updateMessage : updateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppVersionStatusModel].
extension AppVersionStatusModelPatterns on AppVersionStatusModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionStatusModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionStatusModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionStatusModel value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionStatusModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionStatusModel value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionStatusModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: AppUpdateStatus.unknown)  AppUpdateStatus updateStatus,  bool updateRequired,  bool updateAvailable, @JsonKey(fromJson: _trimmedOrNull)  String? latestVersionName, @JsonKey(fromJson: _trimmedOrNull)  String? storeUrl, @JsonKey(fromJson: _trimmedOrNull)  String? updateMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionStatusModel() when $default != null:
return $default(_that.updateStatus,_that.updateRequired,_that.updateAvailable,_that.latestVersionName,_that.storeUrl,_that.updateMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: AppUpdateStatus.unknown)  AppUpdateStatus updateStatus,  bool updateRequired,  bool updateAvailable, @JsonKey(fromJson: _trimmedOrNull)  String? latestVersionName, @JsonKey(fromJson: _trimmedOrNull)  String? storeUrl, @JsonKey(fromJson: _trimmedOrNull)  String? updateMessage)  $default,) {final _that = this;
switch (_that) {
case _AppVersionStatusModel():
return $default(_that.updateStatus,_that.updateRequired,_that.updateAvailable,_that.latestVersionName,_that.storeUrl,_that.updateMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: AppUpdateStatus.unknown)  AppUpdateStatus updateStatus,  bool updateRequired,  bool updateAvailable, @JsonKey(fromJson: _trimmedOrNull)  String? latestVersionName, @JsonKey(fromJson: _trimmedOrNull)  String? storeUrl, @JsonKey(fromJson: _trimmedOrNull)  String? updateMessage)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionStatusModel() when $default != null:
return $default(_that.updateStatus,_that.updateRequired,_that.updateAvailable,_that.latestVersionName,_that.storeUrl,_that.updateMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppVersionStatusModel extends AppVersionStatusModel {
  const _AppVersionStatusModel({@JsonKey(unknownEnumValue: AppUpdateStatus.unknown) required this.updateStatus, this.updateRequired = false, this.updateAvailable = false, @JsonKey(fromJson: _trimmedOrNull) this.latestVersionName, @JsonKey(fromJson: _trimmedOrNull) this.storeUrl, @JsonKey(fromJson: _trimmedOrNull) this.updateMessage}): super._();
  factory _AppVersionStatusModel.fromJson(Map<String, dynamic> json) => _$AppVersionStatusModelFromJson(json);

@override@JsonKey(unknownEnumValue: AppUpdateStatus.unknown) final  AppUpdateStatus updateStatus;
@override@JsonKey() final  bool updateRequired;
@override@JsonKey() final  bool updateAvailable;
@override@JsonKey(fromJson: _trimmedOrNull) final  String? latestVersionName;
@override@JsonKey(fromJson: _trimmedOrNull) final  String? storeUrl;
@override@JsonKey(fromJson: _trimmedOrNull) final  String? updateMessage;

/// Create a copy of AppVersionStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionStatusModelCopyWith<_AppVersionStatusModel> get copyWith => __$AppVersionStatusModelCopyWithImpl<_AppVersionStatusModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppVersionStatusModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionStatusModel&&(identical(other.updateStatus, updateStatus) || other.updateStatus == updateStatus)&&(identical(other.updateRequired, updateRequired) || other.updateRequired == updateRequired)&&(identical(other.updateAvailable, updateAvailable) || other.updateAvailable == updateAvailable)&&(identical(other.latestVersionName, latestVersionName) || other.latestVersionName == latestVersionName)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl)&&(identical(other.updateMessage, updateMessage) || other.updateMessage == updateMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,updateStatus,updateRequired,updateAvailable,latestVersionName,storeUrl,updateMessage);

@override
String toString() {
  return 'AppVersionStatusModel(updateStatus: $updateStatus, updateRequired: $updateRequired, updateAvailable: $updateAvailable, latestVersionName: $latestVersionName, storeUrl: $storeUrl, updateMessage: $updateMessage)';
}


}

/// @nodoc
abstract mixin class _$AppVersionStatusModelCopyWith<$Res> implements $AppVersionStatusModelCopyWith<$Res> {
  factory _$AppVersionStatusModelCopyWith(_AppVersionStatusModel value, $Res Function(_AppVersionStatusModel) _then) = __$AppVersionStatusModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: AppUpdateStatus.unknown) AppUpdateStatus updateStatus, bool updateRequired, bool updateAvailable,@JsonKey(fromJson: _trimmedOrNull) String? latestVersionName,@JsonKey(fromJson: _trimmedOrNull) String? storeUrl,@JsonKey(fromJson: _trimmedOrNull) String? updateMessage
});




}
/// @nodoc
class __$AppVersionStatusModelCopyWithImpl<$Res>
    implements _$AppVersionStatusModelCopyWith<$Res> {
  __$AppVersionStatusModelCopyWithImpl(this._self, this._then);

  final _AppVersionStatusModel _self;
  final $Res Function(_AppVersionStatusModel) _then;

/// Create a copy of AppVersionStatusModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? updateStatus = null,Object? updateRequired = null,Object? updateAvailable = null,Object? latestVersionName = freezed,Object? storeUrl = freezed,Object? updateMessage = freezed,}) {
  return _then(_AppVersionStatusModel(
updateStatus: null == updateStatus ? _self.updateStatus : updateStatus // ignore: cast_nullable_to_non_nullable
as AppUpdateStatus,updateRequired: null == updateRequired ? _self.updateRequired : updateRequired // ignore: cast_nullable_to_non_nullable
as bool,updateAvailable: null == updateAvailable ? _self.updateAvailable : updateAvailable // ignore: cast_nullable_to_non_nullable
as bool,latestVersionName: freezed == latestVersionName ? _self.latestVersionName : latestVersionName // ignore: cast_nullable_to_non_nullable
as String?,storeUrl: freezed == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String?,updateMessage: freezed == updateMessage ? _self.updateMessage : updateMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
