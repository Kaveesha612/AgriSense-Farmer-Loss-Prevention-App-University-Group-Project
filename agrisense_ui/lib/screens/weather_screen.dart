import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/planting_service.dart';

class WeatherScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const WeatherScreen({super.key, this.onBack});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherData> _currentWeatherFuture;
  late Future<List<WeatherData>> _hourlyForecastFuture;
  late Future<List<WeatherData>> _forecastFuture;
  final TextEditingController _fieldSizeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final List<String> _riceVarieties = ['Basmathi', 'Swarna', 'Kolam', 'Nadu'];
  String _riceType = 'Basmathi';
  String _recommendation = '';
  String _recommendationError = '';
  bool _isLoadingRecommendation = false;
  int _selectedTab = 0;
  double _latitude = 6.9271;
  double _longitude = 80.7789;
  String _locationLabel = 'Colombo, LK';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _fieldSizeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadWeather() {
    _currentWeatherFuture = WeatherService.getCurrentWeather(
      _latitude,
      _longitude,
    );
    _hourlyForecastFuture = WeatherService.getHourlyForecast(
      _latitude,
      _longitude,
    );
    _forecastFuture = WeatherService.getWeatherForecast(_latitude, _longitude);
  }

  String _formatDate(DateTime dateTime) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${dateTime.day.toString().padLeft(2, '0')} ${monthNames[dateTime.month - 1]} ${dateTime.year}';
  }

  Future<void> _showLocationDialog() async {
    _locationController.text = _locationLabel;
    final newLocation = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change location'),
          content: TextField(
            controller: _locationController,
            decoration: const InputDecoration(hintText: 'Enter city name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_locationController.text.trim());
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (newLocation != null &&
        newLocation.isNotEmpty &&
        newLocation != _locationLabel) {
      await _updateLocation(newLocation);
    }
  }

  Future<void> _updateLocation(String location) async {
    setState(() {
      _locationLabel = 'Loading...';
    });

    try {
      final coords = await WeatherService.getLocationCoordinates(location);
      setState(() {
        _latitude = coords['lat'];
        _longitude = coords['lon'];
        final state = coords['state'] != null && coords['state'].isNotEmpty
            ? ', ${coords['state']}'
            : '';
        _locationLabel = '${coords['name']}$state, ${coords['country']}';
      });
      _loadWeather();
    } catch (e) {
      setState(() {
        _locationLabel = location;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update location: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 18.0,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF1F4F32),
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showLocationDialog,
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF1F4F32),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _locationLabel,
                          style: const TextStyle(
                            color: Color(0xFF1F4F32),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF1F4F32),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<WeatherData>(
                      future: _currentWeatherFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            height: 260,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFBAE6C9), Color(0xFF2A744B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            height: 260,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFBAE6C9), Color(0xFF2A744B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Center(
                              child: Text(
                                'Error loading weather',
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        final weather = snapshot.data!;
                        return Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8DCF9D),
                                    Color(0xFF1B5D37),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(DateTime.now()),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              weather.condition,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              '${weather.temp.toStringAsFixed(0)}°C',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 56,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: const [
                                          Icon(
                                            Icons.cloud_queue,
                                            color: Colors.white,
                                            size: 90,
                                          ),
                                          SizedBox(height: 8),
                                          Icon(
                                            Icons.nights_stay,
                                            color: Colors.white70,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F6E8),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSmallStat(
                                    icon: Icons.wind_power,
                                    value:
                                        '${weather.windSpeed.toStringAsFixed(1)} m/s',
                                    label: 'Wind',
                                  ),
                                  _buildSmallStat(
                                    icon: Icons.water_drop,
                                    value: '${weather.humidity}%',
                                    label: 'Humidity',
                                  ),
                                  _buildSmallStat(
                                    icon: Icons.cloudy_snowing,
                                    value:
                                        '${weather.precipitation?.toStringAsFixed(1) ?? '0.0'} mm',
                                    label: 'Rain',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    _buildForecastSection(),
                    const SizedBox(height: 28),
                    const Text(
                      'Field size',
                      style: TextStyle(
                        color: Color(0xFF2D4A36),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _fieldSizeController,
                      style: const TextStyle(color: Color(0xFF2D4A36)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF1F9F2),
                        hintText: 'XX acres',
                        hintStyle: const TextStyle(color: Color(0xFF8DAE94)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rice variety',
                      style: TextStyle(
                        color: Color(0xFF2D4A36),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F9F2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _riceType,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF2D4A36),
                          ),
                          items: _riceVarieties
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type,
                                    style: const TextStyle(
                                      color: Color(0xFF2D4A36),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _riceType = value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildRecommendationCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3A6C4F), size: 26),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1F4F32),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF779E82),
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Today', 'Tomorrow', 'Next 3 Days'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        tabs.length,
        (index) => GestureDetector(
          onTap: () => setState(() => _selectedTab = index),
          child: Column(
            children: [
              Text(
                tabs[index],
                style: TextStyle(
                  color: _selectedTab == index
                      ? const Color(0xFF2A5A33)
                      : const Color(0xFF8EA98B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 60,
                decoration: BoxDecoration(
                  color: _selectedTab == index
                      ? const Color(0xFF2A5A33)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
    return FutureBuilder<List<WeatherData>>(
      future: _selectedTab < 2 ? _hourlyForecastFuture : _forecastFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 130,
            child: Center(
              child: CircularProgressIndicator(color: const Color(0xFF2A5A33)),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 130,
            child: Center(
              child: Text(
                'Error loading forecast',
                style: const TextStyle(color: Color(0xFF2D4A36)),
              ),
            ),
          );
        }

        final forecast = snapshot.data;
        if (forecast == null || forecast.isEmpty) {
          return const SizedBox(
            height: 130,
            child: Center(
              child: Text(
                'No forecast available',
                style: TextStyle(color: Color(0xFF2D4A36)),
              ),
            ),
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: forecast.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _buildTimeCard(forecast[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildTimeCard(WeatherData weather) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            weather.day,
            style: const TextStyle(
              color: Color(0xFF3A6C4F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          Icon(
            _getWeatherIcon(weather.condition),
            color: const Color(0xFF467654),
            size: 30,
          ),
          Text(
            '${weather.temp.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Color(0xFF2A5A33),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4D2D),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Planting Window',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'March 8  →  March 12',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Soil moisture: Optimal (32%)\nTemperature range: 26–30°C (ideal for germination)\nWind speed: Low (reduces seed displacement)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.7,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66C780),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoadingRecommendation
                  ? null
                  : _handleGenerateRecommendation,
              child: _isLoadingRecommendation
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Get recommendation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
          if (_recommendation.isNotEmpty ||
              _recommendationError.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              _recommendationError.isNotEmpty
                  ? _recommendationError
                  : _recommendation,
              style: TextStyle(
                color: _recommendationError.isNotEmpty
                    ? Colors.red[200]
                    : Colors.white70,
                fontSize: 12,
                height: 1.6,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleGenerateRecommendation() async {
    final fieldSize = _fieldSizeController.text.trim();
    if (fieldSize.isEmpty) {
      setState(() {
        _recommendationError =
            'Enter the field size to receive a planting recommendation.';
        _recommendation = '';
      });
      return;
    }

    setState(() {
      _recommendationError = '';
      _recommendation = '';
      _isLoadingRecommendation = true;
    });

    try {
      final currentWeather = await _currentWeatherFuture;
      final weatherSummary =
          '${currentWeather.condition}, ${currentWeather.temp.toStringAsFixed(1)}°C, humidity ${currentWeather.humidity}%, wind ${currentWeather.windSpeed.toStringAsFixed(1)} m/s.';
      final recommendation =
          await PlantingService.getPlantingWindowRecommendation(
            riceType: _riceType,
            fieldSize: fieldSize,
            weatherSummary: weatherSummary,
          );
      setState(() {
        _recommendation = recommendation;
      });
    } catch (_) {
      setState(() {
        _recommendationError =
            'Unable to fetch recommendation right now. Please try again.';
      });
    } finally {
      setState(() {
        _isLoadingRecommendation = false;
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    final description = WeatherService.getWeatherIconDescription(condition);
    switch (description) {
      case 'cloud':
        return Icons.cloud_outlined;
      case 'rain':
        return Icons.water_drop_outlined;
      case 'storm':
        return Icons.thunderstorm_outlined;
      case 'snow':
        return Icons.cloudy_snowing;
      case 'sunny':
        return Icons.wb_sunny_outlined;
      case 'wind':
        return Icons.air_outlined;
      default:
        return Icons.cloud_outlined;
    }
  }
}
