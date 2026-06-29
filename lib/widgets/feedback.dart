import 'package:flutter/material.dart';

class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFECEFF1),
                Color(0xFFF6F7F8),
                Color(0xFFECEFF1),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
            ),
          ),
        );
      },
    );
  }
}

class ShimmerMerchantCard extends StatelessWidget {
  const ShimmerMerchantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(width: double.infinity, height: 140, borderRadius: 12),
            SizedBox(height: 12),
            ShimmerLoader(width: 150, height: 16),
            SizedBox(height: 8),
            ShimmerLoader(width: 100, height: 12),
          ],
        ),
      ),
    );
  }
}

class SuccessConcentricCheck extends StatelessWidget {
  final IconData icon;
  
  const SuccessConcentricCheck({
    super.key,
    this.icon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFDCB9),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.secondaryContainer,
            ),
          ),
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: theme.colorScheme.error,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'No internet connection. Showing cached details.',
              style: TextStyle(color: theme.colorScheme.onError, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.onError,
              side: BorderSide(color: theme.colorScheme.onError),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

void showCustomToast(BuildContext context, String message) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).colorScheme.secondary,
    ),
  );
}
