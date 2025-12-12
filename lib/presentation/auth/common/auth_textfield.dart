import 'package:flutter/material.dart';
import 'package:project_setting/core/theme/color.dart';
import 'package:project_setting/core/theme/icon.dart';
import 'package:project_setting/core/theme/typography.dart';

enum AuthTextFieldType {
  text,
  email,
  password,
}

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

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  Color get _borderColor {
    if (_hasError) return WasherColor.errorColor;
    if (_isFocused) return WasherColor.baseGray700;
    return WasherColor.baseGray300;
  }

  bool get _isPassword => widget.type == AuthTextFieldType.password;
  bool get _isEmail => widget.type == AuthTextFieldType.email;

  TextInputType get _keyboardType {
    if (_isEmail) return TextInputType.emailAddress;
    return TextInputType.text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: WasherTypography.body1(WasherColor.baseGray700),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _borderColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _isPassword && _obscureText,
            keyboardType: _keyboardType,
            onChanged: widget.onChanged,
            textAlignVertical: TextAlignVertical.center,
            style: WasherTypography.body2(WasherColor.baseGray700),
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
        ),
        if (_hasError) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: WasherTypography.caption(WasherColor.errorColor),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    // 비밀번호 필드: 눈 아이콘으로 보이기/숨기기
    if (_isPassword) {
      return IconButton(
        icon: WasherIcon(
          type: _obscureText ? WasherIconType.eyeOff : WasherIconType.eye,
          size: 20,
          color: WasherColor.baseGray500,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    // 이메일 필드: @gsm.hs.kr 자동 표시
    if (_isEmail) {
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Text(
          '@ gsm.hs.kr',
          style: WasherTypography.body2(WasherColor.baseGray600),
        ),
      );
    }

    return null;
  }
}
