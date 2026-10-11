// freezed factory 파라미터의 @JsonKey는 생성된 필드에 적용되지만,
// 분석기가 invalid_annotation_target 경고를 내므로 파일 단위로 무시한다.
// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_request.freezed.dart';
part 'login_request.g.dart';

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String authCode,
    required String redirectUri,

    /// PKCE code verifier(#316). 서버가 DataGSM 토큰 교환에 함께 보낸다.
    @JsonKey(includeIfNull: false) String? codeVerifier,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}
