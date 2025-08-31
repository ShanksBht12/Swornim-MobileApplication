// widgets/client/dashboard/welcome_section.dart
import 'package:flutter/material.dart';
import 'package:swornim/main.dart';

class WelcomeSection extends StatelessWidget {
  final String? userName;
  final String? customMessage;

  const WelcomeSection({
    super.key,
    this.userName,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientContainer(
      gradient: GradientTheme.primaryGradient,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userName != null ? 'Welcome back, $userName!' : 'Welcome back!',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            customMessage ?? 'Ready to plan something unforgettable?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}