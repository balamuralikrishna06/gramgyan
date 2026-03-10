import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/report_user.dart';
import '../providers/report_generator_provider.dart';
import '../widgets/add_person_form.dart';

class ReportGeneratorScreen extends ConsumerWidget {
  const ReportGeneratorScreen({super.key});

  Future<void> _showAddPersonSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddPersonForm(
        onSave: ({required name, required email, required position}) async {
          await ref
              .read(reportGeneratorProvider.notifier)
              .addPerson(name: name, email: email, position: position);
        },
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Person added successfully! 🌱'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _handleSend(
      BuildContext context, WidgetRef ref, ReportUser user) async {
    try {
      await ref.read(reportGeneratorProvider.notifier).sendReport(user);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report sent to ${user.email} ✅'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // 🔒 Admin guard
    if (authState is! AuthAuthenticated || authState.role != 'admin') {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text('Report Generator'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                'Only Admins can access Report Generator.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(reportGeneratorProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F1E6),
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        title: const Text(
          'Report Generator',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primaryDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(reportGeneratorProvider.notifier).fetchUsers(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : state.error != null
                      ? _buildError(context, ref, state.error!)
                      : _buildBody(context, ref, state.users),
            ),
            // ── Sticky bottom Add Person button ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F1E6),
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAddPersonSheet(context, ref),
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: const Text(
                  'Add Person',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body: header + content ──────────────────────────────────────────────
  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<ReportUser> users) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top bar: count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            '${users.length} ${users.length == 1 ? 'person' : 'people'}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Content: empty or table
        Expanded(
          child: users.isEmpty
              ? _buildEmpty(context, ref)
              : _buildTable(context, ref, users),
        ),
      ],
    );
  }

  // ── Data table ───────────────────────────────────────────────────────────
  Widget _buildTable(
      BuildContext context, WidgetRef ref, List<ReportUser> users) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.cardGreenLight,
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ColHeader(label: 'Name'),
                  ),
                  Expanded(
                    flex: 2,
                    child: _ColHeader(label: 'Position'),
                  ),
                  SizedBox(
                    width: 110,
                    child: _ColHeader(label: 'Action', centered: true),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1, thickness: 1, color: AppColors.divider),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _ReportUserRow(
                    user: user,
                    onSend: () => _handleSend(context, ref, user),
                    onDelete: () => _handleDelete(context, ref, user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_rounded,
                size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No people added yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Add Person" below to start building\nyour report recipient list.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 52, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(reportGeneratorProvider.notifier).fetchUsers(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _handleDelete(
      BuildContext context, WidgetRef ref, ReportUser user) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person'),
        content: Text('Are you sure you want to remove ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (!context.mounted) return;
      await ref.read(reportGeneratorProvider.notifier).deletePerson(user.id);
      
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${user.name} removed successfully.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ── Column Header ────────────────────────────────────────────────────────────
class _ColHeader extends StatelessWidget {
  final String label;
  final bool centered;

  const _ColHeader({required this.label, this.centered = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Report User Row ──────────────────────────────────────────────────────────
class _ReportUserRow extends StatefulWidget {
  final ReportUser user;
  final VoidCallback onSend;
  final VoidCallback onDelete;

  const _ReportUserRow({
    required this.user,
    required this.onSend,
    required this.onDelete,
  });

  @override
  State<_ReportUserRow> createState() => _ReportUserRowState();
}

class _ReportUserRowState extends State<_ReportUserRow> {
  bool _isSending = false;

  Future<void> _onSendTap() async {
    setState(() => _isSending = true);
    widget.onSend();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name + Email
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Position
          Expanded(
            flex: 2,
            child: Text(
              widget.user.position,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Actions: Send & Delete
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _isSending
                    ? const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _onSendTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
