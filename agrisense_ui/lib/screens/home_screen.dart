import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'weather_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<WeatherData> _weatherForecast = [];
  bool _isWeatherLoading = false;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });

    try {
      // Default location: Colombo, Sri Lanka (adjust as needed)
      final forecast = await WeatherService.getWeatherForecast(6.9271, 80.7789);
      setState(() {
        _weatherForecast = forecast;
        _isWeatherLoading = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = 'Unable to load weather';
        _isWeatherLoading = false;
      });
    }
  }

  void _goHome() {
    setState(() {
      _selectedIndex = 0;
    });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        // The Stack keeps the Nav Bar floating ON TOP of whatever screen is currently active
        body: Stack(
        children: [
          // 1. The Active Screen Manager (The Deck of Cards)
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboardView(), // Index 0: Home
              ChatbotScreen(onBack: _goHome), // Index 1: Chatbot
              WeatherScreen(onBack: _goHome), // Index 2: Weather
              const ProfileScreen(), // Index 3: Profile
              const SettingsScreen(), // Index 4: Settings
            ],
          ),

          // 2. Floating Bottom Navigation Bar (Fixed in place over everything)
          if (_selectedIndex != 1 && _selectedIndex != 2)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 30),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(Icons.home_outlined, 0),
                      _buildNavItem(Icons.chat_bubble_outline, 1),
                      _buildNavItem(Icons.cloud_outlined, 2),
                      _buildNavItem(Icons.person_outline, 3),
                      _buildNavItem(Icons.settings_outlined, 4),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  // --- DASHBOARD VIEW (Your Home Screen UI) ---
  Widget _buildDashboardView() {
    return Stack(
      children: [
        // 1. Full Screen Background Image (Only for the Dashboard)
        Positioned.fill(
          child: Image.asset(
            'assets/images/onboardingBG.png',
            fit: BoxFit.cover,
          ),
        ),

        // 2. Main Layout (Fixed Top Bar + Scrollable Content)
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- FIXED TOP APP BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Notification Icon
                    IconButton(
                      onPressed: () {
                        print("Notifications clicked");
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),

                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        // Switch to Profile Tab programmatically
                        setState(() {
                          _selectedIndex = 3;
                        });
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 18,
                        child: Icon(
                          Icons.person_outline,
                          color: Color(0xFF0B2B1D),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- SCROLLABLE MAIN CONTENT ---
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting
                        const Text(
                          'Hi Eshan,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Keep your field operations running smoothly.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Weather Cards Row
                        _isWeatherLoading
                            ? const Center(
                                child: SizedBox(
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              )
                            : _weatherError != null
                                ? Center(
                                    child: Text(
                                      _weatherError!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : _buildWeatherCardsRow(),

                        const SizedBox(height: 30),

                        // Ask AI Banner
                        GestureDetector(
                          onTap: () {
                            // Switch to Chatbot Tab programmatically
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Need Expert Advice?",
                                  style: TextStyle(
                                    color: Color(0xFF081C15),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Detect risks early and protect your yield",
                                  style: TextStyle(
                                    color: Color(0xFF081C15),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: const [
                                    Text(
                                      "Ask AI",
                                      style: TextStyle(
                                        color: Color(0xFF081C15),
                                        fontSize: 36,
                                        fontWeight: FontWeight.w400,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Color(0xFF081C15),
                                      size: 28,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Your AI Insights Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Your AI Insights",
                                style: TextStyle(
                                  color: Color(0xFF081C15),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Revisit past diagnoses and field recommendations",
                                style: TextStyle(
                                  color: Color(0xFF081C15),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 16),

                              ListView(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildInsightTile(
                                    "yellow leaves on rice plants",
                                    "Usually indicates nitrogen deficiency or overwatering...",
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInsightTile(
                                    "rice blast fungus signs in seedlings",
                                    "White or gray lesions with dark borders on leaves. Controlled with ...",
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInsightTile(
                                    "white streaks on rice leaves disease",
                                    "Could be rice tungro virus. Managed by controlling vector insects...",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Spacer to ensure content scrolls above the nav bar
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildWeatherCardsRow() {
    if (_weatherForecast.isEmpty) {
      return const Center(
        child: Text(
          'No weather data available',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < _weatherForecast.length; i++) ...[
          Expanded(
            child: _buildWeatherCard(
              _weatherForecast[i].day,
              _getWeatherIcon(_weatherForecast[i].condition),
              '${_weatherForecast[i].temp.toStringAsFixed(0)}°',
            ),
          ),
          if (i < _weatherForecast.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildWeatherCard(String day, IconData icon, String temp) {
    return GestureDetector(
      onTap: () {
        // Switch to Weather Tab programmatically
        setState(() => _selectedIndex = 2);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD8F3DC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: const TextStyle(
                color: Color(0xFF081C15),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 12),
            Icon(icon, color: const Color(0xFF081C15), size: 24),
            const SizedBox(height: 12),
            Text(
              temp,
              style: const TextStyle(
                color: Color(0xFF081C15),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(String title, String subtitle) {
    return GestureDetector(
      onTap: () => print("Insight clicked: $title"),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF081C15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon,
          color: isActive
              ? const Color(0xFF081C15)
              : const Color(0xFF081C15).withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}
