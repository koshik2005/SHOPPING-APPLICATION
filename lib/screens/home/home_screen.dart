import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state.dart';
import '../../widgets/card.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/empty_states.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients && mounted) {
        final currentBranchKey = ref.read(selectedBranchProvider);
        final bannersLength = ref.read(dynamicBannersProvider(currentBranchKey)).value?.length ?? 0;
        if (bannersLength > 0) {
          final next = (_currentBanner + 1) % bannersLength;
          _bannerController.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentBranchKey = ref.watch(selectedBranchProvider);
    final branches = ref.watch(branchInfoListProvider);
    final activeBranch = branches[currentBranchKey];
    final merchants = ref.watch(merchantListProvider);
    final user = ref.watch(userProfileProvider);
    final categories = ref.watch(categoriesProvider(currentBranchKey));
    final localisationAsync = ref.watch(localisationProvider('en'));
    final i18n = localisationAsync.value ?? {};
    final String searchPlaceholder = i18n['home.search.placeholder'] ?? 'Search food, groceries, items...';

    if (activeBranch == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final greeting = _getGreeting();
    final userName = user.name.isNotEmpty ? user.name.split(' ').first : 'there';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _showBranchSelector(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DELIVERING TO', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Row(children: [
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Text(activeBranch.name, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
                const Icon(Icons.arrow_drop_down, size: 16),
              ]),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          final branchKey = ref.read(selectedBranchProvider);
          await ref.read(appConfigProvider.notifier).fetchConfig();
          await ref.read(branchInfoListProvider.notifier).fetchBranches();
          await ref.read(categoriesProvider(branchKey).notifier).fetchCategories();
          await ref.read(catalogProvider(branchKey).notifier).fetchProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('$greeting, $userName \uD83D\uDC4B', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () => context.go('/search'),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Icon(Icons.search),
                      const SizedBox(width: 8),
                      Text(searchPlaceholder, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const Spacer(),
                      Icon(Icons.mic, color: theme.colorScheme.onSurfaceVariant),
                    ]),
                  ),
                ),
              ),

              // Auto-scrolling dynamic banner carousel
              ref.watch(dynamicBannersProvider(currentBranchKey)).when(
                data: (bannersList) {
                  if (bannersList.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      SizedBox(
                        height: 148,
                        child: PageView.builder(
                          controller: _bannerController,
                          onPageChanged: (i) => setState(() => _currentBanner = i),
                          itemCount: bannersList.length,
                          itemBuilder: (context, index) {
                            final b = bannersList[index];
                            final title = b['title'] ?? '';
                            final subtitle = b['subtitle'] ?? '';
                            final actionRoute = b['actionRoute'] ?? '';
                            final List<dynamic> rawColors = b['backgroundColors'] ?? [];
                            final colors = rawColors.map((hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')))).toList();
                            if (colors.isEmpty) colors.addAll([const Color(0xFF1565C0), const Color(0xFF0D47A1)]);

                            return Padding(
                              padding: EdgeInsets.only(left: index == 0 ? 16 : 8, right: index == bannersList.length - 1 ? 16 : 8),
                              child: GestureDetector(
                                onTap: () {
                                  if (actionRoute.isNotEmpty) {
                                    context.push(actionRoute);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.all(20),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ]),
                                    ),
                                    const Icon(Icons.local_mall, size: 52, color: Colors.white24),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Dot indicators
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(bannersList.length, (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentBanner == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentBanner == i ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(height: 148, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => const SizedBox.shrink(),
              ),

              // Services Grid
              Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text(i18n['home.section.explore_services'] ?? 'Explore Services', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: categories.isEmpty
                    ? const HomeScreenSkeleton()
                    : LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 600 ? 6 : 4;
                        final activeServices = categories.where((c) => c.isAvailable).toList();
                        if (activeServices.isEmpty) return const NoBranchState();
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                          itemCount: activeServices.length,
                          itemBuilder: (context, index) {
                            final item = activeServices[index];
                            return GestureDetector(
                              onTap: () => context.push(_getRouteFromId(item.id)),
                              child: Column(children: [
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: theme.colorScheme.primary.withAlpha(30), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: _isEmoji(item.iconUrl)
                                      ? Center(child: Text(item.iconUrl, style: const TextStyle(fontSize: 28)))
                                      : Icon(_getIconFromString(item.iconUrl), size: 28, color: theme.colorScheme.onPrimaryContainer),
                                ),
                                const SizedBox(height: 6),
                                Text(item.label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                              ]),
                            );
                          },
                        );
                      }),
              ),
              const SizedBox(height: 24),

              // Popular Near You
              Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: Text(i18n['home.section.popular_near_you'] ?? 'Popular Near You', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: merchants.length,
                  itemBuilder: (context, index) {
                    final m = merchants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MerchantCard(
                        name: m.name, category: 'Service',
                        rating: m.rating.toStringAsFixed(1), distance: '1.2 km',
                        duration: '${m.averagePrepTimeMinutes} mins',
                        image: '\uD83E\uDD51',
                        onTap: () => context.push('/shop/food'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final localisationAsync = ref.read(localisationProvider('en'));
    final i18n = localisationAsync.value ?? {};
    final h = DateTime.now().hour;
    if (h < 12) return i18n['home.greeting.morning'] ?? 'Good morning';
    if (h < 17) return i18n['home.greeting.afternoon'] ?? 'Good afternoon';
    return i18n['home.greeting.evening'] ?? 'Good evening';
  }

  void _showBranchSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final current = ref.watch(selectedBranchProvider);
        final branches = ref.watch(branchInfoListProvider);
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Delivery Branch', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 16),
              ...branches.entries.map((entry) => RadioListTile<String>(
                title: Text(entry.value.name),
                subtitle: Text(entry.value.address, style: const TextStyle(fontSize: 12)),
                value: entry.key, groupValue: current,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(selectedBranchProvider.notifier).selectBranch(val);
                    ref.read(branchInfoListProvider.notifier).fetchBranches();
                    ref.read(categoriesProvider(val).notifier).fetchCategories();
                    Navigator.pop(context);
                  }
                },
              )),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconFromString(String name) {
    switch (name) {
      case 'restaurant': return Icons.restaurant;
      case 'local_grocery_store': return Icons.local_grocery_store;
      case 'directions_car': return Icons.directions_car;
      case 'inventory_2': return Icons.inventory_2;
      case 'local_pharmacy': return Icons.local_pharmacy;
      default: return Icons.category;
    }
  }

  bool _isEmoji(String s) {
    if (s.isEmpty) return false;
    final codeUnit = s.codeUnitAt(0);
    return codeUnit > 127;
  }

  String _getRouteFromId(String id) {
    if (id == 'rides') return '/rides';
    if (id == 'parcel') return '/parcel';
    return '/shop/$id';
  }
}
