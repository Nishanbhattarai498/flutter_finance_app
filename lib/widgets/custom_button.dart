import 'package:flutter/material.dart';
import 'package:flutter_finance_app/theme/app_theme.dart';

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
    final borderRadius = BorderRadius.circular(16);
    final gradient = const LinearGradient(
      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              )
            : Text(text);

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        backgroundColor: variant == ButtonVariant.filled
            ? Colors.transparent
            : Colors.white.withOpacity(0.04),
        foregroundColor: variant == ButtonVariant.filled
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: variant == ButtonVariant.outlined
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  width: 1.2,
                )
              : BorderSide.none,
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: variant == ButtonVariant.filled ? gradient : null,
          borderRadius: borderRadius,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
