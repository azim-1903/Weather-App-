import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFE3F2FD),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: WeatherHomePage(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _cityController = TextEditingController();
  final String apiKey = 'f02fa2e03ed4e15e72bdd4fba02d205f'; // ← REPLACE WITH YOUR KEY

  bool isLoading = false;
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecastWeather;
  String? errorMessage;

  bool get isDarkMode => widget.themeMode == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWeather();
  }

  Future<void> _getCurrentLocationWeather() async {
    setState(() => isLoading = true);
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        errorMessage = 'Location services are disabled.';
        isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          errorMessage = 'Location permissions are denied';
          isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage = 'Location permissions are permanently denied';
        isLoading = false;
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    await _fetchWeather(lat: position.latitude, lon: position.longitude);
  }

  Future<void> _fetchWeather({String? city, double? lat, double? lon}) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String url;
    if (city != null) {
      url =
          'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    } else {
      url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _fetchForecast(data['coord']['lat'], data['coord']['lon']);

        setState(() {
          currentWeather = data;
        });
      } else {
        setState(() {
          errorMessage =
              json.decode(response.body)['message'] ?? 'City not found';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load weather';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchForecast(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> list = data['list'];

      // Group by day
      Map<String, dynamic> daily = {};
      for (var item in list) {
        String date = item['dt_txt'].split(' ')[0];
        if (!daily.containsKey(date)) {
          daily[date] = item;
        }
      }

      setState(() {
        forecastWeather = daily.values.toList().take(5).toList();
      });
    }
  }

  String getWeatherIcon(String? iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@4x.png';
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryTextColor =
        isDarkMode ? Colors.white : Colors.black87;
    final Color secondaryTextColor =
        isDarkMode ? Colors.white70 : Colors.black54;
    final List<Color> gradientColors = isDarkMode
        ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
        : [const Color(0xFF8EC5FC), const Color(0xFFE0C3FC)];
    final Color cardColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.9);
    final Color searchFillColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);
    final Color actionButtonColor =
        isDarkMode ? Colors.white : Colors.blue;
    final Color actionIconColor =
        isDarkMode ? Colors.blue : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Weather App',
          style: TextStyle(color: primaryTextColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: primaryTextColor,
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cityController,
                        style: TextStyle(color: primaryTextColor),
                        decoration: InputDecoration(
                          hintText: 'Enter city name',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          filled: true,
                          fillColor: searchFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_cityController.text.isNotEmpty) {
                          _fetchWeather(city: _cityController.text);
                          _cityController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: actionButtonColor,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: actionIconColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                if (isLoading)
                  SpinKitCircle(color: primaryTextColor, size: 60)
                else if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red.shade200, fontSize: 18),
                  )
                else if (currentWeather != null) ...[
                  // Current Weather
                  Text(
                    currentWeather!['name'],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: TextStyle(fontSize: 18, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  Image.network(
                    getWeatherIcon(currentWeather!['weather'][0]['icon']),
                    width: 150,
                  ),
                  Text(
                    '${currentWeather!['main']['temp'].round()}°C',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.w300,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    currentWeather!['weather'][0]['description']
                        .toString()
                        .toUpperCase(),
                    style:
                        TextStyle(fontSize: 20, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoCard(
                        Icons.water_drop,
                        '${currentWeather!['main']['humidity']}%',
                        'Humidity',
                        primaryTextColor,
                        secondaryTextColor,
                      ),
                      _buildInfoCard(
                        Icons.air,
                        '${currentWeather!['wind']['speed']} m/s',
                        'Wind',
                        primaryTextColor,
                        secondaryTextColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '5-Day Forecast',
                    style: TextStyle(fontSize: 22, color: primaryTextColor),
                  ),
                  const SizedBox(height: 10),
                  if (forecastWeather != null)
                    Expanded(
                      child: ListView.builder(
                        itemCount: forecastWeather!.length,
                        itemBuilder: (context, index) {
                          var day = forecastWeather![index];
                          String date = day['dt_txt'].split(' ')[0];
                          return Card(
                            color: cardColor,
                            child: ListTile(
                              leading: Image.network(
                                getWeatherIcon(day['weather'][0]['icon']),
                                width: 50,
                              ),
                              title: Text(
                                DateFormat('EEEE').format(DateTime.parse(date)),
                                style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                day['weather'][0]['description'],
                                style: TextStyle(color: secondaryTextColor),
                              ),
                              trailing: Text(
                                '${day['main']['temp'].round()}°C',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: primaryTextColor,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String value,
    String label,
    Color primaryTextColor,
    Color secondaryTextColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: secondaryTextColor, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(fontSize: 20, color: primaryTextColor),
        ),
        Text(
          label,
          style: TextStyle(color: secondaryTextColor),
        ),
      ],
    );
  }
}
