import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'weather_api_service.dart';

/// Farm-scoped forecast used by dashboard and other operational summaries.
final farmWeatherForecastProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, farmId) {
  return WeatherApiService().forecastForFarm(farmId);
});
