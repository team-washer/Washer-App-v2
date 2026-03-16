// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cancel_reservation_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CancelReservationResponse {

 bool get success; String get message; bool get penaltyApplied; String get penaltyExpiresAt;
/// Create a copy of CancelReservationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CancelReservationResponseCopyWith<CancelReservationResponse> get copyWith => _$CancelReservationResponseCopyWithImpl<CancelReservationResponse>(this as CancelReservationResponse, _$identity);

  /// Serializes this CancelReservationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CancelReservationResponse&&(identical(other.success, success) || other.success == success)&&(identical(other.message, message) || other.message == message)&&(identical(other.penaltyApplied, penaltyApplied) || other.penaltyApplied == penaltyApplied)&&(identical(other.penaltyExpiresAt, penaltyExpiresAt) || other.penaltyExpiresAt == penaltyExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,message,penaltyApplied,penaltyExpiresAt);

@override
String toString() {
  return 'CancelReservationResponse(success: $success, message: $message, penaltyApplied: $penaltyApplied, penaltyExpiresAt: $penaltyExpiresAt)';
}


}

/// @nodoc
abstract mixin class $CancelReservationResponseCopyWith<$Res>  {
  factory $CancelReservationResponseCopyWith(CancelReservationResponse value, $Res Function(CancelReservationResponse) _then) = _$CancelReservationResponseCopyWithImpl;
@useResult
$Res call({
 bool success, String message, bool penaltyApplied, String penaltyExpiresAt
});




}
/// @nodoc
class _$CancelReservationResponseCopyWithImpl<$Res>
    implements $CancelReservationResponseCopyWith<$Res> {
  _$CancelReservationResponseCopyWithImpl(this._self, this._then);

  final CancelReservationResponse _self;
  final $Res Function(CancelReservationResponse) _then;

/// Create a copy of CancelReservationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? message = null,Object? penaltyApplied = null,Object? penaltyExpiresAt = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,penaltyApplied: null == penaltyApplied ? _self.penaltyApplied : penaltyApplied // ignore: cast_nullable_to_non_nullable
as bool,penaltyExpiresAt: null == penaltyExpiresAt ? _self.penaltyExpiresAt : penaltyExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CancelReservationResponse].
extension CancelReservationResponsePatterns on CancelReservationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CancelReservationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CancelReservationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CancelReservationResponse value)  $default,){
final _that = this;
switch (_that) {
case _CancelReservationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CancelReservationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CancelReservationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  String message,  bool penaltyApplied,  String penaltyExpiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CancelReservationResponse() when $default != null:
return $default(_that.success,_that.message,_that.penaltyApplied,_that.penaltyExpiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  String message,  bool penaltyApplied,  String penaltyExpiresAt)  $default,) {final _that = this;
switch (_that) {
case _CancelReservationResponse():
return $default(_that.success,_that.message,_that.penaltyApplied,_that.penaltyExpiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  String message,  bool penaltyApplied,  String penaltyExpiresAt)?  $default,) {final _that = this;
switch (_that) {
case _CancelReservationResponse() when $default != null:
return $default(_that.success,_that.message,_that.penaltyApplied,_that.penaltyExpiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CancelReservationResponse implements CancelReservationResponse {
  const _CancelReservationResponse({required this.success, required this.message, required this.penaltyApplied, required this.penaltyExpiresAt});
  factory _CancelReservationResponse.fromJson(Map<String, dynamic> json) => _$CancelReservationResponseFromJson(json);

@override final  bool success;
@override final  String message;
@override final  bool penaltyApplied;
@override final  String penaltyExpiresAt;

/// Create a copy of CancelReservationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CancelReservationResponseCopyWith<_CancelReservationResponse> get copyWith => __$CancelReservationResponseCopyWithImpl<_CancelReservationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CancelReservationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CancelReservationResponse&&(identical(other.success, success) || other.success == success)&&(identical(other.message, message) || other.message == message)&&(identical(other.penaltyApplied, penaltyApplied) || other.penaltyApplied == penaltyApplied)&&(identical(other.penaltyExpiresAt, penaltyExpiresAt) || other.penaltyExpiresAt == penaltyExpiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,message,penaltyApplied,penaltyExpiresAt);

@override
String toString() {
  return 'CancelReservationResponse(success: $success, message: $message, penaltyApplied: $penaltyApplied, penaltyExpiresAt: $penaltyExpiresAt)';
}


}

/// @nodoc
abstract mixin class _$CancelReservationResponseCopyWith<$Res> implements $CancelReservationResponseCopyWith<$Res> {
  factory _$CancelReservationResponseCopyWith(_CancelReservationResponse value, $Res Function(_CancelReservationResponse) _then) = __$CancelReservationResponseCopyWithImpl;
@override @useResult
$Res call({
 bool success, String message, bool penaltyApplied, String penaltyExpiresAt
});




}
/// @nodoc
class __$CancelReservationResponseCopyWithImpl<$Res>
    implements _$CancelReservationResponseCopyWith<$Res> {
  __$CancelReservationResponseCopyWithImpl(this._self, this._then);

  final _CancelReservationResponse _self;
  final $Res Function(_CancelReservationResponse) _then;

/// Create a copy of CancelReservationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? message = null,Object? penaltyApplied = null,Object? penaltyExpiresAt = null,}) {
  return _then(_CancelReservationResponse(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,penaltyApplied: null == penaltyApplied ? _self.penaltyApplied : penaltyApplied // ignore: cast_nullable_to_non_nullable
as bool,penaltyExpiresAt: null == penaltyExpiresAt ? _self.penaltyExpiresAt : penaltyExpiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
