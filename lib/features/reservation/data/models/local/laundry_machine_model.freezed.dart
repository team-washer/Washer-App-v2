// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'laundry_machine_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MachineModel {

 int get machineId; String get name; String get type; String get status; String get availability; String? get operatingState; String? get jobState; String? get switchStatus; String? get expectedCompletionTime; int? get remainingMinutes; int? get reservationId; int? get userId; String? get roomNumber;
/// Create a copy of MachineModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MachineModelCopyWith<MachineModel> get copyWith => _$MachineModelCopyWithImpl<MachineModel>(this as MachineModel, _$identity);

  /// Serializes this MachineModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MachineModel&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.operatingState, operatingState) || other.operatingState == operatingState)&&(identical(other.jobState, jobState) || other.jobState == jobState)&&(identical(other.switchStatus, switchStatus) || other.switchStatus == switchStatus)&&(identical(other.expectedCompletionTime, expectedCompletionTime) || other.expectedCompletionTime == expectedCompletionTime)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,machineId,name,type,status,availability,operatingState,jobState,switchStatus,expectedCompletionTime,remainingMinutes,reservationId,userId,roomNumber);

@override
String toString() {
  return 'MachineModel(machineId: $machineId, name: $name, type: $type, status: $status, availability: $availability, operatingState: $operatingState, jobState: $jobState, switchStatus: $switchStatus, expectedCompletionTime: $expectedCompletionTime, remainingMinutes: $remainingMinutes, reservationId: $reservationId, userId: $userId, roomNumber: $roomNumber)';
}


}

