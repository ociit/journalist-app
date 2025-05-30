// lib/models/weather_data.dart

class WeatherData {
  final String cityName;
  final double temperatureC;
  final String conditionText;
  final String conditionIconUrl;
  final double feelsLikeC;
  final int humidity;
  final double windKph;
  final int uvIndex;

  WeatherData({
    required this.cityName,
    required this.temperatureC,
    required this.conditionText,
    required this.conditionIconUrl,
    required this.feelsLikeC,
    required this.humidity,
    required this.windKph,
    required this.uvIndex,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final current = json['current'];

    return WeatherData(
      cityName: location['name'] ?? 'Unknown City',
      temperatureC: (current['temp_c'] as num).toDouble(),
      conditionText: current['condition']['text'] ?? 'Unknown',
      // Perhatikan penambahan 'https:' karena kadang API hanya mengembalikan '//'
      conditionIconUrl: 'https:' + (current['condition']['icon'] ?? '//cdn.weatherapi.com/weather/64x64/day/113.png'),
      feelsLikeC: (current['feelslike_c'] as num).toDouble(),
      humidity: current['humidity'] ?? 0,
      windKph: (current['wind_kph'] as num).toDouble(),
      uvIndex: (current['uv'] as num).toInt(),
    );
  }
}