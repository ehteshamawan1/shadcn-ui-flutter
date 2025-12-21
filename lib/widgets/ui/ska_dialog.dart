import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import 'ska_button.dart';

/// SKA-DAN themed dialog component matching React shadcn/ui dialog
class SkaDialog {
  /// Show a standard dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
    double? maxWidth,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? 500,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: AppSpacing.p6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.lgSemibold.copyWith(
                        color: AppColors.cardForeground,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTypography.sm.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: AppSpacing.p6,
                  child: content,
                ),
              ),
              // Actions
              if (actions != null && actions.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: AppSpacing.p6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show an alert dialog with OK button
  static Future<void> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String okText = 'OK',
    VoidCallback? onOk,
  }) {
    return show(
      context: context,
      title: title,
      content: Text(
        message,
        style: AppTypography.sm.copyWith(color: AppColors.foreground),
      ),
      actions: [
        SkaButton(
          text: okText,
          onPressed: () {
            Navigator.of(context).pop();
            onOk?.call();
          },
        ),
      ],
    );
  }

  /// Show a confirmation dialog with Cancel and Confirm buttons
  static Future<bool> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = 'Annuller',
    String confirmText = 'Bekræft',
    bool destructive = false,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      content: Text(
        message,
        style: AppTypography.sm.copyWith(color: AppColors.foreground),
      ),
      actions: [
        SkaButton(
          text: cancelText,
          variant: ButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SkaButton(
          text: confirmText,
          variant: destructive ? ButtonVariant.destructive : ButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    return result ?? false;
  }

  /// Show a loading dialog
  static void showLoading({
    required BuildContext context,
    String? message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.radiusLg,
        ),
        child: Padding(
          padding: AppSpacing.p6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: AppTypography.sm.copyWith(
                    color: AppColors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Dismiss the current dialog
  static void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Bottom sheet helper
class SkaBottomSheet {
  /// Show a bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    required Widget content,
    List<Widget>? actions,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.top(AppRadius.lg),
      ),
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: AppSpacing.symmetric(
                horizontal: AppSpacing.s6,
                vertical: AppSpacing.s4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.lgSemibold.copyWith(
                      color: AppColors.cardForeground,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.sm.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.p6,
                child: content,
              ),
            ),
            // Actions
            if (actions != null && actions.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: AppSpacing.p6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
