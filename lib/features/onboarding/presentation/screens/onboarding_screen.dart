import 'package:flutter/material.dart';
import 'package:openhearth_design/openhearth_design.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/profile_providers.dart';
import '../../../profiles/domain/entities/profile.dart';
import '../../../profiles/presentation/profile_ui_constants.dart';

const _kOnboardingKey = 'onboarding_v1';

/// Full-screen welcome shown on first launch.
/// After tapping "Get Started" the key is written and the user lands
/// on the dashboard. On every subsequent launch the router skips this screen.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Profile setup state (page 1)
  String _selectedEmoji = kDefaultProfileEmoji;
  String _selectedColor = kDefaultProfileColor;
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageController.nextPage(
        duration: OhMotion.deliberate,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await const FlutterSecureStorage().write(
      key: _kOnboardingKey,
      value: 'complete',
    );
    if (mounted) context.go('/dashboard');
  }

  Future<void> _createProfileAndNext() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    final now = DateTime.now();
    final profile = Profile(
      id: const Uuid().v4(),
      name: name,
      colorHex: _selectedColor,
      avatarEmoji: _selectedEmoji,
      isDefault: true,
      createdAt: now,
      modifiedAt: now,
    );
    final result = await ref
        .read(profileRepositoryProvider)
        .createProfile(profile);
    Profile? created;
    result.when(
      success: (p) => created = p,
      failure: (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save profile')),
          );
        }
      },
    );
    if (created == null) return;
    await ref.read(activeProfileProvider.notifier).setActive(created);
    if (mounted) _next();
  }

  void _showEmojiPicker() {
    showModalBottomSheet<String>(
      context: context,
      builder: (_) => Padding(
        padding: OhSpacing.insetMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose emoji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: kProfileEmojis.length,
              itemBuilder: (_, index) {
                final emoji = kProfileEmojis[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ).then((picked) {
      if (picked != null && mounted) {
        setState(() => _selectedEmoji = picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (p) => setState(() => _page = p),
          children: [
            _WelcomePage(onNext: _next),
            _buildProfileSetupPage(),
            _FeaturesPage(onFinish: _finish),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSetupPage() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 48),
          Text(
            "Who's setting this up?",
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Large tappable emoji
          GestureDetector(
            onTap: _showEmojiPicker,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: profileColor(_selectedColor).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: profileColor(_selectedColor),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _selectedEmoji,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: OhSpacing.sm),
          Text(
            'Tap to change',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: OhSpacing.lg),

          // Name field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: OhSpacing.lg),

          // Color swatches
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kProfileColors.map((hex) {
              final isSelected = hex == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = hex),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: profileColor(hex),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const Spacer(),

          // "That's me" button
          FilledButton(
            onPressed: _createProfileAndNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text("That's me \u2192"),
          ),
          const SizedBox(height: 12),

          // Skip button
          TextButton(onPressed: _next, child: const Text('Skip \u2192')),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 1: Welcome ───────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.home_work_outlined,
              size: 56,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Still Life',
            style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Document what you own.\nKnow what it\'s worth.',
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Get Started'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Page 3: Features ─────────────────────────────────────────────────────────

class _FeaturesPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _FeaturesPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const features = [
      (
        Icons.inventory_2_outlined,
        'Inventory',
        'Catalog items with photos, receipts & serial numbers',
      ),
      (
        Icons.bar_chart_outlined,
        'Financial dashboard',
        'Track total value, depreciation trends, and room breakdowns',
      ),
      (
        Icons.shield_outlined,
        'Insurance',
        'Record policies and spot coverage gaps',
      ),
      (
        Icons.build_outlined,
        'Maintenance',
        'Schedule tasks and get warranty expiry reminders',
      ),
      (
        Icons.wifi_outlined,
        'LAN sync',
        'Sync across devices on your home Wi-Fi — no cloud required',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Everything in one place',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: OhSpacing.sm),
          Text(
            'Your data stays on your device — no account needed.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(f.$1, color: cs.primary, size: 24),
                  const SizedBox(width: OhSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          f.$3,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onFinish,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('Let\'s Go'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
