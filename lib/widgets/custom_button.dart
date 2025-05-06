import 'package:flutter/material.dart';

enum ButtonVariant { filled, outlined }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.filled,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = variant == ButtonVariant.filled
        ? ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            minimumSize: const Size(0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          )
        : OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            minimumSize: const Size(0, 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          );

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == ButtonVariant.filled
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
          )
        : icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8), Text(text)],
          )
        : Text(text);

    Widget button;
    if (variant == ButtonVariant.filled) {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      );
    }

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
