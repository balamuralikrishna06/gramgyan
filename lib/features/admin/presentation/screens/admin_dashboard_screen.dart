import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../map/presentation/providers/map_providers.dart';
import '../widgets/submission_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(reportRepositoryProvider);
      final submissions = await repo.getPendingSubmissions();
      if (mounted) {
        setState(() {
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> submission) async {
    try {
      final authState = ref.read(authStateProvider);
      final userId = (authState is AuthAuthenticated) ? authState.userId : '';

      if (userId.isEmpty) {
         throw Exception('Cannot approve: User ID is missing.');
      }

      final repo = ref.read(reportRepositoryProvider);
      await repo.approveSubmission(submission, userId: userId); // Pass userId
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission Approved! 🌾')),
        );
        _fetchSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(String id) async {
    try {
      final repo = ref.read(reportRepositoryProvider);
      await repo.rejectSubmission(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission Rejected')),
        );
        _fetchSubmissions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // 🔒 Security Check
    if (authState is! AuthAuthenticated || 
        (authState.role != 'admin' && authState.role != 'expert')) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Access Denied', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Only Admins and Experts can view this page.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSubmissions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'All Caught Up!',
                        style: AppTextStyles.headlineMedium.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      const Text('No pending submissions to review.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) {
                    final submission = _submissions[index];
                    return SubmissionCard(
                      submission: submission,
                      onApprove: () => _handleApprove(submission),
                      onReject: () => _handleReject(submission['id']),
                    );
                  },
                ),
    );
  }
}
