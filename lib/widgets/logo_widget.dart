import 'package:flutter/material.dart';

/// A reusable widget to display the app logo with proper error handling
class LogoWidget extends StatelessWidget {
  final double width;
  final double height;
  final String heroTag;

  const LogoWidget({
    super.key,
    this.width = 120,
    this.height = 120,
    this.heroTag = 'logo',
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Image.asset(
            'assets/images/finance-app-by-nishan-high-resolution-logo.png',
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return AnimatedOpacity(
                opacity: frame != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading logo: $error');
              // Fallback to a text if image can't be loaded
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: width * 0.5,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Finance App\nby Nishan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: width * 0.15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
