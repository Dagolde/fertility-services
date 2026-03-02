import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../core/config/app_config.dart';

class CustomTextField extends StatelessWidget {
  final String name;
  final String? label;
  final String? labelText;
  final String? hintText;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<String? Function(String?)>? validators;
  final void Function(String?)? onChanged;
  final void Function(String?)? onSubmitted;
  final void Function()? onTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.name,
    this.label,
    this.labelText,
    this.hintText,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.validators,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.controller,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.contentPadding,
    this.fillColor,
    this.borderRadius,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || labelText != null) ...[
          Text(
            label ?? labelText!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        FormBuilderTextField(
          name: name,
          initialValue: initialValue,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          textAlign: textAlign,
          inputFormatters: inputFormatters,
          validator: validators != null
              ? (value) {
                  for (final validator in validators!) {
                    final result = validator(value);
                    if (result != null) return result;
                  }
                  return null;
                }
              : null,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? theme.inputDecorationTheme.fillColor,
            contentPadding: contentPadding ?? 
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: borderRadius ?? 
                  BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomSearchField extends StatelessWidget {
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;

  const CustomSearchField({
    super.key,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller?.text.isNotEmpty == true
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          borderSide: BorderSide(
            color: theme.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class CustomDropdownField<T> extends StatelessWidget {
  final String name;
  final String? label;
  final String? hintText;
  final T? initialValue;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final List<String? Function(T?)>? validators;
  final bool enabled;
  final Widget? prefixIcon;

  const CustomDropdownField({
    super.key,
    required this.name,
    this.label,
    this.hintText,
    this.initialValue,
    required this.items,
    this.onChanged,
    this.validators,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        FormBuilderDropdown<T>(
          name: name,
          initialValue: initialValue,
          items: items,
          onChanged: onChanged,
          enabled: enabled,
          validator: validators != null
              ? (value) {
                  for (final validator in validators!) {
                    final result = validator(value);
                    if (result != null) return result;
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomDateField extends StatelessWidget {
  final String name;
  final String? label;
  final String? hintText;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime?)? onChanged;
  final List<String? Function(DateTime?)>? validators;
  final bool enabled;
  final Widget? prefixIcon;
  final DatePickerMode initialDatePickerMode;

  const CustomDateField({
    super.key,
    required this.name,
    this.label,
    this.hintText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.validators,
    this.enabled = true,
    this.prefixIcon,
    this.initialDatePickerMode = DatePickerMode.day,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        FormBuilderDateTimePicker(
          name: name,
          initialValue: initialValue,
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 10)),
          onChanged: onChanged,
          enabled: enabled,
          inputType: InputType.date,
          initialDatePickerMode: initialDatePickerMode,
          validator: validators != null
              ? (value) {
                  for (final validator in validators!) {
                    final result = validator(value);
                    if (result != null) return result;
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon ?? const Icon(Icons.calendar_today),
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
