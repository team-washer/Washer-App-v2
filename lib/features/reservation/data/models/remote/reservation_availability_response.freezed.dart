// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation_availability_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReservationAvailabilityResponse {

/// 예약 가능 여부. 값이 없으면 막지 않는 쪽(true)으로 본다.
 bool get canReserve;/// 패널티 만료 시각. 패널티가 없으면 null.
 String? get penaltyExpiresAt;/// 호실 세탁 강제 금지 여부.
 bool get isBanned;
/// Create a copy of ReservationAvailabilityResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationAvailabilityResponseCopyWith<ReservationAvailabilityResponse> get copyWith => _$ReservationAvailabilityResponseCopyWithImpl<ReservationAvailabilityResponse>(this as ReservationAvailabilityResponse, _$identity);

  /// Serializes this ReservationAvailabilityResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationAvailabilityResponse&&(identical(other.canReserve, canReserve) || other.canReserve == canReserve)&&(identical(other.penaltyExpiresAt, penaltyExpiresAt) || other.penaltyExpiresAt == penaltyExpiresAt)&&(identical(other.isBanned, isBanned) || other.isBanned == isBanned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canReserve,penaltyExpiresAt,isBanned);

@override
String toString() {
  return 'ReservationAvailabilityResponse(canReserve: $canReserve, penaltyExpiresAt: $penaltyExpiresAt, isBanned: $isBanned)';
}


}

/// @nodoc
abstract mixin class $ReservationAvailabilityResponseCopyWith<$Res>  {
  factory $ReservationAvailabilityResponseCopyWith(ReservationAvailabilityResponse value, $Res Function(ReservationAvailabilityResponse) _then) = _$ReservationAvailabilityResponseCopyWithImpl;
@useResult
$Res call({
 bool canReserve, String? penaltyExpiresAt, bool isBanned
});




}
/// @nodoc
class _$ReservationAvailabilityResponseCopyWithImpl<$Res>
    implements $ReservationAvailabilityResponseCopyWith<$Res> {
  _$ReservationAvailabilityResponseCopyWithImpl(this._self, this._then);

  final ReservationAvailabilityResponse _self;
  final $Res Function(ReservationAvailabilityResponse) _then;

/// Create a copy of ReservationAvailabilityResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canReserve = null,Object? penaltyExpiresAt = freezed,Object? isBanned = null,}) {
  return _then(_self.copyWith(
canReserve: null == canReserve ? _self.canReserve : canReserve // ignore: cast_nullable_to_non_nullable
as bool,penaltyExpiresAt: freezed == penaltyExpiresAt ? _self.penaltyExpiresAt : penaltyExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,isBanned: null == isBanned ? _self.isBanned : isBanned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ReservationAvailabilityResponse].
extension ReservationAvailabilityResponsePatterns on ReservationAvailabilityResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReservationAvailabilityResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReservationAvailabilityResponse value)  $default,){
final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReservationAvailabilityResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool canReserve,  String? penaltyExpiresAt,  bool isBanned)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse() when $default != null:
return $default(_that.canReserve,_that.penaltyExpiresAt,_that.isBanned);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool canReserve,  String? penaltyExpiresAt,  bool isBanned)  $default,) {final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse():
return $default(_that.canReserve,_that.penaltyExpiresAt,_that.isBanned);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool canReserve,  String? penaltyExpiresAt,  bool isBanned)?  $default,) {final _that = this;
switch (_that) {
case _ReservationAvailabilityResponse() when $default != null:
return $default(_that.canReserve,_that.penaltyExpiresAt,_that.isBanned);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReservationAvailabilityResponse implements ReservationAvailabilityResponse {
  const _ReservationAvailabilityResponse({this.canReserve = true, this.penaltyExpiresAt, this.isBanned = false});
  factory _ReservationAvailabilityResponse.fromJson(Map<String, dynamic> json) => _$ReservationAvailabilityResponseFromJson(json);

/// 예약 가능 여부. 값이 없으면 막지 않는 쪽(true)으로 본다.
@override@JsonKey() final  bool canReserve;
/// 패널티 만료 시각. 패널티가 없으면 null.
@override final  String? penaltyExpiresAt;
/// 호실 세탁 강제 금지 여부.
@override@JsonKey() final  bool isBanned;

/// Create a copy of ReservationAvailabilityResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationAvailabilityResponseCopyWith<_ReservationAvailabilityResponse> get copyWith => __$ReservationAvailabilityResponseCopyWithImpl<_ReservationAvailabilityResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationAvailabilityResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationAvailabilityResponse&&(identical(other.canReserve, canReserve) || other.canReserve == canReserve)&&(identical(other.penaltyExpiresAt, penaltyExpiresAt) || other.penaltyExpiresAt == penaltyExpiresAt)&&(identical(other.isBanned, isBanned) || other.isBanned == isBanned));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,canReserve,penaltyExpiresAt,isBanned);

@override
String toString() {
  return 'ReservationAvailabilityResponse(canReserve: $canReserve, penaltyExpiresAt: $penaltyExpiresAt, isBanned: $isBanned)';
}


}

/// @nodoc
abstract mixin class _$ReservationAvailabilityResponseCopyWith<$Res> implements $ReservationAvailabilityResponseCopyWith<$Res> {
  factory _$ReservationAvailabilityResponseCopyWith(_ReservationAvailabilityResponse value, $Res Function(_ReservationAvailabilityResponse) _then) = __$ReservationAvailabilityResponseCopyWithImpl;
@override @useResult
$Res call({
 bool canReserve, String? penaltyExpiresAt, bool isBanned
});




}
/// @nodoc
class __$ReservationAvailabilityResponseCopyWithImpl<$Res>
    implements _$ReservationAvailabilityResponseCopyWith<$Res> {
  __$ReservationAvailabilityResponseCopyWithImpl(this._self, this._then);

  final _ReservationAvailabilityResponse _self;
  final $Res Function(_ReservationAvailabilityResponse) _then;

/// Create a copy of ReservationAvailabilityResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canReserve = null,Object? penaltyExpiresAt = freezed,Object? isBanned = null,}) {
  return _then(_ReservationAvailabilityResponse(
canReserve: null == canReserve ? _self.canReserve : canReserve // ignore: cast_nullable_to_non_nullable
as bool,penaltyExpiresAt: freezed == penaltyExpiresAt ? _self.penaltyExpiresAt : penaltyExpiresAt // ignore: cast_nullable_to_non_nullable
as String?,isBanned: null == isBanned ? _self.isBanned : isBanned // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
