import 'package:flutter/material.dart';

class NetworkImageWithFallback extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallbackWidget;
  final BorderRadius? borderRadius;
  final bool isCircular;

  const NetworkImageWithFallback({
    Key? key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackWidget,
    this.borderRadius,
    this.isCircular = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Default fallback widget
    final defaultFallback = fallbackWidget ?? 
        Icon(
          Icons.person,
          size: (width ?? 40) / 2,
          color: colorScheme.primary,
        );

    // If no image URL, show fallback
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildContainer(defaultFallback);
    }

    // Validate URL format
    if (!_isValidUrl(imageUrl!)) {
      return _buildContainer(defaultFallback);
    }

    return _buildContainer(
              ClipRRect(
          borderRadius: borderRadius ?? (isCircular ? BorderRadius.circular((width ?? 40) / 2) : BorderRadius.zero),
          child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Network image error: $error');
            // Log more details for debugging
            if (error.toString().contains('host lookup')) {
              debugPrint('DNS resolution failed for: $imageUrl');
            } else if (error.toString().contains('timeout')) {
              debugPrint('Image load timeout for: $imageUrl');
            } else if (error.toString().contains('connection')) {
              debugPrint('Connection failed for: $imageUrl');
            }
            return defaultFallback;
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: borderRadius ?? (isCircular ? BorderRadius.circular((width ?? 40) / 2) : null),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
          // Add timeout and retry configuration
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
        ),
      ),
    );
  }

  Widget _buildContainer(Widget child) {
    if (isCircular) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.1),
        ),
        child: Center(child: child),
      );
    }
    
    if (borderRadius != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.grey.withOpacity(0.1),
        ),
        child: ClipRRect(
          borderRadius: borderRadius!,
          child: child,
        ),
      );
    }
    
    return child;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
}

// Convenience widget for circular profile images
class ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;
  final IconData? fallbackIcon;

  const ProfileImage({
    Key? key,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
    this.fallbackIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return NetworkImageWithFallback(
      imageUrl: imageUrl,
      width: size,
      height: size,
      isCircular: true,
      fallbackWidget: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? colorScheme.primary.withOpacity(0.1),
        ),
        child: Icon(
          fallbackIcon ?? Icons.person,
          size: size / 2,
          color: colorScheme.primary,
        ),
      ),
    );
  }
} 