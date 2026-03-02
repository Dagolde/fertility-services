import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;
  final Color? backgroundColor;
  final Color? spinnerColor;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
    this.backgroundColor,
    this.spinnerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitFadingCircle(
                      color: spinnerColor ?? Theme.of(context).primaryColor,
                      size: 50,
                    ),
                    if (loadingText != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingText!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LoadingButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final double? height;

  const LoadingButton({
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
        width: width,
        height: height ?? 48,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.primaryColor,
        ),
        child: child,
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final String? text;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 50,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinKitFadingCircle(
          color: color ?? Theme.of(context).primaryColor,
          size: size,
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: child,
    );
  }
}

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
  });

  static ShimmerLoading fromColors({
    Key? key,
    required Color baseColor,
    required Color highlightColor,
    required Widget child,
    Duration period = const Duration(milliseconds: 1500),
  }) {
    return ShimmerLoading(
      key: key,
      isLoading: true,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Shimmer(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: period,
        child: child,
      ),
    );
  }

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.period,
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class LoadingCard extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LoadingCard({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

class LoadingListTile extends StatelessWidget {
  final bool showAvatar;
  final bool showTrailing;

  const LoadingListTile({
    super.key,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: showAvatar
          ? const CircleAvatar(
              backgroundColor: Colors.grey,
            )
          : null,
      title: Container(
        height: 16,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 200,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      trailing: showTrailing
          ? Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : null,
    );
  }
}

class PullToRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;

  const PullToRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
