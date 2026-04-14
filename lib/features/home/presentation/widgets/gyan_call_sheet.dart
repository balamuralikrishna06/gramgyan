import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/gyan_call_provider.dart';

/// Bottom sheet for the "Gyan Call" feature — allows smartphone users
/// to trigger a voice call for offline (button-phone) farmers.
class GyanCallSheet extends StatefulWidget {
  const GyanCallSheet({super.key});

  @override
  State<GyanCallSheet> createState() => _GyanCallSheetState();
}

class _GyanCallSheetState extends State<GyanCallSheet> {
  // 0 = Line 1, 1 = Line 2
  int _selectedLine = 0;
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  static const _lines = [
    _CallLine(
      label: 'Line 1',
      subLabel: 'Expert Support',
      number: '+1 839-261-6941',
      lineId: 1,
    ),
    _CallLine(
      label: 'Line 2',
      subLabel: 'Alternate Support',
      number: '+1 582-282-0653',
      lineId: 2,
    ),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestCallback() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnack("Please enter the farmer's phone number.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final line = _lines[_selectedLine];
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.backendPrimaryUrl}/api/v1/gyancall/trigger'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'phone': phone,
              'line': line.lineId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        _showSnack(
          '✅ Success! An incoming call is being initiated to the farmer.',
          isError: false,
        );
      } else {
        _showSnack('Service busy. Please try again later.', isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Service busy. Please try again later.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ──
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dividerDark : AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── Title ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_forwarded_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gyan Call',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  Text('Help an offline farmer via voice call',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Line Selection ──
          Text('Select Call Line',
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 10),
          Row(
            children: List.generate(_lines.length, (i) {
              final selected = _selectedLine == i;
              final line = _lines[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLine = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : (isDark ? AppColors.cardDark : AppColors.cardLight),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.dividerDark
                                : AppColors.divider),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selected
                                  ? AppColors.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(line.label,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? AppColors.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                )),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(line.subLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11,
                            )),
                        const SizedBox(height: 2),
                        Text(line.number,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Phone Input ──
          Text(
            "Farmer's Phone Number",
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. +91 98765 43210',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              prefixIcon: const Icon(Icons.phone_outlined,
                  color: AppColors.primary, size: 20),
              filled: true,
              fillColor:
                  isDark ? AppColors.cardDark : AppColors.cardLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.dividerDark : AppColors.divider,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color:
                      isDark ? AppColors.dividerDark : AppColors.divider,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestCallback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_forwarded_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Request Call Back',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for a call line configuration.
class _CallLine {
  final String label;
  final String subLabel;
  final String number;
  final int lineId;

  const _CallLine({
    required this.label,
    required this.subLabel,
    required this.number,
    required this.lineId,
  });
}

/// Shows the GyanCallSheet as a modal bottom sheet.
/// Updates [gyanCallOpenProvider] so AppShell can hide FABs.
Future<void> showGyanCallSheet(BuildContext context, WidgetRef ref) async {
  ref.read(gyanCallOpenProvider.notifier).state = true;
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const GyanCallSheet(),
  );
  ref.read(gyanCallOpenProvider.notifier).state = false;
}