/// @nodoc
abstract mixin class $MachineModelCopyWith<$Res>  {
  factory $MachineModelCopyWith(MachineModel value, $Res Function(MachineModel) _then) = _$MachineModelCopyWithImpl;
@useResult
$Res call({
 int machineId, String name, String type, String status, String availability, String? operatingState, String? jobState, String? switchStatus, String? expectedCompletionTime, int? remainingMinutes, int? reservationId, int? userId, String? roomNumber
});




}
/// @nodoc
class _$MachineModelCopyWithImpl<$Res>
    implements $MachineModelCopyWith<$Res> {
  _$MachineModelCopyWithImpl(this._self, this._then);

  final MachineModel _self;
  final $Res Function(MachineModel) _then;

/// Create a copy of MachineModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? machineId = null,Object? name = null,Object? type = null,Object? status = null,Object? availability = null,Object? operatingState = freezed,Object? jobState = freezed,Object? switchStatus = freezed,Object? expectedCompletionTime = freezed,Object? remainingMinutes = freezed,Object? reservationId = freezed,Object? userId = freezed,Object? roomNumber = freezed,}) {
  return _then(_self.copyWith(
machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as String,operatingState: freezed == operatingState ? _self.operatingState : operatingState // ignore: cast_nullable_to_non_nullable
as String?,jobState: freezed == jobState ? _self.jobState : jobState // ignore: cast_nullable_to_non_nullable
as String?,switchStatus: freezed == switchStatus ? _self.switchStatus : switchStatus // ignore: cast_nullable_to_non_nullable
as String?,expectedCompletionTime: freezed == expectedCompletionTime ? _self.expectedCompletionTime : expectedCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,remainingMinutes: freezed == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as int?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,roomNumber: freezed == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MachineModel].
extension MachineModelPatterns on MachineModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MachineModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MachineModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MachineModel value)  $default,){
final _that = this;
switch (_that) {
case _MachineModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MachineModel value)?  $default,){
final _that = this;
switch (_that) {
case _MachineModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int machineId,  String name,  String type,  String status,  String availability,  String? operatingState,  String? jobState,  String? switchStatus,  String? expectedCompletionTime,  int? remainingMinutes,  int? reservationId,  int? userId,  String? roomNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MachineModel() when $default != null:
return $default(_that.machineId,_that.name,_that.type,_that.status,_that.availability,_that.operatingState,_that.jobState,_that.switchStatus,_that.expectedCompletionTime,_that.remainingMinutes,_that.reservationId,_that.userId,_that.roomNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int machineId,  String name,  String type,  String status,  String availability,  String? operatingState,  String? jobState,  String? switchStatus,  String? expectedCompletionTime,  int? remainingMinutes,  int? reservationId,  int? userId,  String? roomNumber)  $default,) {final _that = this;
switch (_that) {
case _MachineModel():
return $default(_that.machineId,_that.name,_that.type,_that.status,_that.availability,_that.operatingState,_that.jobState,_that.switchStatus,_that.expectedCompletionTime,_that.remainingMinutes,_that.reservationId,_that.userId,_that.roomNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int machineId,  String name,  String type,  String status,  String availability,  String? operatingState,  String? jobState,  String? switchStatus,  String? expectedCompletionTime,  int? remainingMinutes,  int? reservationId,  int? userId,  String? roomNumber)?  $default,) {final _that = this;
switch (_that) {
case _MachineModel() when $default != null:
return $default(_that.machineId,_that.name,_that.type,_that.status,_that.availability,_that.operatingState,_that.jobState,_that.switchStatus,_that.expectedCompletionTime,_that.remainingMinutes,_that.reservationId,_that.userId,_that.roomNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MachineModel extends MachineModel {
  const _MachineModel({required this.machineId, required this.name, required this.type, required this.status, required this.availability, this.operatingState, this.jobState, this.switchStatus, this.expectedCompletionTime, this.remainingMinutes, this.reservationId, this.userId, this.roomNumber}): super._();
  factory _MachineModel.fromJson(Map<String, dynamic> json) => _$MachineModelFromJson(json);

@override final  int machineId;
@override final  String name;
@override final  String type;
@override final  String status;
@override final  String availability;
@override final  String? operatingState;
@override final  String? jobState;
@override final  String? switchStatus;
@override final  String? expectedCompletionTime;
@override final  int? remainingMinutes;
@override final  int? reservationId;
@override final  int? userId;
@override final  String? roomNumber;

/// Create a copy of MachineModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MachineModelCopyWith<_MachineModel> get copyWith => __$MachineModelCopyWithImpl<_MachineModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MachineModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MachineModel&&(identical(other.machineId, machineId) || other.machineId == machineId)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.availability, availability) || other.availability == availability)&&(identical(other.operatingState, operatingState) || other.operatingState == operatingState)&&(identical(other.jobState, jobState) || other.jobState == jobState)&&(identical(other.switchStatus, switchStatus) || other.switchStatus == switchStatus)&&(identical(other.expectedCompletionTime, expectedCompletionTime) || other.expectedCompletionTime == expectedCompletionTime)&&(identical(other.remainingMinutes, remainingMinutes) || other.remainingMinutes == remainingMinutes)&&(identical(other.reservationId, reservationId) || other.reservationId == reservationId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.roomNumber, roomNumber) || other.roomNumber == roomNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,machineId,name,type,status,availability,operatingState,jobState,switchStatus,expectedCompletionTime,remainingMinutes,reservationId,userId,roomNumber);

@override
String toString() {
  return 'MachineModel(machineId: $machineId, name: $name, type: $type, status: $status, availability: $availability, operatingState: $operatingState, jobState: $jobState, switchStatus: $switchStatus, expectedCompletionTime: $expectedCompletionTime, remainingMinutes: $remainingMinutes, reservationId: $reservationId, userId: $userId, roomNumber: $roomNumber)';
}


}

/// @nodoc
abstract mixin class _$MachineModelCopyWith<$Res> implements $MachineModelCopyWith<$Res> {
  factory _$MachineModelCopyWith(_MachineModel value, $Res Function(_MachineModel) _then) = __$MachineModelCopyWithImpl;
@override @useResult
$Res call({
 int machineId, String name, String type, String status, String availability, String? operatingState, String? jobState, String? switchStatus, String? expectedCompletionTime, int? remainingMinutes, int? reservationId, int? userId, String? roomNumber
});




}
/// @nodoc
class __$MachineModelCopyWithImpl<$Res>
    implements _$MachineModelCopyWith<$Res> {
  __$MachineModelCopyWithImpl(this._self, this._then);

  final _MachineModel _self;
  final $Res Function(_MachineModel) _then;

/// Create a copy of MachineModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? machineId = null,Object? name = null,Object? type = null,Object? status = null,Object? availability = null,Object? operatingState = freezed,Object? jobState = freezed,Object? switchStatus = freezed,Object? expectedCompletionTime = freezed,Object? remainingMinutes = freezed,Object? reservationId = freezed,Object? userId = freezed,Object? roomNumber = freezed,}) {
  return _then(_MachineModel(
machineId: null == machineId ? _self.machineId : machineId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as String,operatingState: freezed == operatingState ? _self.operatingState : operatingState // ignore: cast_nullable_to_non_nullable
as String?,jobState: freezed == jobState ? _self.jobState : jobState // ignore: cast_nullable_to_non_nullable
as String?,switchStatus: freezed == switchStatus ? _self.switchStatus : switchStatus // ignore: cast_nullable_to_non_nullable
as String?,expectedCompletionTime: freezed == expectedCompletionTime ? _self.expectedCompletionTime : expectedCompletionTime // ignore: cast_nullable_to_non_nullable
as String?,remainingMinutes: freezed == remainingMinutes ? _self.remainingMinutes : remainingMinutes // ignore: cast_nullable_to_non_nullable
as int?,reservationId: freezed == reservationId ? _self.reservationId : reservationId // ignore: cast_nullable_to_non_nullable
as int?,userId: freezed == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int?,roomNumber: freezed == roomNumber ? _self.roomNumber : roomNumber // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MachineStatusResponse {

 List<MachineModel> get machines; int get totalCount;
/// Create a copy of MachineStatusResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MachineStatusResponseCopyWith<MachineStatusResponse> get copyWith => _$MachineStatusResponseCopyWithImpl<MachineStatusResponse>(this as MachineStatusResponse, _$identity);

  /// Serializes this MachineStatusResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MachineStatusResponse&&const DeepCollectionEquality().equals(other.machines, machines)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(machines),totalCount);

@override
String toString() {
  return 'MachineStatusResponse(machines: $machines, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class $MachineStatusResponseCopyWith<$Res>  {
  factory $MachineStatusResponseCopyWith(MachineStatusResponse value, $Res Function(MachineStatusResponse) _then) = _$MachineStatusResponseCopyWithImpl;
@useResult
$Res call({
 List<MachineModel> machines, int totalCount
});




}
/// @nodoc
class _$MachineStatusResponseCopyWithImpl<$Res>
    implements $MachineStatusResponseCopyWith<$Res> {
  _$MachineStatusResponseCopyWithImpl(this._self, this._then);

  final MachineStatusResponse _self;
  final $Res Function(MachineStatusResponse) _then;

/// Create a copy of MachineStatusResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? machines = null,Object? totalCount = null,}) {
  return _then(_self.copyWith(
machines: null == machines ? _self.machines : machines // ignore: cast_nullable_to_non_nullable
as List<MachineModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MachineStatusResponse].
extension MachineStatusResponsePatterns on MachineStatusResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MachineStatusResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MachineStatusResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MachineStatusResponse value)  $default,){
final _that = this;
switch (_that) {
case _MachineStatusResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MachineStatusResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MachineStatusResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<MachineModel> machines,  int totalCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MachineStatusResponse() when $default != null:
return $default(_that.machines,_that.totalCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<MachineModel> machines,  int totalCount)  $default,) {final _that = this;
switch (_that) {
case _MachineStatusResponse():
return $default(_that.machines,_that.totalCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<MachineModel> machines,  int totalCount)?  $default,) {final _that = this;
switch (_that) {
case _MachineStatusResponse() when $default != null:
return $default(_that.machines,_that.totalCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MachineStatusResponse implements MachineStatusResponse {
  const _MachineStatusResponse({required final  List<MachineModel> machines, required this.totalCount}): _machines = machines;
  factory _MachineStatusResponse.fromJson(Map<String, dynamic> json) => _$MachineStatusResponseFromJson(json);

 final  List<MachineModel> _machines;
@override List<MachineModel> get machines {
  if (_machines is EqualUnmodifiableListView) return _machines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_machines);
}

@override final  int totalCount;

/// Create a copy of MachineStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MachineStatusResponseCopyWith<_MachineStatusResponse> get copyWith => __$MachineStatusResponseCopyWithImpl<_MachineStatusResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MachineStatusResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MachineStatusResponse&&const DeepCollectionEquality().equals(other._machines, _machines)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_machines),totalCount);

@override
String toString() {
  return 'MachineStatusResponse(machines: $machines, totalCount: $totalCount)';
}


}

/// @nodoc
abstract mixin class _$MachineStatusResponseCopyWith<$Res> implements $MachineStatusResponseCopyWith<$Res> {
  factory _$MachineStatusResponseCopyWith(_MachineStatusResponse value, $Res Function(_MachineStatusResponse) _then) = __$MachineStatusResponseCopyWithImpl;
@override @useResult
$Res call({
 List<MachineModel> machines, int totalCount
});




}
/// @nodoc
class __$MachineStatusResponseCopyWithImpl<$Res>
    implements _$MachineStatusResponseCopyWith<$Res> {
  __$MachineStatusResponseCopyWithImpl(this._self, this._then);

  final _MachineStatusResponse _self;
  final $Res Function(_MachineStatusResponse) _then;

/// Create a copy of MachineStatusResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? machines = null,Object? totalCount = null,}) {
  return _then(_MachineStatusResponse(
machines: null == machines ? _self._machines : machines // ignore: cast_nullable_to_non_nullable
as List<MachineModel>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
