import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/weather_service.dart';
import '../../../../core/providers/language_provider.dart';
import '../providers/smart_prediction_provider.dart';

/// Bottom-sheet form that collects all 7 soil+weather parameters.
///
/// Temperature & humidity are auto-fetched from GPS but shown as
/// editable fields so the farmer can correct for seasonal averages
/// if the current time/weather is unrepresentative.
class SoilInputForm extends ConsumerStatefulWidget {
  const SoilInputForm({super.key});

  @override
  ConsumerState<SoilInputForm> createState() => _SoilInputFormState();
}

class _SoilInputFormState extends ConsumerState<SoilInputForm> {
  final _formKey = GlobalKey<FormState>();

  final _nCtrl    = TextEditingController();
  final _pCtrl    = TextEditingController();
  final _kCtrl    = TextEditingController();
  final _phCtrl   = TextEditingController();
  final _rainCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _humCtrl  = TextEditingController();

  bool _loadingWeather = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  @override
  void dispose() {
    _nCtrl.dispose(); _pCtrl.dispose(); _kCtrl.dispose();
    _phCtrl.dispose(); _rainCtrl.dispose();
    _tempCtrl.dispose(); _humCtrl.dispose();
    super.dispose();
  }

  /// Auto-fetch GPS temperature + humidity and pre-fill the fields.
  Future<void> _fetchWeather() async {
    setState(() { _loadingWeather = true; _weatherError = null; });
    try {
      final w = await WeatherService().fetchWeather();
      if (mounted) {
        _tempCtrl.text = w.temperature.toStringAsFixed(1);
        _humCtrl.text  = w.humidity.toStringAsFixed(1);
        setState(() { _loadingWeather = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingWeather = false;
          _weatherError = 'GPS unavailable — enter manually';
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final n    = double.parse(_nCtrl.text.trim());
    final p    = double.parse(_pCtrl.text.trim());
    final k    = double.parse(_kCtrl.text.trim());
    final ph   = double.parse(_phCtrl.text.trim());
    final rain = double.parse(_rainCtrl.text.trim());
    final temp = double.parse(_tempCtrl.text.trim());
    final hum  = double.parse(_humCtrl.text.trim());

    // Read user's preferred language from local storage (set on profile)
    final languageCode = ref.read(languageProvider) ?? 'en';

    Navigator.of(context).pop();

    ref.read(smartPredictionProvider.notifier).runPrediction(
      nitrogen: n, phosphorus: p, potassium: k,
      ph: ph, rainfall: rain, temperature: temp, humidity: hum,
      languageCode: languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : AppColors.cardLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 16),

              // Title
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('🌱', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Crop Prediction', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
                    )),
                    const SizedBox(height: 2),
                    Text(
                      _loadingWeather
                          ? '📡 Fetching GPS weather...'
                          : _weatherError ?? '✅ Weather fetched — edit if needed',
                      style: TextStyle(fontSize: 11, color: AppColors.primary),
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),

              // ── Soil section label ──
              _SectionLabel(label: 'Soil Parameters'),
              const SizedBox(height: 8),

              // N + P
              Row(children: [
                Expanded(child: _SoilField(controller: _nCtrl, label: 'Nitrogen (N)', hint: '0–140', unit: 'kg/ha', min: 0, max: 200)),
                const SizedBox(width: 10),
                Expanded(child: _SoilField(controller: _pCtrl, label: 'Phosphorus (P)', hint: '5–145', unit: 'kg/ha', min: 0, max: 200)),
              ]),
              const SizedBox(height: 10),

              // K + pH
              Row(children: [
                Expanded(child: _SoilField(controller: _kCtrl, label: 'Potassium (K)', hint: '5–205', unit: 'kg/ha', min: 0, max: 300)),
                const SizedBox(width: 10),
                Expanded(child: _SoilField(controller: _phCtrl, label: 'Soil pH', hint: '3.5–9.5', unit: '', min: 0, max: 14, isDecimal: true)),
              ]),
              const SizedBox(height: 10),

              // Rainfall
              _SoilField(
                controller: _rainCtrl,
                label: 'Rainfall (mm)',
                hint: 'e.g. 58 for Virudhunagar',
                unit: 'mm',
                min: 10, max: 300,
                isDecimal: true,
                fullWidth: true,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  '💧 Monthly avg: Virudhunagar ~58  |  Chennai ~120  |  Punjab ~60',
                  style: TextStyle(fontSize: 10, color: AppColors.info, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 14),

              // ── Weather section label ──
              _SectionLabel(label: 'Weather (GPS auto-filled — edit if wrong)'),
              const SizedBox(height: 8),

              Row(children: [
                Expanded(child: _SoilField(
                  controller: _tempCtrl,
                  label: 'Temperature',
                  hint: _loadingWeather ? 'Fetching...' : '15–45',
                  unit: '°C',
                  min: -10, max: 60,
                  isDecimal: true,
                  isLoading: _loadingWeather,
                )),
                const SizedBox(width: 10),
                Expanded(child: _SoilField(
                  controller: _humCtrl,
                  label: 'Humidity',
                  hint: _loadingWeather ? 'Fetching...' : '14–100',
                  unit: '%',
                  min: 0, max: 100,
                  isDecimal: true,
                  isLoading: _loadingWeather,
                )),
              ]),

              if (_weatherError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '\u26a0\ufe0f $_weatherError \u2014 enter your area\'s typical values',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ),

              const SizedBox(height: 18),

              // Submit
              ElevatedButton.icon(
                onPressed: _loadingWeather ? null : _submit,
                icon: const Icon(Icons.agriculture_rounded),
                label: Text(
                  _loadingWeather ? 'Fetching GPS...' : 'Analyze My Soil →',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section label ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ── Reusable text field ────────────────────────────────────────────────────

class _SoilField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String unit;
  final double min;
  final double max;
  final bool isDecimal;
  final bool fullWidth;
  final bool isLoading;

  const _SoilField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.unit,
    required this.min,
    required this.max,
    this.isDecimal = false,
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      enabled: !isLoading,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isDecimal ? RegExp(r'[\d.]') : RegExp(r'\d'),
        ),
      ],
      style: TextStyle(
        color: isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit.isNotEmpty ? unit : null,
        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.6)
            : AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null) return 'Invalid';
        if (n < min || n > max) return '${min.toInt()}–${max.toInt()}';
        return null;
      },
    );
  }
}
