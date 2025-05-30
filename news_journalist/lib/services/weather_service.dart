// lib/services/weather_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../api/api_keys.dart';
import '../models/weather_data.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class WeatherService {
  final String _apiKey = ApiKeys.weatherApiKey;
  final String _baseUrl = 'http://api.weatherapi.com/v1';

  Future<WeatherData> fetchCurrentWeather(String query) async {
    final uri = Uri.parse('$_baseUrl/current.json?key=$_apiKey&q=$query');

    try {
      final response = await http.get(uri);
      debugPrint('WeatherAPI URL: $uri');
      debugPrint('WeatherAPI Status Code: ${response.statusCode}');
      debugPrint('WeatherAPI Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        String errorMessage = 'Terjadi kesalahan tidak diketahui.';
        if (errorData.containsKey('error') && errorData['error'].containsKey('message')) {
          errorMessage = errorData['error']['message'];
        }
        throw Exception('Gagal memuat cuaca untuk "$query": $errorMessage');
      }
    } catch (e) {
      throw Exception('Error mengambil cuaca: $e');
    }
  }

  Future<WeatherData> fetchWeatherByLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen, tidak bisa meminta izin lagi.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );

    String query = '${position.latitude},${position.longitude}';
    return await fetchCurrentWeather(query);
  }

  // --- Fungsi baru untuk saran pencarian ---
  Future<List<String>> fetchCitySuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final uri = Uri.parse('$_baseUrl/search.json?key=$_apiKey&q=$query');

    try {
      final response = await http.get(uri);
      debugPrint('WeatherAPI Search URL: $uri');
      debugPrint('WeatherAPI Search Status Code: ${response.statusCode}');
      debugPrint('WeatherAPI Search Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Mengambil hanya nama kota dari hasil pencarian
        return data.map((item) => item['name'] as String).toList();
      } else {
        // Tangani error jika terjadi pada pencarian
        final Map<String, dynamic> errorData = json.decode(response.body);
        String errorMessage = 'Terjadi kesalahan saat mencari kota.';
        if (errorData.containsKey('error') && errorData['error'].containsKey('message')) {
          errorMessage = errorData['error']['message'];
        }
        debugPrint('Error fetching city suggestions: $errorMessage');
        return []; // Kembalikan list kosong jika ada error
      }
    } catch (e) {
      debugPrint('Caught error fetching city suggestions: $e');
      return []; // Kembalikan list kosong jika terjadi error jaringan
    }
  }
}