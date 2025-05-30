// lib/pages/weather_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';
import 'package:flutter/scheduler.dart'; // Import ini untuk SchedulerBinding

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  WeatherData? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _cityController = TextEditingController();
  final WeatherService _weatherService = WeatherService(); // Inisialisasi WeatherService

  // Tambahkan variabel untuk mengelola state loading saran
  bool _isSuggestionsLoading = false;

  @override
  void initState() {
    super.initState();
    // Anda bisa mengaktifkan ini jika ingin cuaca lokasi langsung muncul saat aplikasi dibuka
    // fetchWeatherForCurrentLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> fetchWeatherForCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
    });
    try {
      final weather = await _weatherService.fetchWeatherByLocation();
      setState(() {
        _weatherData = weather;
        _isLoading = false;
        _cityController.text = weather.cityName; // Set the city name to the text field
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> fetchWeatherByCity(String city) async {
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Nama kota tidak boleh kosong.';
        _weatherData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
    });
    try {
      final weather = await _weatherService.fetchCurrentWeather(city);
      setState(() {
        _weatherData = weather;
        _isLoading = false;
        _cityController.text = city; // Set textfield to the actual city found
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  LinearGradient _getBackgroundGradient(String? conditionText) {
    if (conditionText == null) {
      return LinearGradient(
        colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade500],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    String lowerCaseCondition = conditionText.toLowerCase();
    if (lowerCaseCondition.contains('rain') || lowerCaseCondition.contains('drizzle')) {
      return LinearGradient(
        colors: [Colors.blueGrey.shade600, Colors.blueGrey.shade800],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (lowerCaseCondition.contains('cloud') || lowerCaseCondition.contains('overcast')) {
      return LinearGradient(
        colors: [Colors.grey.shade400, Colors.grey.shade600],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (lowerCaseCondition.contains('clear') || lowerCaseCondition.contains('sun')) {
      return LinearGradient(
        colors: [Colors.lightBlue.shade300, Colors.blue.shade600],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (lowerCaseCondition.contains('snow') || lowerCaseCondition.contains('sleet')) {
      return LinearGradient(
        colors: [Colors.lightBlue.shade100, Colors.blue.shade300],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return LinearGradient(
      colors: [Colors.blueGrey.shade300, Colors.blueGrey.shade500], // Default
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Info Cuaca',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(_weatherData?.conditionText),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  // Tambahkan indikator loading saat mulai fetching
                  if (!_isSuggestionsLoading) {
                    setState(() {
                      _isSuggestionsLoading = true;
                    });
                  }

                  if (textEditingValue.text.isEmpty) {
                    // Hentikan loading jika teks kosong
                    if (_isSuggestionsLoading) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _isSuggestionsLoading = false;
                        });
                      });
                    }
                    return const Iterable<String>.empty();
                  }

                  final suggestions = await _weatherService.fetchCitySuggestions(textEditingValue.text);

                  // Hentikan loading setelah selesai fetching
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _isSuggestionsLoading = false;
                    });
                  });
                  return suggestions;
                },
                onSelected: (String selection) {
                  fetchWeatherByCity(selection);
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  // Pastikan _cityController dan fieldTextEditingController sinkron
                  if (_cityController.text != fieldTextEditingController.text) {
                    _cityController.text = fieldTextEditingController.text;
                  }
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
                    style: GoogleFonts.openSans(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Cari Kota (Contoh: Jakarta)',
                      labelStyle: GoogleFonts.openSans(color: Colors.white70),
                      hintStyle: GoogleFonts.openSans(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: () => fetchWeatherByCity(fieldTextEditingController.text),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                    ),
                    onSubmitted: (value) => fetchWeatherByCity(value),
                  );
                },
                optionsViewBuilder: (BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surface,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: _isSuggestionsLoading // Tampilkan indikator loading di sini
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: Theme.of(context).colorScheme.primary),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option,
                                        style: GoogleFonts.openSans(
                                            color: Theme.of(context).colorScheme.onSurface)),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: fetchWeatherForCurrentLocation,
                icon: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                label: Text(
                  'Dapatkan Cuaca Lokasi Sekarang',
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.primary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          style: GoogleFonts.openSans(color: Colors.redAccent, fontSize: 16),
                          textAlign: TextAlign.center,
                        )
                      : _weatherData != null
                          ? Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text(
                                      _weatherData!.cityName,
                                      style: GoogleFonts.poppins(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                    Image.network(
                                      _weatherData!.conditionIconUrl,
                                      scale: 0.7,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.cloud_off, size: 80, color: Colors.white70),
                                    ),
                                    Text(
                                      _weatherData!.conditionText.toUpperCase(),
                                      style: GoogleFonts.openSans(fontSize: 26, color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 30),
                                    Card(
                                      color: Colors.white.withOpacity(0.3),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          children: [
                                            _buildWeatherDetailRow(
                                                'Terasa seperti', '${_weatherData!.feelsLikeC.round()}°C', context),
                                            _buildWeatherDetailRow(
                                                'Kelembaban', '${_weatherData!.humidity}%', context),
                                            _buildWeatherDetailRow(
                                                'Kecepatan Angin', '${_weatherData!.windKph} kph', context),
                                            _buildWeatherDetailRow(
                                                'UV Index', '${_weatherData!.uvIndex}', context),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wb_sunny_outlined, size: 80, color: Colors.white70),
                                  SizedBox(height: 10),
                                  Text(
                                    'Cari cuaca atau gunakan lokasi Anda.',
                                    style: GoogleFonts.openSans(fontSize: 18, color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetailRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.openSans(fontSize: 18, color: Colors.white)),
          Text(value, style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}