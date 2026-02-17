class ClimateData {
  final WeatherCurrent current;
  final WeatherDaily daily;
  final String locationName;
  final bool isGPS;

  ClimateData({
    required this.current,
    required this.daily,
    required this.locationName,
    required this.isGPS,
  });

  factory ClimateData.fromJson(Map<String, dynamic> json, {String locationName = '', bool isGPS = false}) {
    return ClimateData(
      current: WeatherCurrent.fromJson(json['current_weather']),
      daily: WeatherDaily.fromJson(json['daily']),
      locationName: locationName,
      isGPS: isGPS,
    );
  }
}

class WeatherCurrent {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final int isDay;

  WeatherCurrent({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.isDay,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      temperature: (json['temperature'] as num).toDouble(),
      windspeed: (json['windspeed'] as num).toDouble(),
      weathercode: json['weathercode'] as int,
      isDay: json['is_day'] as int,
    );
  }
}

class WeatherDaily {
  final List<String> time;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;
  final List<double> precipitationSum;
  final List<int> weathercode;

  WeatherDaily({
    required this.time,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationSum,
    required this.weathercode,
  });

  factory WeatherDaily.fromJson(Map<String, dynamic> json) {
    return WeatherDaily(
      time: (json['time'] as List).map((e) => e.toString()).toList(),
      temperature2mMax: (json['temperature_2m_max'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      temperature2mMin: (json['temperature_2m_min'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      precipitationSum: (json['precipitation_sum'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      weathercode: (json['weathercode'] as List)
          .map((e) => e as int)
          .toList(),
    );
  }
}
