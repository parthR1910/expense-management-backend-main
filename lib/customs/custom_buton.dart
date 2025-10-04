import 'package:flutter/material.dart';

enum ButtonType { filled, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.filled,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ButtonType.filled:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? Colors.indigo,
              foregroundColor: textColor ?? Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: textColor ?? Colors.white),
            ),
          ),
        );

      case ButtonType.outlined:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: backgroundColor ?? Colors.indigo),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: backgroundColor ?? Colors.indigo),
            ),
          ),
        );
    }
  }
}
