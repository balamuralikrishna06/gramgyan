import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_providers.dart';

class PhoneLoginSheet extends ConsumerStatefulWidget {
  const PhoneLoginSheet({super.key});

  @override
  ConsumerState<PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _PhoneLoginSheetState extends ConsumerState<PhoneLoginSheet> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  String? _verificationId;
  String? _error;
  bool _isLoading = false;
  int _resendToken = 0;
  Timer? _timer;
  int _start = 60;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _start = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _verifyPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    await ref.read(authStateProvider.notifier).verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-verification
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) Navigator.pop(context);
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
          _error = e.message ?? 'Verification failed';
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken ?? 0;
          _codeSent = true;
          _isLoading = false;
        });
        _startTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  void _signInWithOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter valid 6-digit OTP');
      return;
    }

    if (_verificationId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authStateProvider.notifier).signInWithOtp(
          _verificationId!,
          otp,
        );
    
    // The provider generic state listener in LoginScreen will handle navigation
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _codeSent ? 'Verify OTP' : 'Phone Login',
            style: AppTextStyles.headlineMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _codeSent
                ? 'Enter the code sent to ${_phoneController.text}'
                : 'We will send a verification code to this number.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (!_codeSent)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Enter Phone Number',
                prefixText: '+91 ',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                letterSpacing: 8,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (_codeSent ? _signInWithOtp : _verifyPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _codeSent ? 'Verify & Login' : 'Send Code',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 16),
            Center(
              child: _start > 0
                  ? Text(
                      'Resend code in $_start s',
                      style: TextStyle(color: Colors.grey[600]),
                    )
                  : TextButton(
                      onPressed: _verifyPhone,
                      child: const Text('Resend Code'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
