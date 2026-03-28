import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/repositories/auth_repository.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  /// Full phone number including country code, e.g. "+919876543210".
  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final _authRepository = AuthRepository();

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  bool _isVerifying = false;
  bool _isResending = false;

  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      AppConstants.otpLength,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      AppConstants.otpLength,
      (_) => FocusNode(),
    );

    _startResendTimer();

    // Focus the first field after the frame renders.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _otp => _controllers.map((c) => c.text).join();

  bool get _isOtpComplete => _otp.length == AppConstants.otpLength;

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < AppConstants.otpLength - 1) {
      // Advance focus to the next field.
      _focusNodes[index + 1].requestFocus();
    }

    if (_isOtpComplete) {
      _verifyOtp();
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  /// Checks the profiles table to see if onboarding has been completed.
  Future<bool> _checkOnboardingCompleted() async {
    final userId = SupabaseConfig.userId;
    if (userId == null) return false;

    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return false;
      return data['onboarding_completed'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _verifyOtp() async {
    if (_isVerifying || !_isOtpComplete) return;

    setState(() => _isVerifying = true);

    try {
      await _authRepository.verifyOtp(widget.phoneNumber, _otp);

      if (!mounted) return;

      // Determine where to navigate based on onboarding status.
      final onboardingDone = await _checkOnboardingCompleted();

      if (!mounted) return;

      if (onboardingDone) {
        context.go('/home');
      } else {
        context.go('/welcome');
      }
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

      // Clear the OTP fields so the user can retry.
      _clearOtp();
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await _authRepository.sendOtp(widget.phoneNumber);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP sent successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      _startResendTimer();
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
        setState(() => _isResending = false);
      }
    }
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final displayPhone = widget.phoneNumber;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),

              // Heading
              Text(
                'Verify your number',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the code sent to $displayPhone',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 40),

              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(AppConstants.otpLength, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: EdgeInsets.only(
                      right: index < AppConstants.otpLength - 1 ? 10 : 0,
                    ),
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyEvent(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _controllers[index].text.isNotEmpty
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) => _onDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _isVerifying || !_isOtpComplete ? null : _verifyOtp,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Verify'),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Center(
                child: _isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _resendCountdown > 0
                        ? Text(
                            'Resend OTP in ${_resendCountdown}s',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                          )
                        : GestureDetector(
                            onTap: _resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
