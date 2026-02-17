import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/climate_providers.dart';
import '../../domain/models/climate_model.dart';

class ClimateScreen extends ConsumerWidget {
  const ClimateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);
    // final locationName = ref.watch(weatherLocationNameProvider); // Removed
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Climate'),
        centerTitle: true,
      ),
      body: weatherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load weather.\nCheck connection.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(weatherProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (climate) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(weatherProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Current Weather Card
                  _buildCurrentWeatherCard(context, climate, isDark),
                  const SizedBox(height: 24),

                  // 2. 5-Day Forecast
                  Text('5-Day Forecast', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _buildForecastCard(context, climate.daily, index, isDark);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Smart Farming Advisory
                  Text('Farming Advisory', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 12),
                  _buildAdvisoryCard(context, climate, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentWeatherCard(BuildContext context, ClimateData climate, bool isDark) {
    final current = climate.current;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [AppColors.primaryDark, AppColors.cardGreenDark]
              : [AppColors.primary, AppColors.cardGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (climate.isGPS) 
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
              Text(
                climate.locationName,
                style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, d MMMM').format(DateTime.now()),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getWeatherIcon(current.weathercode),
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${current.temperature.round()}°',
                    style: AppTextStyles.displayLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    _getWeatherDescription(current.weathercode),
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  if (climate.daily.temperature2mMax.isNotEmpty)
                    Text(
                      'H:${climate.daily.temperature2mMax[0].round()}° L:${climate.daily.temperature2mMin[0].round()}°',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(Icons.air, '${current.windspeed} km/h', 'Wind'),
              // Humidity is not in current_weather by default in open-meteo free without extra params,
              // so we omit or use daily rain sum as proxy for wetness context
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildForecastCard(BuildContext context, WeatherDaily daily, int index, bool isDark) {
    final date = DateTime.now().add(Duration(days: index));
    final maxTemp = daily.temperature2mMax[index];
    final minTemp = daily.temperature2mMin[index];
    final code = daily.weathercode[index];

    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.dividerDark : AppColors.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('E').format(date),
            style: AppTextStyles.titleSmall,
          ),
          const SizedBox(height: 8),
          Icon(_getWeatherIcon(code), size: 32, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            '${maxTemp.round()}° / ${minTemp.round()}°',
            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard(BuildContext context, ClimateData data, bool isDark) {
    String message = "🌤 Weather conditions are stable for normal farming activities.";
    Color color = AppColors.success;
    IconData icon = Icons.check_circle_outline;

    final currentTemp = data.current.temperature;
    // Sum of rain for next 24h (approx index 0)
    final rainSum = data.daily.precipitationSum.isNotEmpty ? data.daily.precipitationSum[0] : 0.0;
    final windSpeed = data.current.windspeed;

    if (rainSum > 10.0) {
      message = "⚠️ Heavy rainfall expected. Avoid pesticide spraying and check drainage.";
      color = AppColors.warning;
      icon = Icons.water_drop;
    } else if (currentTemp > 35.0) {
      message = "🌡 High heat stress risk. Increase irrigation frequency for crops.";
      color = AppColors.error;
      icon = Icons.thermostat;
    } else if (windSpeed > 20.0) {
      message = "💨 Strong winds predicted. Secure loose structures and tall crops.";
      color = AppColors.warning;
      icon = Icons.air;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.umbrella; // Rain
    if (code >= 71 && code <= 77) return Icons.ac_unit; // Snow
    if (code >= 80 && code <= 82) return Icons.storm; // Showers
    if (code >= 95) return Icons.flash_on; // Thunderstorm
    return Icons.wb_sunny;
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Sky';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Clear';
  }
}
