import 'package:flutter/material.dart';
import 'package:washer/core/theme/color.dart';
import 'package:washer/core/theme/icon.dart';
import 'package:washer/core/theme/spacing.dart';
import 'package:washer/core/theme/typography.dart';

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

  bool get _hasError => widget.errorText?.isNotEmpty ?? false;

  Color get _borderColor {
    if (_hasError) return WasherColor.errorColor;
    if (_isFocused) return WasherColor.baseGray700;
    return WasherColor.baseGray300;
  }

  bool get _isPassword => widget.type == AuthTextFieldType.password;
  bool get _isEmail => widget.type == AuthTextFieldType.email;

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

  Widget _buildLabel() {
    return Text(
      widget.label,
      style: WasherTypography.body1(WasherColor.baseGray700),
    );
  }

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

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
