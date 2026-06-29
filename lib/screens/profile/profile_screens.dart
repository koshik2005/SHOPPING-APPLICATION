import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/state.dart';
import '../../core/session_manager.dart';
import '../../widgets/card.dart';
import '../../widgets/button.dart';
import '../../widgets/empty_states.dart';
import '../../widgets/input.dart';
import '../../lip/lip_di.dart';
import '../../lip/domain/map_provider.dart' as lip;
import 'package:latlong2/latlong.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Read dynamic user profile from state provider
    final user = ref.watch(userProfileProvider);
    final initials = user.name.split(' ').map((e) => e[0]).join().toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            HyperLocalCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      initials.isNotEmpty ? initials : 'HL',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: theme.textTheme.titleLarge),
                  Text(
                    '${user.email} • ID: HL-88219',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerLowest,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.manage_accounts, color: theme.colorScheme.primary),
                    title: const Text('Account Details'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.home_outlined, color: theme.colorScheme.primary),
                    title: const Text('My Addresses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/address'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.support_agent, color: theme.colorScheme.primary),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/support'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.settings, color: theme.colorScheme.primary),
                    title: const Text('Preferences & Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            HyperLocalButton(
              label: 'Log Out',
              variant: ButtonVariant.outlined,
              onPressed: () => _confirmLogout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of your HyperLocal account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            onPressed: () async {
              Navigator.pop(ctx);
              await SessionManager.clearSession();
              ref.read(authStateProvider.notifier).state = false;
              ref.read(userProfileProvider.notifier).updateProfile(UserProfile(
                name: '', email: '', mobileNumber: '', gender: '', dob: '',
                profilePhotoUrl: '', addresses: [], savedPlaces: {},
                preferredLanguage: 'English', preferredCurrency: 'USD', themePreference: 'light',
              ));
              ref.read(walletProvider.notifier).setBalance(0.0);
              if (context.mounted) context.go('/');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = true;
  bool _marketingEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProfileProvider);
    final config = ref.watch(appConfigProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          HyperLocalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security Preferences', style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Biometric Verification (FaceID)'),
                  value: _biometricEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _biometricEnabled = val;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Marketing Offer Messages'),
                  value: _marketingEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _marketingEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HyperLocalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User Details (API loaded)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Gender Preference'),
                    Text(user.gender),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saved Language'),
                    Text(user.preferredLanguage),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saved Currency'),
                    Text(user.preferredCurrency),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          HyperLocalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Configuration', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Build Version'),
                    Text(config.appVersion),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('API Endpoint Version'),
                    Text(config.apiVersion),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final faqs = ref.watch(faqProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Support Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'How can we help you?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our help centers and safety networks are active 24/7',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: HyperLocalCard(
                    onTap: () => context.push('/chat'),
                    child: Column(
                      children: [
                        Icon(Icons.chat, size: 32, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        const Text('Live Chat support', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Rider connection', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HyperLocalCard(
                    onTap: () {},
                    child: Column(
                      children: [
                        Icon(Icons.phone, size: 32, color: theme.colorScheme.tertiary),
                        const SizedBox(height: 8),
                        const Text('Emergency Call', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Open helpline', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Dynamic FAQ Expansion list
            Text('Frequently Asked Questions', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...faqs.map((faq) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: HyperLocalCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(faq.answer, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            HyperLocalCard(
              color: const Color(0xFFFFEBEE),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sos, size: 36, color: Color(0xFFC62828)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMERGENCY SOS',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: const Color(0xFFC62828),
                              ),
                            ),
                            const Text(
                              'Report rider security threats immediately',
                              style: TextStyle(color: Color(0xFFC62828), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  HyperLocalButton(
                    label: 'Call Emergency Team',
                    variant: ButtonVariant.destructive,
                    onPressed: () {},
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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'sender': 'agent', 'text': "Hi Alex! I'm Sarah from Support. How can I help you regarding your order #HL-9824?", 'time': '12:06 PM'},
    {'sender': 'user', 'text': 'Hi Sarah, the delivery status says "Preparing" but the driver is still active at the shop.', 'time': '12:08 PM'},
    {'sender': 'agent', 'text': 'I verified that. Rajesh is picking up bakery boxes. He should depart in 2 minutes!', 'time': '12:09 PM'},
  ];

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({'sender': 'user', 'text': text, 'time': 'Just now'});
      });
      _msgController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Support Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg['text'] as String,
                          style: TextStyle(
                            color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: theme.colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Failed to load notifications: $err')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyNotificationsState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: HyperLocalCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.isRead ? theme.colorScheme.surfaceContainer : theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: item.isRead ? theme.colorScheme.outline : theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.timestamp,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Delivery Address'),
        content: TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Enter complete address details...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _addressCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final addr = _addressCtrl.text.trim();
              if (addr.isNotEmpty) {
                ref.read(userProfileProvider.notifier).addAddress(addr);
                _addressCtrl.clear();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address successfully saved!'), backgroundColor: Color(0xFF006D5B)),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: user.addresses.isEmpty
          ? EmptySavedAddressesState(onAddAddress: _showAddAddressDialog)
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: user.addresses.length,
              itemBuilder: (context, index) {
                final addr = user.addresses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: HyperLocalCard(
                    child: Row(
                      children: [
                        Icon(Icons.home_outlined, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(index == 0 ? 'Primary Address' : 'Secondary Address', style: theme.textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Text(addr, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          onPressed: () {
                            final list = List<String>.from(user.addresses)..removeAt(index);
                            ref.read(userProfileProvider.notifier).updateProfile(user.copyWith(addresses: list));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Address deleted.')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: user.addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddAddressDialog,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
            )
          : null,
    );
  }
}

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key});

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  LatLng? _userLoc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final lipRepo = ref.read(locationRepositoryProvider);
      final pos = await lipRepo.getCurrentLocation();
      if (pos != null && mounted) {
        setState(() {
          _userLoc = LatLng(pos.latitude, pos.longitude);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBranch = ref.watch(selectedBranchProvider);
    final branches = ref.watch(branchInfoListProvider);
    final activeBranch = branches[selectedBranch] ?? branches.values.first;

    if (_loading || _userLoc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location Map Explorer')),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6D00)),
        ),
      );
    }

    final mProvider = ref.watch(mapProvider);
    final center = _userLoc!;
    final markerService = ref.read(markerServiceProvider);
    
    markerService.updateMarker(lip.MapMarker(
      id: 'customer_me',
      position: center,
      type: lip.MarkerType.customer,
      title: 'You',
    ));

    for (final b in branches.values) {
      markerService.updateMarker(lip.MapMarker(
        id: 'branch_${b.id}',
        position: LatLng(b.latitude, b.longitude),
        type: lip.MarkerType.branch,
        title: b.name,
      ));
    }

    final mapMarkers = markerService.clusterMarkers(markerService.getMarkers(), 13.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Location Map Explorer')),
      body: Stack(
        children: [
          mProvider.buildMapWidget(
            initialCenter: center,
            initialZoom: 13.0,
            routePolyline: [],
            markers: mapMarkers,
            onCameraMove: (newCenter) {},
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_searching, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active Geofencing Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Serving radius: ${activeBranch.deliveryRadiusMiles} miles from main hub', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
