import 'package:flutter/material.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';

class AppErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? customMessage;

  const AppErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final errorHandler = ErrorHandler();
    final message =
        customMessage ?? errorHandler.getUserFriendlyMessage(failure, context);
    final icon = errorHandler.getErrorIcon(failure);
    final color = errorHandler.getErrorColor(failure);
    final isRecoverable = errorHandler.isRecoverable(failure);
    final suggestedAction = errorHandler.getSuggestedAction(failure, context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  color: color,
                ),
            ],
          ),
          if (suggestedAction != null) ...[
            const SizedBox(height: 8),
            Text(
              suggestedAction,
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 14),
            ),
          ],
          if (isRecoverable && onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error widget for full-screen errors
class FullScreenErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  const FullScreenErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final errorHandler = ErrorHandler();
    final message = errorHandler.getUserFriendlyMessage(failure, context);
    final icon = errorHandler.getErrorIcon(failure);
    final color = errorHandler.getErrorColor(failure);
    final isRecoverable = errorHandler.isRecoverable(failure);
    final suggestedAction = errorHandler.getSuggestedAction(failure, context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: color.withValues(alpha: 0.7)),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (suggestedAction != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    suggestedAction,
                    style: TextStyle(
                      fontSize: 16,
                      color: color.withValues(alpha:  0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                if (isRecoverable && onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                if (onBack != null) ...[
                  if (isRecoverable && onRetry != null)
                    const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: TextButton.styleFrom(foregroundColor: color),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error widget for snackbar-style errors
class ErrorSnackBar extends SnackBar {
  ErrorSnackBar({
    super.key,
    required Failure failure,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) : super(
         content: Row(
           children: [
             Icon(
               ErrorHandler().getErrorIcon(failure),
               color: Colors.white,
               size: 20,
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Text(
                 failure.message,
                 style: const TextStyle(color: Colors.white),
               ),
             ),
             if (onRetry != null)
               TextButton(
                 onPressed: onRetry,
                 child: const Text(
                   'Retry',
                   style: TextStyle(color: Colors.white),
                 ),
               ),
             if (onDismiss != null)
               IconButton(
                 icon: const Icon(Icons.close, color: Colors.white, size: 20),
                 onPressed: onDismiss,
               ),
           ],
         ),
         backgroundColor: ErrorHandler().getErrorColor(failure),
         duration: const Duration(seconds: 4),
         behavior: SnackBarBehavior.floating,
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       );
}
