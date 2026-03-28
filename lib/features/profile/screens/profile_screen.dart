import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/core/demo/demo_data.dart';
import 'package:glintup/data/models/user_stats_model.dart';
import 'package:glintup/data/repositories/auth_repository.dart';

final userStatsProvider = FutureProvider<UserStatsModel?>((ref) async {
  try {
    final userId = SupabaseConfig.userId;
    if (userId == null) return DemoData.getSampleStats();

    final response = await SupabaseConfig.client
        .from('user_stats')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return DemoData.getSampleStats();
    return UserStatsModel.fromJson(response);
  } catch (_) {
    return DemoData.getSampleStats();
  }
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final userId = SupabaseConfig.userId;
    if (userId == null) return DemoData.getSampleProfile();

    final response = await SupabaseConfig.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return response ?? DemoData.getSampleProfile();
  } catch (_) {
    return DemoData.getSampleProfile();
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with settings
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                  onPressed: () => context.push('/settings'),
                ),
              ),

              // Profile header
              profile.when(
                loading: () => const SizedBox(height: 120),
                error: (_, _) =>
                    _ProfileHeader(profile: DemoData.getSampleProfile()),
                data: (p) => _ProfileHeader(profile: p),
              ),
              const SizedBox(height: 28),

              // Streak card
              stats.when(
                loading: () => const SizedBox(height: 120),
                error: (_, _) =>
                    _StreakCard(stats: DemoData.getSampleStats()),
                data: (s) => _StreakCard(stats: s),
              ),
              const SizedBox(height: 28),

              // Stats section
              stats.when(
                loading: () => const SizedBox(height: 200),
                error: (_, _) =>
                    _StatsGrid(stats: DemoData.getSampleStats()),
                data: (s) => _StatsGrid(stats: s),
              ),
              const SizedBox(height: 28),

              // Topics section
              _TopicsSection(),
              const SizedBox(height: 28),

              // Upgrade to Pro
              _UpgradeButton(),
              const SizedBox(height: 16),

              // Sign Out
              Center(
                child: TextButton(
                  onPressed: () async {
                    await AuthRepository().signOut();
                    if (context.mounted) context.go('/login');
                  },
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _ProfileHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?['first_name'] ?? 'Learner';

    return Center(
      child: Column(
        children: [
          // Avatar with gold ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: AppColors.goldGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    name.toString().isNotEmpty ? name[0].toUpperCase() : 'G',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.toString(),
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Member since 2024',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Streak Card ──────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final UserStatsModel? stats;

  const _StreakCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final streak = stats?.currentStreak ?? 0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8A951), Color(0xFFE8D5A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                '$streak Day Streak',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isCompleted = index < streak.clamp(0, 7);
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.25),
                      border: isCompleted
                          ? null
                          : Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    days[index],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep it going!',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Grid ───────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final UserStatsModel? stats;

  const _StatsGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR STATS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                number: '${stats?.totalEditionsCompleted ?? 0}',
                label: 'Editions',
                icon: Icons.auto_stories_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                number: '${stats?.totalCardsRead ?? 0}',
                label: 'Cards Read',
                icon: Icons.style_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                number: '${(stats?.totalTimeSeconds ?? 0) ~/ 3600}h',
                label: 'Time Spent',
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                number: '${stats?.level ?? 1}',
                label: 'Level',
                icon: Icons.trending_up_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;

  const _StatCard({
    required this.number,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle watermark icon
          Positioned(
            right: -4,
            bottom: -4,
            child: Icon(
              icon,
              size: 40,
              color: AppColors.textTertiary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Topics Section ───────────────────────────────────────────

class _TopicsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final topics = ['Science', 'Psychology', 'History', 'Technology', 'Arts'];
    final colors = [
      AppColors.science,
      AppColors.psychology,
      AppColors.history,
      AppColors.technology,
      AppColors.arts,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR TOPICS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(topics.length, (index) {
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border(
                  left: BorderSide(color: colors[index], width: 3),
                ),
              ),
              child: Text(
                topics[index],
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Upgrade Button ───────────────────────────────────────────

class _UpgradeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.goldGradient,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Upgrade to Pro',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
