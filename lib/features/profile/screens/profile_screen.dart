import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/user_stats_model.dart';

final userStatsProvider = FutureProvider<UserStatsModel?>((ref) async {
  final userId = SupabaseConfig.userId;
  if (userId == null) return null;

  final response = await SupabaseConfig.client
      .from('user_stats')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  if (response == null) return null;
  return UserStatsModel.fromJson(response);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = SupabaseConfig.userId;
  if (userId == null) return null;

  final response = await SupabaseConfig.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  return response;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            profile.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (p) => _ProfileHeader(profile: p),
            ),
            const SizedBox(height: 24),

            // Stats section
            stats.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (s) => _StatsSection(stats: s),
            ),

            const SizedBox(height: 24),

            // Subscription card
            _SubscriptionCard(),

            const SizedBox(height: 24),

            // Sign out — will be re-enabled when auth is set up.
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton.icon(
            //     onPressed: () async {
            //       await SupabaseConfig.auth.signOut();
            //       if (context.mounted) context.go('/login');
            //     },
            //     icon: const Icon(Icons.logout_rounded),
            //     label: const Text('Sign Out'),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _ProfileHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?['first_name'] ?? 'Learner';

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.toString().isNotEmpty ? name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name.toString(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          SupabaseConfig.currentUser?.email ?? '',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final UserStatsModel? stats;

  const _StatsSection({this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.streakFire, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats?.currentStreak ?? 0} Day Streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Longest: ${stats?.longestStreak ?? 0} days',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Stats grid
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.auto_stories_rounded,
                value: '${stats?.totalEditionsCompleted ?? 0}',
                label: 'Editions',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.style_rounded,
                value: '${stats?.totalCardsRead ?? 0}',
                label: 'Cards Read',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.timer_rounded,
                value: '${(stats?.totalTimeSeconds ?? 0) ~/ 60}m',
                label: 'Time Spent',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.bookmark_rounded,
                value: '${stats?.totalCardsSaved ?? 0}',
                label: 'Saved',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.star_rounded,
                value: '${stats?.xpPoints ?? 0}',
                label: 'XP Points',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.trending_up_rounded,
                value: 'Lv ${stats?.level ?? 1}',
                label: 'Level',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Free',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Upgrade to Pro',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '15-min editions, explore mode, saved library & more.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Coming Soon'),
                      content: const Text(
                        'Pro subscriptions are coming soon! '
                        'Stay tuned for unlimited editions, '
                        'explore mode, and more.',
                      ),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Upgrade'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
