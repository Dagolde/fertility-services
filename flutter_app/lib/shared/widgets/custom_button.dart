import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

enum ButtonVariant {
  filled,
  outlined,
  text,
  elevated,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? theme.primaryColor : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? (isOutlined ? theme.primaryColor : Colors.white),
          ),
        ),
      ],
    );

    if (isOutlined) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(
              color: theme.primaryColor,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.borderRadius),
            ),
            padding: padding ?? const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          elevation: 2,
          shadowColor: theme.primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(AppConfig.borderRadius),
          ),
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
        child: child,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final String? tooltip;
  final bool isLoading;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                iconColor ?? theme.primaryColor,
              ),
            ),
          )
        : Icon(
            icon,
            color: iconColor ?? theme.primaryColor,
            size: size ?? 24,
          );

    return Material(
      color: backgroundColor ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: tooltip != null
              ? Tooltip(
                  message: tooltip!,
                  child: child,
                )
              : child,
        ),
      ),
    );
  }
}

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final String? label;
  final bool isLoading;

  const CustomFloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: isLoading ? null : onPressed,
        backgroundColor: backgroundColor ?? theme.primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        tooltip: tooltip,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    foregroundColor ?? Colors.white,
                  ),
                ),
              )
            : Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: backgroundColor ?? theme.primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      tooltip: tooltip,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Colors.white,
                ),
              ),
            )
          : Icon(icon),
    );
  }
}

class CustomChip extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final bool isSelected;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? textColor;
  final IconData? icon;
  final Widget? avatar;

  const CustomChip({
    super.key,
    required this.label,
    this.onPressed,
    this.onDeleted,
    this.isSelected = false,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.icon,
    this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (onPressed != null) {
      return FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onPressed?.call(),
        backgroundColor: backgroundColor,
        selectedColor: selectedColor ?? theme.primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? (textColor ?? theme.primaryColor)
              : (textColor ?? theme.textTheme.bodyMedium?.color),
        ),
        avatar: avatar,
        side: BorderSide(
          color: isSelected
              ? (selectedColor ?? theme.primaryColor)
              : theme.dividerColor,
        ),
      );
    }

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor),
      avatar: avatar,
      onDeleted: onDeleted,
      deleteIcon: onDeleted != null ? const Icon(Icons.close, size: 18) : null,
    );
  }
}

class CustomToggleButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback? onPressed;
  final IconData? icon;

  const CustomToggleButton({
    super.key,
    required this.text,
    required this.isSelected,
    this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.primaryColor
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
