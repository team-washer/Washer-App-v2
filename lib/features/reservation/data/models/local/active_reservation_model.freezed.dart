// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_reservation_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActiveReservationModel {

 int get id; int get userId; String get userName; String get userRoomNumber; int get machineId; String get machineName; String? get reservedAt; String? get confirmedAt; String? get startTime; String? get expectedCompletionTime; String? get actualCompletionTime; String get status;
/// Create a copy of ActiveReservationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveReservationModelCopyWith<ActiveReservationModel> get copyWith => _$ActiveReservationModelCopyWithImpl<ActiveReservationModel>(this as ActiveReservationModel, _$identity);

  /// Serializes this ActiveReservationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveReservationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userRoomNumber, userRoomNumber) || other.userRoomNumber == userRoomNumber)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.machineName, machineName) || other.machineName == machineName)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.expectedCompletionTime, expectedCompletionTime) || other.expectedCompletionTime == expectedCompletionTime)&&(identical(other.actualCompletionTime, actualCompletionTime) || other.actualCompletionTime == actualCompletionTime)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,userRoomNumber,machineId,machineName,reservedAt,confirmedAt,startTime,expectedCompletionTime,actualCompletionTime,status);

@override
String toString() {
  return 'ActiveReservationModel(id: $id, userId: $userId, userName: $userName, userRoomNumber: $userRoomNumber, machineId: $machineId, machineName: $machineName, reservedAt: $reservedAt, confirmedAt: $confirmedAt, startTime: $startTime, expectedCompletionTime: $expectedCompletionTime, actualCompletionTime: $actualCompletionTime, status: $status)';
}


}

