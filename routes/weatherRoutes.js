import express from 'express';
import { getWeather, getWeatherForecast, getGeocode } from '../controllers/weatherController.js';

const router = express.Router();

router.get('/current', getWeather);
router.get('/forecast', getWeatherForecast);
router.get('/geocode', getGeocode);

export default router;