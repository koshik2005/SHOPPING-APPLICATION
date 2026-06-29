import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state.dart';
import '../../widgets/card.dart';
import '../../widgets/button.dart';
import '../../widgets/feedback.dart';


class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  double _distanceRange = 3.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;
    
    final currentBranchKey = ref.watch(selectedBranchProvider);
    final catalogList = ref.watch(catalogProvider(currentBranchKey));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search food, groceries, items...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse Catalog',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: catalogList.length,
                      itemBuilder: (context, index) {
                        final item = catalogList[index];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: HyperLocalCard(
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFDBC8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(item.imageUrl.contains('avocado') ? '🥑' : '🍞', style: const TextStyle(fontSize: 24)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: theme.textTheme.titleSmall),
                                      const SizedBox(height: 2),
                                      Text(item.description, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 72,
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ref.read(dynamicCartProvider.notifier).addItem(item, 'Standard');
                                      showCustomToast(context, '${item.name} added to cart!');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (isLargeScreen) ...[
            const VerticalDivider(width: 1),
            Container(
              width: 280,
              color: theme.colorScheme.surfaceContainerLow,
              padding: const EdgeInsets.all(24),
              child: _buildFilterContent(context),
            )
          ]
        ],
      ),
    );
  }

  void _showFilter(BuildContext context) {
    if (MediaQuery.of(context).size.width >= 600) return; // Persistent on tablet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: _buildFilterContent(context),
        );
      },
    );
  }

  Widget _buildFilterContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter & Sort',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 24),
        Text('Sort Options', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(label: const Text('Top Rated'), selected: true, onSelected: (_) {}),
            ChoiceChip(label: const Text('Distance'), selected: false, onSelected: (_) {}),
            ChoiceChip(label: const Text('Price'), selected: false, onSelected: (_) {}),
          ],
        ),
        const SizedBox(height: 24),
        Text('Distance Range (${_distanceRange.toStringAsFixed(1)} mi)', style: theme.textTheme.titleSmall),
        Slider(
          value: _distanceRange,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          onChanged: (val) {
            setState(() {
              _distanceRange = val;
            });
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: HyperLocalButton(
                label: 'Reset',
                variant: ButtonVariant.outlined,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HyperLocalButton(
                label: 'Apply',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
