import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';

class NotificationSetupScreen extends ConsumerStatefulWidget {
  const NotificationSetupScreen({super.key});

  @override
  ConsumerState<NotificationSetupScreen> createState() =>
      _NotificationSetupScreenState();
}

class _NotificationSetupScreenState
    extends ConsumerState<NotificationSetupScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSaving = false;

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveAndFinish() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) throw Exception('User not authenticated');

      // Build a time string like "08:00" for storage.
      final timeString =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:'
          '${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Save notification preference.
      await SupabaseConfig.client.from('notification_preferences').upsert({
        'user_id': userId,
        'preferred_time': timeString,
        'enabled': true,
      });

      // Mark onboarding as completed.
      await SupabaseConfig.client.from('profiles').upsert({
        'id': userId,
        'onboarding_completed': true,
      });

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _skip() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final userId = SupabaseConfig.userId;
      if (userId == null) throw Exception('User not authenticated');

      // Mark onboarding as completed even if user skips notification setup.
      await SupabaseConfig.client.from('profiles').upsert({
        'id': userId,
        'onboarding_completed': true,
      });

      if (!mounted) return;

      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Bell icon
              const Center(
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Heading
              Text(
                'When should we\nnotify you?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Your daily edition will be ready at this time',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 48),

              // Time display / picker trigger
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formattedTime,
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Done button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndFinish,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),

              const SizedBox(height: 12),

              // Skip button
              Center(
                child: TextButton(
                  onPressed: _isSaving ? null : _skip,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
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
