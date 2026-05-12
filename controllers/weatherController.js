import asyncHandler from 'express-async-handler';

const BASE_URL = 'https://api.openweathermap.org/data/2.5';

const getOpenWeatherApiKey = () => {
  const apiKey = process.env.OPENWEATHER_API_KEY;
  if (!apiKey) {
    throw new Error('OPENWEATHER_API_KEY is not configured in environment variables');
  }
  return apiKey;
};

// @desc    Get current weather by coordinates
// @route   GET /api/weather/current?lat=...&lon=...
// @access  Private
export const getWeather = asyncHandler(async (req, res) => {
  const { lat, lon } = req.query;
  if (!lat || !lon) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }

  const apiKey = getOpenWeatherApiKey();
  const url = `${BASE_URL}/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric`;

  const response = await fetch(url);
  const data = await response.json();

  if (data.cod !== 200) {
    res.status(data.cod);
    throw new Error(data.message);
  }

  res.json(data);
});

export const getGeocode = asyncHandler(async (req, res) => {
  const { city } = req.query;
  if (!city) {
    res.status(400);
    throw new Error('City is required');
  }

  const apiKey = getOpenWeatherApiKey();
  const url = `https://api.openweathermap.org/geo/1.0/direct?q=${encodeURIComponent(city)}&limit=1&appid=${apiKey}`;
  const response = await fetch(url);
  const data = await response.json();

  if (!response.ok || !Array.isArray(data) || data.length == 0) {
    res.status(404);
    throw new Error('Location not found');
  }

  const locationInfo = data[0];
  res.json({
    name: locationInfo.name,
    state: locationInfo.state || '',
    country: locationInfo.country || '',
    lat: locationInfo.lat,
    lon: locationInfo.lon,
  });
});

// @desc    Get weather forecast by coordinates
// @route   GET /api/weather/forecast?lat=...&lon=...
// @access  Private
export const getWeatherForecast = asyncHandler(async (req, res) => {
  const { lat, lon } = req.query;
  if (!lat || !lon) {
    res.status(400);
    throw new Error('Latitude and longitude are required');
  }

  const apiKey = getOpenWeatherApiKey();
  const url = `${BASE_URL}/forecast?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&cnt=40`;

  const response = await fetch(url);
  const data = await response.json();

  if (!response.ok) {
    res.status(response.status);
    throw new Error(data.message || 'Failed to fetch weather forecast');
  }

  res.json(data);
});