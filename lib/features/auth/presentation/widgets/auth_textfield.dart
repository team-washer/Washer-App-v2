import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

/// 인증 입력 테스트필드 유상
enum AuthTextFieldType {
  text,
  email,
  password,
}

/// 로그인 입력 필드 (징초, 비밀번호, 메일) 위젯
/// 
/// 기능:
/// - 징초 가늤린 완료 단이 요구사항 나타내기
/// - 비밀번호 비뱀 토글
/// - 메일 번 겄사 주차 타인 좌측 내용
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.errorText,
    this.type = AuthTextFieldType.text,
    this.onChanged,
  });

  final String label;
  final String hintText;
  final TextEditingController? controller;
  final String? errorText;
  final AuthTextFieldType type;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  /// 포커스 상태 변화 리스너
  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  bool get _hasError => widget.errorText?.isNotEmpty ?? false;

  /// 에러 여부에 따른 테두리 색으로 결정
  Color get _borderColor {
    if (_hasError) return WasherColor.errorColor;
    if (_isFocused) return WasherColor.baseGray700;
    return WasherColor.baseGray300;
  }

  bool get _isPassword => widget.type == AuthTextFieldType.password;
  bool get _isEmail => widget.type == AuthTextFieldType.email;

  /// 입력 유형에 따른 키보드 유형 결정
  TextInputType get _keyboardType {
    return _isEmail ? TextInputType.emailAddress : TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: AppSpacing.v8),
        _buildTextField(),
        if (_hasError) _buildErrorText(),
      ],
    );
  }

  /// 레이블 텍스트 렌더링
  Widget _buildLabel() {
    return Text(
      widget.label,
      style: WasherTypography.body1(WasherColor.baseGray700),
    );
  }

  /// 에러 메시지 렌더링
  Widget _buildErrorText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.v4),
        Text(
          widget.errorText!,
          style: WasherTypography.caption(WasherColor.errorColor),
        ),
      ],
    );
  }

  /// 텍스트필드 렌더링
  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: TextField(
        maxLines: 1,
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: _isPassword && _obscureText,
        keyboardType: _keyboardType,
        onChanged: widget.onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: WasherTypography.body1(WasherColor.baseGray700),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: WasherTypography.body2(WasherColor.baseGray200),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          suffixIcon: _buildSuffixIcon(),
          isDense: true,
        ),
      ),
    );
  }

  /// 비밀번호/이메일 전용 접미사 아이콘 렌더링
  Widget? _buildSuffixIcon() {
    if (_isPassword) {
      return IconButton(
        icon: WasherIcon(
          type: _obscureText ? WasherIconType.eyeOff : WasherIconType.eye,
          size: 20,
          color: WasherColor.baseGray200,
        ),
        onPressed: _togglePasswordVisibility,
      );
    }

    if (_isEmail) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '@ gsm.hs.kr',
            style: WasherTypography.body2(WasherColor.baseGray400),
          ),
        ),
      );
    }

    return null;
  }

  /// 비밀번호 표시/숨김 전환
  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
