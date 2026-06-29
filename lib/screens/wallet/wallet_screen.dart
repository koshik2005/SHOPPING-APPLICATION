import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state.dart';
import '../../core/session_manager.dart';
import '../../widgets/card.dart';
import '../../widgets/badge.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Read state
    final balance = ref.watch(walletProvider);
    final points = ref.watch(pointsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Rewards')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFE65100)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'TOTAL WALLET BALANCE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${balance.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await ref.read(walletRepositoryProvider).credit(
                                '87ef769c-d021-4f11-ba32-aafe812bb31c',
                                50.0,
                              );
                              final balanceData = await ref.read(walletRepositoryProvider).getBalance('87ef769c-d021-4f11-ba32-aafe812bb31c');
                              final balance = balanceData['balance']?.toDouble() ?? 50.0;
                              ref.read(walletProvider.notifier).setBalance(balance);
                              ref.read(pointsProvider.notifier).addPoints(500);
                              await SessionManager.updateWalletBalance(balance);
                            } catch (e) {
                              debugPrint('Credit failed: $e');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Add Funds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        height: 36,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: const Text('Send Cash', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Loyalty progress
            HyperLocalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Loyalty Program', style: theme.textTheme.titleMedium),
                      const HyperLocalBadge(label: 'Gold Tier', category: BadgeType.feature),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$points points out of 2,000 to Platinum',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: points / 2000,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.tertiary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transactions
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Green Market Fresh', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Grocery • Today, 12:05 PM'),
                    trailing: Text(
                      '-\$15.00',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Loaded Funds', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Card Load • Yesterday, 09:00 AM'),
                    trailing: Text(
                      '+\$50.00',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
