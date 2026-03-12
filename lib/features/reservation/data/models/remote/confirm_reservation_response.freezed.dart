// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'confirm_reservation_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConfirmReservationResponse {

 String get status; int get code; String get message;
/// Create a copy of ConfirmReservationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfirmReservationResponseCopyWith<ConfirmReservationResponse> get copyWith => _$ConfirmReservationResponseCopyWithImpl<ConfirmReservationResponse>(this as ConfirmReservationResponse, _$identity);

  /// Serializes this ConfirmReservationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfirmReservationResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,code,message);

@override
String toString() {
  return 'ConfirmReservationResponse(status: $status, code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $ConfirmReservationResponseCopyWith<$Res>  {
  factory $ConfirmReservationResponseCopyWith(ConfirmReservationResponse value, $Res Function(ConfirmReservationResponse) _then) = _$ConfirmReservationResponseCopyWithImpl;
@useResult
$Res call({
 String status, int code, String message
});




}
/// @nodoc
class _$ConfirmReservationResponseCopyWithImpl<$Res>
    implements $ConfirmReservationResponseCopyWith<$Res> {
  _$ConfirmReservationResponseCopyWithImpl(this._self, this._then);

  final ConfirmReservationResponse _self;
  final $Res Function(ConfirmReservationResponse) _then;

/// Create a copy of ConfirmReservationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfirmReservationResponse].
extension ConfirmReservationResponsePatterns on ConfirmReservationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConfirmReservationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConfirmReservationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConfirmReservationResponse value)  $default,){
final _that = this;
switch (_that) {
case _ConfirmReservationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConfirmReservationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _ConfirmReservationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  int code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConfirmReservationResponse() when $default != null:
return $default(_that.status,_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  int code,  String message)  $default,) {final _that = this;
switch (_that) {
case _ConfirmReservationResponse():
return $default(_that.status,_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  int code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ConfirmReservationResponse() when $default != null:
return $default(_that.status,_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConfirmReservationResponse implements ConfirmReservationResponse {
  const _ConfirmReservationResponse({required this.status, required this.code, required this.message});
  factory _ConfirmReservationResponse.fromJson(Map<String, dynamic> json) => _$ConfirmReservationResponseFromJson(json);

@override final  String status;
@override final  int code;
@override final  String message;

/// Create a copy of ConfirmReservationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfirmReservationResponseCopyWith<_ConfirmReservationResponse> get copyWith => __$ConfirmReservationResponseCopyWithImpl<_ConfirmReservationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConfirmReservationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfirmReservationResponse&&(identical(other.status, status) || other.status == status)&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,code,message);

@override
String toString() {
  return 'ConfirmReservationResponse(status: $status, code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ConfirmReservationResponseCopyWith<$Res> implements $ConfirmReservationResponseCopyWith<$Res> {
  factory _$ConfirmReservationResponseCopyWith(_ConfirmReservationResponse value, $Res Function(_ConfirmReservationResponse) _then) = __$ConfirmReservationResponseCopyWithImpl;
@override @useResult
$Res call({
 String status, int code, String message
});




}
/// @nodoc
class __$ConfirmReservationResponseCopyWithImpl<$Res>
    implements _$ConfirmReservationResponseCopyWith<$Res> {
  __$ConfirmReservationResponseCopyWithImpl(this._self, this._then);

  final _ConfirmReservationResponse _self;
  final $Res Function(_ConfirmReservationResponse) _then;

/// Create a copy of ConfirmReservationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? code = null,Object? message = null,}) {
  return _then(_ConfirmReservationResponse(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
