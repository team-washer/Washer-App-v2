// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'machine_history_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MachineHistoryResponse {

 List<HistoryContent> get content; int get pageNumber; int get pageSize; int get totalElements; int get totalPages; bool get last;
/// Create a copy of MachineHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MachineHistoryResponseCopyWith<MachineHistoryResponse> get copyWith => _$MachineHistoryResponseCopyWithImpl<MachineHistoryResponse>(this as MachineHistoryResponse, _$identity);

  /// Serializes this MachineHistoryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MachineHistoryResponse&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalElements, totalElements) || other.totalElements == totalElements)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.last, last) || other.last == last));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(content),pageNumber,pageSize,totalElements,totalPages,last);

@override
String toString() {
  return 'MachineHistoryResponse(content: $content, pageNumber: $pageNumber, pageSize: $pageSize, totalElements: $totalElements, totalPages: $totalPages, last: $last)';
}


}

/// @nodoc
abstract mixin class $MachineHistoryResponseCopyWith<$Res>  {
  factory $MachineHistoryResponseCopyWith(MachineHistoryResponse value, $Res Function(MachineHistoryResponse) _then) = _$MachineHistoryResponseCopyWithImpl;
@useResult
$Res call({
 List<HistoryContent> content, int pageNumber, int pageSize, int totalElements, int totalPages, bool last
});




}
/// @nodoc
class _$MachineHistoryResponseCopyWithImpl<$Res>
    implements $MachineHistoryResponseCopyWith<$Res> {
  _$MachineHistoryResponseCopyWithImpl(this._self, this._then);

  final MachineHistoryResponse _self;
  final $Res Function(MachineHistoryResponse) _then;

/// Create a copy of MachineHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? pageNumber = null,Object? pageSize = null,Object? totalElements = null,Object? totalPages = null,Object? last = null,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as List<HistoryContent>,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalElements: null == totalElements ? _self.totalElements : totalElements // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,last: null == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [MachineHistoryResponse].
extension MachineHistoryResponsePatterns on MachineHistoryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MachineHistoryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MachineHistoryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MachineHistoryResponse value)  $default,){
final _that = this;
switch (_that) {
case _MachineHistoryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MachineHistoryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _MachineHistoryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HistoryContent> content,  int pageNumber,  int pageSize,  int totalElements,  int totalPages,  bool last)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MachineHistoryResponse() when $default != null:
return $default(_that.content,_that.pageNumber,_that.pageSize,_that.totalElements,_that.totalPages,_that.last);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HistoryContent> content,  int pageNumber,  int pageSize,  int totalElements,  int totalPages,  bool last)  $default,) {final _that = this;
switch (_that) {
case _MachineHistoryResponse():
return $default(_that.content,_that.pageNumber,_that.pageSize,_that.totalElements,_that.totalPages,_that.last);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HistoryContent> content,  int pageNumber,  int pageSize,  int totalElements,  int totalPages,  bool last)?  $default,) {final _that = this;
switch (_that) {
case _MachineHistoryResponse() when $default != null:
return $default(_that.content,_that.pageNumber,_that.pageSize,_that.totalElements,_that.totalPages,_that.last);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MachineHistoryResponse implements MachineHistoryResponse {
  const _MachineHistoryResponse({required final  List<HistoryContent> content, required this.pageNumber, required this.pageSize, required this.totalElements, required this.totalPages, required this.last}): _content = content;
  factory _MachineHistoryResponse.fromJson(Map<String, dynamic> json) => _$MachineHistoryResponseFromJson(json);

 final  List<HistoryContent> _content;
@override List<HistoryContent> get content {
  if (_content is EqualUnmodifiableListView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_content);
}

@override final  int pageNumber;
@override final  int pageSize;
@override final  int totalElements;
@override final  int totalPages;
@override final  bool last;

/// Create a copy of MachineHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MachineHistoryResponseCopyWith<_MachineHistoryResponse> get copyWith => __$MachineHistoryResponseCopyWithImpl<_MachineHistoryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MachineHistoryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MachineHistoryResponse&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.pageNumber, pageNumber) || other.pageNumber == pageNumber)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalElements, totalElements) || other.totalElements == totalElements)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.last, last) || other.last == last));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_content),pageNumber,pageSize,totalElements,totalPages,last);

@override
String toString() {
  return 'MachineHistoryResponse(content: $content, pageNumber: $pageNumber, pageSize: $pageSize, totalElements: $totalElements, totalPages: $totalPages, last: $last)';
}


}

/// @nodoc
abstract mixin class _$MachineHistoryResponseCopyWith<$Res> implements $MachineHistoryResponseCopyWith<$Res> {
  factory _$MachineHistoryResponseCopyWith(_MachineHistoryResponse value, $Res Function(_MachineHistoryResponse) _then) = __$MachineHistoryResponseCopyWithImpl;
@override @useResult
$Res call({
 List<HistoryContent> content, int pageNumber, int pageSize, int totalElements, int totalPages, bool last
});




}
/// @nodoc
class __$MachineHistoryResponseCopyWithImpl<$Res>
    implements _$MachineHistoryResponseCopyWith<$Res> {
  __$MachineHistoryResponseCopyWithImpl(this._self, this._then);

  final _MachineHistoryResponse _self;
  final $Res Function(_MachineHistoryResponse) _then;

/// Create a copy of MachineHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? pageNumber = null,Object? pageSize = null,Object? totalElements = null,Object? totalPages = null,Object? last = null,}) {
  return _then(_MachineHistoryResponse(
content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as List<HistoryContent>,pageNumber: null == pageNumber ? _self.pageNumber : pageNumber // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalElements: null == totalElements ? _self.totalElements : totalElements // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,last: null == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$HistoryContent {

 int get id; String get userRoomNumber; String get startTime; String get completionTime; String get status; String get createdAt;
/// Create a copy of HistoryContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryContentCopyWith<HistoryContent> get copyWith => _$HistoryContentCopyWithImpl<HistoryContent>(this as HistoryContent, _$identity);

  /// Serializes this HistoryContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryContent&&(identical(other.id, id) || other.id == id)&&(identical(other.userRoomNumber, userRoomNumber) || other.userRoomNumber == userRoomNumber)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.completionTime, completionTime) || other.completionTime == completionTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userRoomNumber,startTime,completionTime,status,createdAt);

@override
String toString() {
  return 'HistoryContent(id: $id, userRoomNumber: $userRoomNumber, startTime: $startTime, completionTime: $completionTime, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $HistoryContentCopyWith<$Res>  {
  factory $HistoryContentCopyWith(HistoryContent value, $Res Function(HistoryContent) _then) = _$HistoryContentCopyWithImpl;
@useResult
$Res call({
 int id, String userRoomNumber, String startTime, String completionTime, String status, String createdAt
});




}
/// @nodoc
class _$HistoryContentCopyWithImpl<$Res>
    implements $HistoryContentCopyWith<$Res> {
  _$HistoryContentCopyWithImpl(this._self, this._then);

  final HistoryContent _self;
  final $Res Function(HistoryContent) _then;

/// Create a copy of HistoryContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userRoomNumber = null,Object? startTime = null,Object? completionTime = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userRoomNumber: null == userRoomNumber ? _self.userRoomNumber : userRoomNumber // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,completionTime: null == completionTime ? _self.completionTime : completionTime // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryContent].
extension HistoryContentPatterns on HistoryContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryContent value)  $default,){
final _that = this;
switch (_that) {
case _HistoryContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryContent value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String userRoomNumber,  String startTime,  String completionTime,  String status,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryContent() when $default != null:
return $default(_that.id,_that.userRoomNumber,_that.startTime,_that.completionTime,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String userRoomNumber,  String startTime,  String completionTime,  String status,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _HistoryContent():
return $default(_that.id,_that.userRoomNumber,_that.startTime,_that.completionTime,_that.status,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String userRoomNumber,  String startTime,  String completionTime,  String status,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _HistoryContent() when $default != null:
return $default(_that.id,_that.userRoomNumber,_that.startTime,_that.completionTime,_that.status,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryContent implements HistoryContent {
  const _HistoryContent({required this.id, required this.userRoomNumber, required this.startTime, required this.completionTime, required this.status, required this.createdAt});
  factory _HistoryContent.fromJson(Map<String, dynamic> json) => _$HistoryContentFromJson(json);

@override final  int id;
@override final  String userRoomNumber;
@override final  String startTime;
@override final  String completionTime;
@override final  String status;
@override final  String createdAt;

/// Create a copy of HistoryContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryContentCopyWith<_HistoryContent> get copyWith => __$HistoryContentCopyWithImpl<_HistoryContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryContent&&(identical(other.id, id) || other.id == id)&&(identical(other.userRoomNumber, userRoomNumber) || other.userRoomNumber == userRoomNumber)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.completionTime, completionTime) || other.completionTime == completionTime)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userRoomNumber,startTime,completionTime,status,createdAt);

@override
String toString() {
  return 'HistoryContent(id: $id, userRoomNumber: $userRoomNumber, startTime: $startTime, completionTime: $completionTime, status: $status, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$HistoryContentCopyWith<$Res> implements $HistoryContentCopyWith<$Res> {
  factory _$HistoryContentCopyWith(_HistoryContent value, $Res Function(_HistoryContent) _then) = __$HistoryContentCopyWithImpl;
@override @useResult
$Res call({
 int id, String userRoomNumber, String startTime, String completionTime, String status, String createdAt
});




}
/// @nodoc
class __$HistoryContentCopyWithImpl<$Res>
    implements _$HistoryContentCopyWith<$Res> {
  __$HistoryContentCopyWithImpl(this._self, this._then);

  final _HistoryContent _self;
  final $Res Function(_HistoryContent) _then;

/// Create a copy of HistoryContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userRoomNumber = null,Object? startTime = null,Object? completionTime = null,Object? status = null,Object? createdAt = null,}) {
  return _then(_HistoryContent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userRoomNumber: null == userRoomNumber ? _self.userRoomNumber : userRoomNumber // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,completionTime: null == completionTime ? _self.completionTime : completionTime // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
