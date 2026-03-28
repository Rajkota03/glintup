import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/repositories/auth_repository.dart';
import 'package:glintup/features/profile/screens/profile_screen.dart';

/// ──────────────────────────────────────────────────────────────
/// Settings Screen — Minimal Luxury + Warm Editorial
/// ──────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── Account ──────────────────────────────────────
          _SectionHeader(title: 'Account'),
          profile.when(
            loading: () => const ListTile(
              title: Text('Loading...'),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (p) => Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  iconColor: AppColors.primary,
                  title: 'Name',
                  subtitle: p?['first_name'] ?? 'Not set',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                  onTap: () => _showEditNameDialog(
                    context,
                    p?['first_name'] ?? '',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: AppColors.divider,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.phone_outlined,
                  iconColor: AppColors.primary,
                  title: 'Phone Number',
                  subtitle: SupabaseConfig.currentUser?.phone ?? 'Not set',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Notifications ────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            iconColor: AppColors.primary,
            title: 'Daily Edition Notifications',
            subtitle: 'Get notified when your edition is ready',
            trailing: Switch(
              value: _notificationsEnabled,
              activeTrackColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SettingsTile(
            icon: Icons.access_time_outlined,
            iconColor: AppColors.primary,
            title: 'Notification Time',
            subtitle: _notificationTime.format(context),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            enabled: _notificationsEnabled,
            onTap: _notificationsEnabled
                ? () => _showTimePicker(context)
                : null,
          ),
          const SizedBox(height: 8),

          // ── Topics ───────────────────────────────────────
          _SectionHeader(title: 'Topics'),
          _SettingsTile(
            icon: Icons.topic_outlined,
            iconColor: AppColors.primary,
            title: 'Manage Topics',
            subtitle: 'Choose what you want to learn about',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () => context.push('/onboarding/topics'),
          ),
          const SizedBox(height: 8),

          // ── About ────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: 'App Version',
            subtitle: '${AppConstants.appName} v1.0.0',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.primary,
            title: 'Terms of Service',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () {
              // TODO: Open terms URL
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.primary,
            title: 'Privacy Policy',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () {
              // TODO: Open privacy URL
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          _SettingsTile(
            icon: Icons.source_outlined,
            iconColor: AppColors.primary,
            title: 'Open Source Licenses',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: 'v1.0.0',
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Sign Out ──────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showSignOutDialog(context),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Danger Zone ──────────────────────────────────
          _SectionHeader(title: 'Danger Zone', isDestructive: true),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context),
              child: Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.error.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(
      BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      final userId = SupabaseConfig.userId;
      if (userId == null) return;
      await SupabaseConfig.client
          .from('profiles')
          .update({'first_name': newName}).eq('id', userId);
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );
    if (picked != null) {
      setState(() => _notificationTime = picked);
    }
  }

  Future<void> _showSignOutDialog(BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      await AuthRepository().signOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext dialogContext) async {
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Account deletion will be available after auth is set up.'),
        ),
      );
    }
  }
}

/// Section header widget for settings groups.
class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDestructive;

  const _SectionHeader({
    required this.title,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDestructive
              ? AppColors.error.withValues(alpha: 0.7)
              : AppColors.textTertiary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Custom settings tile with warm editorial styling.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: enabled
            ? iconColor.withValues(alpha: 0.7)
            : AppColors.textTertiary.withValues(alpha: 0.4),
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      enabled: enabled,
    );
  }
}
