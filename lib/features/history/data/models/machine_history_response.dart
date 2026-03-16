import 'package:freezed_annotation/freezed_annotation.dart';

part 'machine_history_response.freezed.dart';
part 'machine_history_response.g.dart';

@freezed
abstract class MachineHistoryResponse with _$MachineHistoryResponse {
  const factory MachineHistoryResponse({
    required List<HistoryContent> content,
    required int pageNumber,
    required int pageSize,
    required int totalElements,
    required int totalPages,
    required bool last,
  }) = _MachineHistoryResponse;

  factory MachineHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$MachineHistoryResponseFromJson(json);
}

@freezed
abstract class HistoryContent with _$HistoryContent {
  const factory HistoryContent({
    required int id,
    required String userRoomNumber,
    required String startTime,
    required String completionTime,
    required String status,
    required String createdAt,
  }) = _HistoryContent;

  factory HistoryContent.fromJson(Map<String, dynamic> json) =>
      _$HistoryContentFromJson(json);
}
