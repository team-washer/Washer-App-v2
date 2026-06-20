// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'alarm_list_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AlarmListResponse {

@JsonKey(name: 'notifications') List<Notifications> get data;
/// Create a copy of AlarmListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlarmListResponseCopyWith<AlarmListResponse> get copyWith => _$AlarmListResponseCopyWithImpl<AlarmListResponse>(this as AlarmListResponse, _$identity);

  /// Serializes this AlarmListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlarmListResponse&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AlarmListResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class $AlarmListResponseCopyWith<$Res>  {
  factory $AlarmListResponseCopyWith(AlarmListResponse value, $Res Function(AlarmListResponse) _then) = _$AlarmListResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'notifications') List<Notifications> data
});




}
/// @nodoc
class _$AlarmListResponseCopyWithImpl<$Res>
    implements $AlarmListResponseCopyWith<$Res> {
  _$AlarmListResponseCopyWithImpl(this._self, this._then);

  final AlarmListResponse _self;
  final $Res Function(AlarmListResponse) _then;

/// Create a copy of AlarmListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<Notifications>,
  ));
}

}


/// Adds pattern-matching-related methods to [AlarmListResponse].
extension AlarmListResponsePatterns on AlarmListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlarmListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlarmListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlarmListResponse value)  $default,){
final _that = this;
switch (_that) {
case _AlarmListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlarmListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AlarmListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'notifications')  List<Notifications> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlarmListResponse() when $default != null:
return $default(_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'notifications')  List<Notifications> data)  $default,) {final _that = this;
switch (_that) {
case _AlarmListResponse():
return $default(_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'notifications')  List<Notifications> data)?  $default,) {final _that = this;
switch (_that) {
case _AlarmListResponse() when $default != null:
return $default(_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AlarmListResponse implements AlarmListResponse {
  const _AlarmListResponse({@JsonKey(name: 'notifications') final  List<Notifications> data = const <Notifications>[]}): _data = data;
  factory _AlarmListResponse.fromJson(Map<String, dynamic> json) => _$AlarmListResponseFromJson(json);

 final  List<Notifications> _data;
@override@JsonKey(name: 'notifications') List<Notifications> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of AlarmListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlarmListResponseCopyWith<_AlarmListResponse> get copyWith => __$AlarmListResponseCopyWithImpl<_AlarmListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AlarmListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlarmListResponse&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AlarmListResponse(data: $data)';
}


}

/// @nodoc
abstract mixin class _$AlarmListResponseCopyWith<$Res> implements $AlarmListResponseCopyWith<$Res> {
  factory _$AlarmListResponseCopyWith(_AlarmListResponse value, $Res Function(_AlarmListResponse) _then) = __$AlarmListResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'notifications') List<Notifications> data
});




}
/// @nodoc
class __$AlarmListResponseCopyWithImpl<$Res>
    implements _$AlarmListResponseCopyWith<$Res> {
  __$AlarmListResponseCopyWithImpl(this._self, this._then);

  final _AlarmListResponse _self;
  final $Res Function(_AlarmListResponse) _then;

/// Create a copy of AlarmListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,}) {
  return _then(_AlarmListResponse(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<Notifications>,
  ));
}


}


/// @nodoc
mixin _$Notifications {

// 서버가 id를 숫자로 내려주므로 문자열로 안전하게 변환한다.
@JsonKey(fromJson: _idFromJson) String get id;// 알 수 없는 타입이 와도 목록 전체가 깨지지 않도록 unknown으로 폴백한다.
@JsonKey(unknownEnumValue: AlarmType.unknown) AlarmType get type; String get message; String get createdAt;
/// Create a copy of Notifications
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationsCopyWith<Notifications> get copyWith => _$NotificationsCopyWithImpl<Notifications>(this as Notifications, _$identity);

  /// Serializes this Notifications to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Notifications&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,message,createdAt);

@override
String toString() {
  return 'Notifications(id: $id, type: $type, message: $message, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $NotificationsCopyWith<$Res>  {
  factory $NotificationsCopyWith(Notifications value, $Res Function(Notifications) _then) = _$NotificationsCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: _idFromJson) String id,@JsonKey(unknownEnumValue: AlarmType.unknown) AlarmType type, String message, String createdAt
});




}
/// @nodoc
class _$NotificationsCopyWithImpl<$Res>
    implements $NotificationsCopyWith<$Res> {
  _$NotificationsCopyWithImpl(this._self, this._then);

  final Notifications _self;
  final $Res Function(Notifications) _then;

/// Create a copy of Notifications
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? message = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AlarmType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Notifications].
extension NotificationsPatterns on Notifications {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Notifications value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Notifications() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Notifications value)  $default,){
final _that = this;
switch (_that) {
case _Notifications():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Notifications value)?  $default,){
final _that = this;
switch (_that) {
case _Notifications() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _idFromJson)  String id, @JsonKey(unknownEnumValue: AlarmType.unknown)  AlarmType type,  String message,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Notifications() when $default != null:
return $default(_that.id,_that.type,_that.message,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: _idFromJson)  String id, @JsonKey(unknownEnumValue: AlarmType.unknown)  AlarmType type,  String message,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _Notifications():
return $default(_that.id,_that.type,_that.message,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: _idFromJson)  String id, @JsonKey(unknownEnumValue: AlarmType.unknown)  AlarmType type,  String message,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Notifications() when $default != null:
return $default(_that.id,_that.type,_that.message,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Notifications implements Notifications {
  const _Notifications({@JsonKey(fromJson: _idFromJson) required this.id, @JsonKey(unknownEnumValue: AlarmType.unknown) required this.type, required this.message, required this.createdAt});
  factory _Notifications.fromJson(Map<String, dynamic> json) => _$NotificationsFromJson(json);

// 서버가 id를 숫자로 내려주므로 문자열로 안전하게 변환한다.
@override@JsonKey(fromJson: _idFromJson) final  String id;
// 알 수 없는 타입이 와도 목록 전체가 깨지지 않도록 unknown으로 폴백한다.
@override@JsonKey(unknownEnumValue: AlarmType.unknown) final  AlarmType type;
@override final  String message;
@override final  String createdAt;

/// Create a copy of Notifications
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationsCopyWith<_Notifications> get copyWith => __$NotificationsCopyWithImpl<_Notifications>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Notifications&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,message,createdAt);

@override
String toString() {
  return 'Notifications(id: $id, type: $type, message: $message, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$NotificationsCopyWith<$Res> implements $NotificationsCopyWith<$Res> {
  factory _$NotificationsCopyWith(_Notifications value, $Res Function(_Notifications) _then) = __$NotificationsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: _idFromJson) String id,@JsonKey(unknownEnumValue: AlarmType.unknown) AlarmType type, String message, String createdAt
});




}
/// @nodoc
class __$NotificationsCopyWithImpl<$Res>
    implements _$NotificationsCopyWith<$Res> {
  __$NotificationsCopyWithImpl(this._self, this._then);

  final _Notifications _self;
  final $Res Function(_Notifications) _then;

/// Create a copy of Notifications
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? message = null,Object? createdAt = null,}) {
  return _then(_Notifications(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AlarmType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
