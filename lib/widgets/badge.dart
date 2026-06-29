import 'package:flutter/material.dart';

enum BadgeType { promotional, status, feature, delivery, completed, destructive }

class HyperLocalBadge extends StatelessWidget {
  final String label;
  final BadgeType category;

  const HyperLocalBadge({
    super.key,
    required this.label,
    this.category = BadgeType.promotional,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    Border? border;

    switch (category) {
      case BadgeType.promotional:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        break;
      case BadgeType.status:
        backgroundColor = theme.colorScheme.secondary;
        textColor = theme.colorScheme.onSecondary;
        break;
      case BadgeType.feature:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case BadgeType.delivery:
        backgroundColor = theme.colorScheme.tertiary;
        textColor = theme.colorScheme.onTertiary;
        break;
      case BadgeType.completed:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.tertiary;
        border = Border.all(color: theme.colorScheme.tertiary);
        break;
      case BadgeType.destructive:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
