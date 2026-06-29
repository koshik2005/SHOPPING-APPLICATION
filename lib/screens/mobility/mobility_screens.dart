import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/button.dart';
import '../../widgets/input.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Book a Ride')),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFE0F2F1),
            child: const Center(
              child: Icon(Icons.directions_car, size: 84, color: Color(0xFF80CBC4)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choose a Ride', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  
                  // Bike Taxi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.two_wheeler, size: 28),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bike Taxi', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Quickest ride • 3 mins away', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text('\$5.00', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Auto Rickshaw
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.electric_rickshaw, size: 28),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Auto Rickshaw', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Eco ride • 5 mins away', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text('\$8.50', style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  HyperLocalButton(
                    label: 'Book Bike Taxi',
                    onPressed: () {
                      context.push('/processing');
                    },
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ParcelScreen extends StatelessWidget {
  const ParcelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Send Packages')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send Packages', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerLowest,
                      ),
                      child: const Column(
                        children: [
                          HyperLocalInput(
                            label: 'Sender Address',
                            placeholder: '123 Market St, San Francisco',
                            initialValue: '123 Market St, San Francisco',
                          ),
                          HyperLocalInput(
                            label: 'Recipient Address',
                            placeholder: 'Enter dropoff location',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.surfaceContainerLowest,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Package Category', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ChoiceChip(label: const Text('Documents'), selected: true, onSelected: (_) {}),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Apparel'), selected: false, onSelected: (_) {}),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('Box Item'), selected: false, onSelected: (_) {}),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HyperLocalButton(
              label: 'Check Fare Estimate',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }
}
