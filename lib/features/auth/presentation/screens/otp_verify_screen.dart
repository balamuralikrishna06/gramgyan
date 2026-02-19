import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../../domain/models/auth_state.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();

  Future<void> _onVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) return;

    await ref.read(authStateProvider.notifier).verifyOtp(widget.phoneNumber, otp);
    // Navigation is handled by the AuthState listener in the Router or Main
    // If successful, state changes to Authenticated, and Router redirects.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authStateProvider, (prev, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Text('OTP sent to ${widget.phoneNumber}'),
             const SizedBox(height: 20),
             TextField(
               controller: _otpController,
               decoration: const InputDecoration(
                 labelText: 'OTP',
                 border: OutlineInputBorder(),
               ),
               keyboardType: TextInputType.number,
             ),
             const SizedBox(height: 20),
             SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onVerify,
                  child: isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Verify'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
