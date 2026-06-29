import 'package:flutter/material.dart';

class HyperLocalCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;

  const HyperLocalCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final cardWidget = Card(
      color: color ?? theme.colorScheme.surfaceContainerLowest,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap == null) return cardWidget;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: cardWidget,
    );
  }
}

class MerchantCard extends StatelessWidget {
  final String name;
  final String category;
  final String rating;
  final String distance;
  final String duration;
  final String image;
  final VoidCallback? onTap;

  const MerchantCard({
    super.key,
    required this.name,
    required this.category,
    required this.rating,
    required this.distance,
    required this.duration,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return HyperLocalCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDBC8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    image,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '20% OFF',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: Colors.yellow[700]),
              const SizedBox(width: 4),
              Text(rating, style: theme.textTheme.labelMedium),
              const SizedBox(width: 16),
              const Icon(Icons.navigation_outlined, size: 16),
              const SizedBox(width: 4),
              Text(distance, style: theme.textTheme.labelMedium),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16),
              const SizedBox(width: 4),
              Text(duration, style: theme.textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
