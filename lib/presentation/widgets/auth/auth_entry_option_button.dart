import 'package:flutter/material.dart';

class AuthEntryOptionButton extends StatelessWidget {
  final String title;
  final String description;
  final bool enabled;
  final VoidCallback? onPressed;
  final IconData icon;
  final String semanticsLabel;
  final String? semanticsHint;

  const AuthEntryOptionButton({
    super.key,
    required this.title,
    required this.description,
    required this.enabled,
    required this.onPressed,
    required this.icon,
    required this.semanticsLabel,
    this.semanticsHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = enabled ? Colors.white : theme.colorScheme.onSurface;
    final backgroundColor = enabled
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      hint: semanticsHint,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foregroundColor.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
