import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, tonal, outlined, destructive }

class HyperLocalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final double? width;

  const HyperLocalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Tap target constraint (48dp height minimum)
    Widget buttonWidget;

    switch (variant) {
      case ButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _buildChild(),
        );
        break;
        
      case ButtonVariant.secondary:
        buttonWidget = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _buildChild(),
        );
        break;

      case ButtonVariant.tonal:
        buttonWidget = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _buildChild(),
        );
        break;

      case ButtonVariant.outlined:
        buttonWidget = OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.outline),
            foregroundColor: theme.colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _buildChild(),
        );
        break;

      case ButtonVariant.destructive:
        buttonWidget = ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.error,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: _buildChild(),
        );
        break;
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: buttonWidget,
    );
  }

  Widget _buildChild() {
    if (icon == null) {
      return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
