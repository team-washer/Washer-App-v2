import 'package:flutter/material.dart';

class WasherTextButton extends StatelessWidget {
  final String text;
  final TextStyle typography;
  final Color color;
  final VoidCallback onPressed;

  const WasherTextButton({
    super.key,
    required this.text,
    required this.typography,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 33.5),
        backgroundColor: color,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1000),
        ),
      ),
      child: Text(
        text,
        style: typography,
      ),
    );
  }
}
