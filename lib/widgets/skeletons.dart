import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer box for building skeleton layouts.
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const SkeletonBox({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceContainerLow,
      highlightColor: theme.colorScheme.surfaceContainerHigh,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Skeleton loader for the Home Screen.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar skeleton
            const SkeletonBox(width: double.infinity, height: 48, borderRadius: 24),
            const SizedBox(height: 16),
            // Banner skeleton
            const SkeletonBox(width: double.infinity, height: 140, borderRadius: 16),
            const SizedBox(height: 24),
            // Section label
            const SkeletonBox(width: 140, height: 20),
            const SizedBox(height: 12),
            // Category grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 8,
              itemBuilder: (_, __) => Column(
                children: const [
                  SkeletonBox(width: 60, height: 60, borderRadius: 30),
                  SizedBox(height: 6),
                  SkeletonBox(width: 48, height: 12),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SkeletonBox(width: 160, height: 20),
            const SizedBox(height: 12),
            // Merchant cards
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: const SkeletonBox(width: double.infinity, height: 100, borderRadius: 16),
            )),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for the Shop / Products Screen.
class ShopScreenSkeleton extends StatelessWidget {
  const ShopScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const SkeletonBox(width: double.infinity, height: 200, borderRadius: 16),
    );
  }
}

/// Skeleton loader for the Orders Screen.
class OrdersScreenSkeleton extends StatelessWidget {
  const OrdersScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: const [
              SkeletonBox(width: 64, height: 64, borderRadius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: double.infinity, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 24, borderRadius: 12),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}

/// Skeleton for Profile Screen header + settings.
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar + name
          const SkeletonBox(width: 80, height: 80, borderRadius: 40),
          const SizedBox(height: 12),
          const SkeletonBox(width: 160, height: 20),
          const SizedBox(height: 8),
          const SkeletonBox(width: 220, height: 14),
          const SizedBox(height: 24),
          // Settings rows
          ...List.generate(6, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: const [
                SkeletonBox(width: 40, height: 40, borderRadius: 20),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(width: double.infinity, height: 16)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Skeleton for Wallet Screen.
class WalletScreenSkeleton extends StatelessWidget {
  const WalletScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonBox(width: double.infinity, height: 160, borderRadius: 20),
          const SizedBox(height: 24),
          const SkeletonBox(width: 160, height: 20),
          const SizedBox(height: 12),
          ...List.generate(4, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: const SkeletonBox(width: double.infinity, height: 56, borderRadius: 12),
          )),
        ],
      ),
    );
  }
}
