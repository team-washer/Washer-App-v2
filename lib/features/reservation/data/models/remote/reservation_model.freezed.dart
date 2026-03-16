// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reservation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReservationModel {

 String get id; String get machineId; String get machineType;// "washer" | "dryer"
 int get floor; String get room; String get reservedAt; String? get remainDuration;
/// Create a copy of ReservationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReservationModelCopyWith<ReservationModel> get copyWith => _$ReservationModelCopyWithImpl<ReservationModel>(this as ReservationModel, _$identity);

  /// Serializes this ReservationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReservationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.machineType, machineType) || other.machineType == machineType)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.room, room) || other.room == room)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.remainDuration, remainDuration) || other.remainDuration == remainDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,machineId,machineType,floor,room,reservedAt,remainDuration);

@override
String toString() {
  return 'ReservationModel(id: $id, machineId: $machineId, machineType: $machineType, floor: $floor, room: $room, reservedAt: $reservedAt, remainDuration: $remainDuration)';
}


}

/// @nodoc
abstract mixin class $ReservationModelCopyWith<$Res>  {
  factory $ReservationModelCopyWith(ReservationModel value, $Res Function(ReservationModel) _then) = _$ReservationModelCopyWithImpl;
@useResult
$Res call({
 String id, String machineId, String machineType, int floor, String room, String reservedAt, String? remainDuration
});




}
/// @nodoc
class _$ReservationModelCopyWithImpl<$Res>
    implements $ReservationModelCopyWith<$Res> {
  _$ReservationModelCopyWithImpl(this._self, this._then);

  final ReservationModel _self;
  final $Res Function(ReservationModel) _then;

/// Create a copy of ReservationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? machineId = null,Object? machineType = null,Object? floor = null,Object? room = null,Object? reservedAt = null,Object? remainDuration = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,machineType: null == machineType ? _self.machineType : machineType // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as String,remainDuration: freezed == remainDuration ? _self.remainDuration : remainDuration // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReservationModel].
extension ReservationModelPatterns on ReservationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReservationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReservationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReservationModel value)  $default,){
final _that = this;
switch (_that) {
case _ReservationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReservationModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReservationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String machineId,  String machineType,  int floor,  String room,  String reservedAt,  String? remainDuration)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReservationModel() when $default != null:
return $default(_that.id,_that.machineId,_that.machineType,_that.floor,_that.room,_that.reservedAt,_that.remainDuration);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String machineId,  String machineType,  int floor,  String room,  String reservedAt,  String? remainDuration)  $default,) {final _that = this;
switch (_that) {
case _ReservationModel():
return $default(_that.id,_that.machineId,_that.machineType,_that.floor,_that.room,_that.reservedAt,_that.remainDuration);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String machineId,  String machineType,  int floor,  String room,  String reservedAt,  String? remainDuration)?  $default,) {final _that = this;
switch (_that) {
case _ReservationModel() when $default != null:
return $default(_that.id,_that.machineId,_that.machineType,_that.floor,_that.room,_that.reservedAt,_that.remainDuration);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReservationModel implements ReservationModel {
  const _ReservationModel({required this.id, required this.machineId, required this.machineType, required this.floor, required this.room, required this.reservedAt, this.remainDuration});
  factory _ReservationModel.fromJson(Map<String, dynamic> json) => _$ReservationModelFromJson(json);

@override final  String id;
@override final  String machineId;
@override final  String machineType;
// "washer" | "dryer"
@override final  int floor;
@override final  String room;
@override final  String reservedAt;
@override final  String? remainDuration;

/// Create a copy of ReservationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReservationModelCopyWith<_ReservationModel> get copyWith => __$ReservationModelCopyWithImpl<_ReservationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReservationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReservationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.machineType, machineType) || other.machineType == machineType)&&(identical(other.floor, floor) || other.floor == floor)&&(identical(other.room, room) || other.room == room)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.remainDuration, remainDuration) || other.remainDuration == remainDuration));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,machineId,machineType,floor,room,reservedAt,remainDuration);

@override
String toString() {
  return 'ReservationModel(id: $id, machineId: $machineId, machineType: $machineType, floor: $floor, room: $room, reservedAt: $reservedAt, remainDuration: $remainDuration)';
}


}

/// @nodoc
abstract mixin class _$ReservationModelCopyWith<$Res> implements $ReservationModelCopyWith<$Res> {
  factory _$ReservationModelCopyWith(_ReservationModel value, $Res Function(_ReservationModel) _then) = __$ReservationModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String machineId, String machineType, int floor, String room, String reservedAt, String? remainDuration
});




}
/// @nodoc
class __$ReservationModelCopyWithImpl<$Res>
    implements _$ReservationModelCopyWith<$Res> {
  __$ReservationModelCopyWithImpl(this._self, this._then);

  final _ReservationModel _self;
  final $Res Function(_ReservationModel) _then;

/// Create a copy of ReservationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? machineId = null,Object? machineType = null,Object? floor = null,Object? room = null,Object? reservedAt = null,Object? remainDuration = freezed,}) {
  return _then(_ReservationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as String,machineType: null == machineType ? _self.machineType : machineType // ignore: cast_nullable_to_non_nullable
as String,floor: null == floor ? _self.floor : floor // ignore: cast_nullable_to_non_nullable
as int,room: null == room ? _self.room : room // ignore: cast_nullable_to_non_nullable
as String,reservedAt: null == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as String,remainDuration: freezed == remainDuration ? _self.remainDuration : remainDuration // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
