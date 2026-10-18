import 'package:flutter/material.dart';
import 'package:task_track/core/constants/app_colors.dart';
import 'package:task_track/core/constants/app_constants.dart';
import 'package:task_track/shared/widgets/glass_card.dart';

class GlassTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;

  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.onTap,
    this.onTapOutside,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return GlassCard(
      level: GlassLevel.input,
      blurEnabled: false,
      clipBehavior: Clip.none,
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      fillColor: !enabled
          ? p.glassFillSubtle.withValues(alpha: 0.55)
          : readOnly
          ? p.glassFill
          : null,
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        autocorrect: autocorrect,
        enableSuggestions: enableSuggestions,
        readOnly: readOnly,
        obscureText: obscureText,
        enabled: enabled,
        autofocus: autofocus,
        onTap: onTap,
        onTapOutside: onTapOutside,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: enabled ? p.textPrimary : p.textSecondary),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          counterText: '',
          fillColor: Colors.transparent,
        ),
      ),
    );
  }
}
