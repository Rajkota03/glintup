import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/features/profile/screens/profile_screen.dart';

/// ──────────────────────────────────────────────────────────────
/// Settings Screen
///
/// Sections:
///   - Account: Edit name, phone number (read-only)
///   - Notifications: Toggle on/off, change time
///   - Topics: Manage topics
///   - About: App version, Terms, Privacy, Licenses
///   - Danger Zone: Delete account
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
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        children: [
          // ── Account ──────────────────────────────────────
          _SectionHeader(title: 'Account'),
          profile.when(
            loading: () => const ListTile(
              title: Text('Loading...'),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Name'),
                  subtitle: Text(p?['first_name'] ?? 'Not set'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showEditNameDialog(
                    context,
                    p?['first_name'] ?? '',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone Number'),
                  subtitle: Text(
                    SupabaseConfig.currentUser?.phone ?? 'Not set',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Notifications ────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Daily Edition Notifications'),
            subtitle: const Text('Get notified when your edition is ready'),
            value: _notificationsEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time_rounded),
            title: const Text('Notification Time'),
            subtitle: Text(_notificationTime.format(context)),
            trailing: const Icon(Icons.chevron_right_rounded),
            enabled: _notificationsEnabled,
            onTap: _notificationsEnabled
                ? () => _showTimePicker(context)
                : null,
          ),
          const Divider(height: 1),

          // ── Topics ───────────────────────────────────────
          _SectionHeader(title: 'Topics'),
          ListTile(
            leading: const Icon(Icons.topic_rounded),
            title: const Text('Manage Topics'),
            subtitle: const Text('Choose what you want to learn about'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/onboarding/topics'),
          ),
          const Divider(height: 1),

          // ── About ────────────────────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('App Version'),
            subtitle: const Text('${AppConstants.appName} v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // TODO: Open terms URL
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              // TODO: Open privacy URL
            },
          ),
          ListTile(
            leading: const Icon(Icons.source_outlined),
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: 'v1.0.0',
              );
            },
          ),
          const Divider(height: 1),

          // ── Danger Zone ──────────────────────────────────
          _SectionHeader(title: 'Danger Zone', isDestructive: true),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded,
                color: AppColors.error),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            subtitle: const Text('Permanently delete your account and data'),
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const SizedBox(height: 40),
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

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
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

    if (confirmed == true && mounted) {
      // Account deletion will be handled via Supabase Edge Function
      // once auth is set up. For now, just show a confirmation.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion will be available after auth is set up.'),
          ),
        );
      }
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppColors.error : AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
