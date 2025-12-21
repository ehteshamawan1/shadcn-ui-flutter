import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// SKA-DAN themed input component matching React shadcn/ui input
class SkaInput extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final String? Function(String?)? validator;

  const SkaInput({
    super.key,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.initialValue,
    this.inputFormatters,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.smMedium.copyWith(
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          enabled: enabled,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          textInputAction: textInputAction,
          autofocus: autofocus,
          validator: validator,
          style: AppTypography.sm.copyWith(
            color: AppColors.foreground,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTypography.sm.copyWith(
              color: AppColors.mutedForeground,
            ),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        color: AppColors.mutedForeground,
                        size: 18,
                      ),
                      child: prefixIcon!,
                    ),
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12, left: 8),
                    child: IconTheme(
                      data: IconThemeData(
                        color: AppColors.mutedForeground,
                        size: 18,
                      ),
                      child: suffixIcon!,
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            filled: false,
            contentPadding: AppSpacing.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.radiusMd,
              borderSide: BorderSide(
                color: AppColors.disabled(AppColors.border),
                width: 1,
              ),
            ),
            errorText: error,
            errorStyle: AppTypography.xs.copyWith(
              color: AppColors.error,
            ),
          ),
        ),
        if (helper != null && error == null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            style: AppTypography.xs.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}

/// Password input with show/hide toggle
class SkaPasswordInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helper;
  final String? error;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefixIcon;

  const SkaPasswordInput({
    super.key,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.controller,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.prefixIcon,
  });

  @override
  State<SkaPasswordInput> createState() => _SkaPasswordInputState();
}

class _SkaPasswordInputState extends State<SkaPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SkaInput(
      label: widget.label,
      placeholder: widget.placeholder,
      helper: widget.helper,
      error: widget.error,
      controller: widget.controller,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      obscureText: _obscureText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

/// Search input with search icon
class SkaSearchInput extends StatelessWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SkaSearchInput({
    super.key,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SkaInput(
      placeholder: placeholder ?? 'Søg...',
      controller: controller,
      onChanged: onChanged,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}