/// @nodoc
abstract mixin class $ActiveReservationModelCopyWith<$Res>  {
  factory $ActiveReservationModelCopyWith(ActiveReservationModel value, $Res Function(ActiveReservationModel) _then) = _$ActiveReservationModelCopyWithImpl;
@useResult
$Res call({
 int id, int userId, String userName, String userRoomNumber, int machineId, String machineName, String? reservedAt, String? confirmedAt, String? startTime, String? expectedCompletionTime, String? actualCompletionTime, String status
});




}
/// @nodoc
class _$ActiveReservationModelCopyWithImpl<$Res>
    implements $ActiveReservationModelCopyWith<$Res> {
  _$ActiveReservationModelCopyWithImpl(this._self, this._then);

  final ActiveReservationModel _self;
  final $Res Function(ActiveReservationModel) _then;

/// Create a copy of ActiveReservationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? userRoomNumber = null,Object? machineId = null,Object? machineName = null,Object? reservedAt = freezed,Object? confirmedAt = freezed,Object? startTime = freezed,Object? expectedCompletionTime = freezed,Object? actualCompletionTime = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userRoomNumber: null == userRoomNumber ? _self.userRoomNumber : userRoomNumber // ignore: cast_nullable_to_non_nullable
as String,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as int,machineName: null == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String,reservedAt: freezed == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,expectedCompletionTime: freezed == expectedCompletionTime ? _self.expectedCompletionTime : expectedCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,actualCompletionTime: freezed == actualCompletionTime ? _self.actualCompletionTime : actualCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActiveReservationModel].
extension ActiveReservationModelPatterns on ActiveReservationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActiveReservationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActiveReservationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActiveReservationModel value)  $default,){
final _that = this;
switch (_that) {
case _ActiveReservationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActiveReservationModel value)?  $default,){
final _that = this;
switch (_that) {
case _ActiveReservationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int userId,  String userName,  String userRoomNumber,  int machineId,  String machineName,  String? reservedAt,  String? confirmedAt,  String? startTime,  String? expectedCompletionTime,  String? actualCompletionTime,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActiveReservationModel() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.userRoomNumber,_that.machineId,_that.machineName,_that.reservedAt,_that.confirmedAt,_that.startTime,_that.expectedCompletionTime,_that.actualCompletionTime,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int userId,  String userName,  String userRoomNumber,  int machineId,  String machineName,  String? reservedAt,  String? confirmedAt,  String? startTime,  String? expectedCompletionTime,  String? actualCompletionTime,  String status)  $default,) {final _that = this;
switch (_that) {
case _ActiveReservationModel():
return $default(_that.id,_that.userId,_that.userName,_that.userRoomNumber,_that.machineId,_that.machineName,_that.reservedAt,_that.confirmedAt,_that.startTime,_that.expectedCompletionTime,_that.actualCompletionTime,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int userId,  String userName,  String userRoomNumber,  int machineId,  String machineName,  String? reservedAt,  String? confirmedAt,  String? startTime,  String? expectedCompletionTime,  String? actualCompletionTime,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ActiveReservationModel() when $default != null:
return $default(_that.id,_that.userId,_that.userName,_that.userRoomNumber,_that.machineId,_that.machineName,_that.reservedAt,_that.confirmedAt,_that.startTime,_that.expectedCompletionTime,_that.actualCompletionTime,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActiveReservationModel extends ActiveReservationModel {
  const _ActiveReservationModel({required this.id, required this.userId, required this.userName, required this.userRoomNumber, required this.machineId, required this.machineName, this.reservedAt, this.confirmedAt, this.startTime, this.expectedCompletionTime, this.actualCompletionTime, required this.status}): super._();
  factory _ActiveReservationModel.fromJson(Map<String, dynamic> json) => _$ActiveReservationModelFromJson(json);

@override final  int id;
@override final  int userId;
@override final  String userName;
@override final  String userRoomNumber;
@override final  int machineId;
@override final  String machineName;
@override final  String? reservedAt;
@override final  String? confirmedAt;
@override final  String? startTime;
@override final  String? expectedCompletionTime;
@override final  String? actualCompletionTime;
@override final  String status;

/// Create a copy of ActiveReservationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActiveReservationModelCopyWith<_ActiveReservationModel> get copyWith => __$ActiveReservationModelCopyWithImpl<_ActiveReservationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActiveReservationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActiveReservationModel&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.userRoomNumber, userRoomNumber) || other.userRoomNumber == userRoomNumber)&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.machineName, machineName) || other.machineName == machineName)&&(identical(other.reservedAt, reservedAt) || other.reservedAt == reservedAt)&&(identical(other.confirmedAt, confirmedAt) || other.confirmedAt == confirmedAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.expectedCompletionTime, expectedCompletionTime) || other.expectedCompletionTime == expectedCompletionTime)&&(identical(other.actualCompletionTime, actualCompletionTime) || other.actualCompletionTime == actualCompletionTime)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,userName,userRoomNumber,machineId,machineName,reservedAt,confirmedAt,startTime,expectedCompletionTime,actualCompletionTime,status);

@override
String toString() {
  return 'ActiveReservationModel(id: $id, userId: $userId, userName: $userName, userRoomNumber: $userRoomNumber, machineId: $machineId, machineName: $machineName, reservedAt: $reservedAt, confirmedAt: $confirmedAt, startTime: $startTime, expectedCompletionTime: $expectedCompletionTime, actualCompletionTime: $actualCompletionTime, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ActiveReservationModelCopyWith<$Res> implements $ActiveReservationModelCopyWith<$Res> {
  factory _$ActiveReservationModelCopyWith(_ActiveReservationModel value, $Res Function(_ActiveReservationModel) _then) = __$ActiveReservationModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int userId, String userName, String userRoomNumber, int machineId, String machineName, String? reservedAt, String? confirmedAt, String? startTime, String? expectedCompletionTime, String? actualCompletionTime, String status
});




}
/// @nodoc
class __$ActiveReservationModelCopyWithImpl<$Res>
    implements _$ActiveReservationModelCopyWith<$Res> {
  __$ActiveReservationModelCopyWithImpl(this._self, this._then);

  final _ActiveReservationModel _self;
  final $Res Function(_ActiveReservationModel) _then;

/// Create a copy of ActiveReservationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? userName = null,Object? userRoomNumber = null,Object? machineId = null,Object? machineName = null,Object? reservedAt = freezed,Object? confirmedAt = freezed,Object? startTime = freezed,Object? expectedCompletionTime = freezed,Object? actualCompletionTime = freezed,Object? status = null,}) {
  return _then(_ActiveReservationModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,userRoomNumber: null == userRoomNumber ? _self.userRoomNumber : userRoomNumber // ignore: cast_nullable_to_non_nullable
as String,machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as int,machineName: null == machineName ? _self.machineName : machineName // ignore: cast_nullable_to_non_nullable
as String,reservedAt: freezed == reservedAt ? _self.reservedAt : reservedAt // ignore: cast_nullable_to_non_nullable
as String?,confirmedAt: freezed == confirmedAt ? _self.confirmedAt : confirmedAt // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,expectedCompletionTime: freezed == expectedCompletionTime ? _self.expectedCompletionTime : expectedCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,actualCompletionTime: freezed == actualCompletionTime ? _self.actualCompletionTime : actualCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
