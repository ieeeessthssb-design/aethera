import 'package:flutter/material.dart';
import '../data/weather_api_service.dart';
import '../../farmer/presentation/farm_api_service.dart';
import '../../../l10n/generated/app_localizations.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final _api = WeatherApiService();
  final _locationController = TextEditingController();
  final _farmApi = FarmApiService();
  List<Farm> _farms = const [];
  Farm? _farmToSave;
  Map<String, dynamic>? _selectedLocation;
  Map<String, dynamic>? _forecast;
  String? _place;
  String? _error;
  bool _loading = false;
  bool _showingSavedFarmForecast = false;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    try {
      final farms = await _farmApi.getMyFarms();
      if (!mounted) return;
      setState(() {
        _farms = farms;
        _farmToSave = farms.isEmpty ? null : farms.first;
      });
      Farm? locatedFarm;
      for (final farm in farms) {
        if (farm.latitude != null && farm.longitude != null) {
          locatedFarm = farm;
          break;
        }
      }
      if (locatedFarm != null && _forecast == null) {
        if (mounted) setState(() => _farmToSave = locatedFarm);
        await _loadForFarm(locatedFarm);
      }
    } catch (_) {
      // Weather search remains available when the farmer has no saved farms.
    }
  }

  Future<void> _loadForFarm(Farm farm) async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _api.forecastForFarm(farm.id);
      if (!mounted) return;
      setState(() {
        _forecast = result;
        _showingSavedFarmForecast = true;
        _place = farm.location;
        _selectedLocation = {
          'latitude': farm.latitude,
          'longitude': farm.longitude,
          'timezone': 'auto',
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; });
    }
  }

  Future<void> _saveLocationToFarm() async {
    final farm = _farmToSave;
    final location = _selectedLocation;
    if (farm == null || location == null) return;
    try {
      final updated = await _farmApi.updateFarmCoordinates(
        farmId: farm.id,
        latitude: (location['latitude'] as num).toDouble(),
        longitude: (location['longitude'] as num).toDouble(),
      );
      if (!mounted) return;
      setState(() {
        _farms = _farms.map((item) => item.id == updated.id ? updated : item).toList();
        _farmToSave = updated;
        _showingSavedFarmForecast = true;
        _place = updated.location;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.weatherLocationSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppLocalizations.of(context)!.weatherLoadError);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadForPlace(String query) async {
    if (query.trim().length < 2) return;
    setState(() { _loading = true; _error = null; });
    try {
      final locations = await _api.searchLocations(query.trim());
      if (locations.isEmpty) throw Exception('No matching location found.');
      final location = locations.first;
      final result = await _api.forecast(
        latitude: (location['latitude'] as num).toDouble(),
        longitude: (location['longitude'] as num).toDouble(),
        timezone: location['timezone']?.toString() ?? 'auto',
      );
      if (!mounted) return;
      setState(() {
        _forecast = result;
        _showingSavedFarmForecast = false;
        _selectedLocation = location;
        _place = [location['name'], location['admin1'], location['country']]
            .where((v) => v != null && v.toString().isNotEmpty).join(', ');
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = AppLocalizations.of(context)!.weatherLoadError; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _forecast?['current'] as Map<String, dynamic>?;
    final daily = _forecast?['daily'] as Map<String, dynamic>?;
    final alerts = (_forecast?['notable_changes'] as List<dynamic>? ?? []);
    final hourly = _forecast?['hourly'] as Map<String, dynamic>?;
    final times = hourly?['time'] as List<dynamic>? ?? [];
    final temps = hourly?['temperature_2m'] as List<dynamic>? ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6EF),
      appBar: AppBar(title: Text(l10n.weatherFarmTitle), backgroundColor: const Color(0xFFF5F6EF)),
      body: _loading && _forecast == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                final farm = _farmToSave;
                if (_showingSavedFarmForecast && farm != null && farm.latitude != null && farm.longitude != null) {
                  await _loadForFarm(farm);
                } else {
                  await _loadForPlace(_locationController.text);
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                children: [
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _locationController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _loadForPlace,
                      decoration: InputDecoration(
                        hintText: l10n.weatherSearchHint, prefixIcon: const Icon(Icons.location_on_outlined),
                        filled: true, fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    )),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _loading ? null : () => _loadForPlace(_locationController.text), icon: const Icon(Icons.search)),
                  ]),
                  if (_selectedLocation != null && _farms.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: DropdownButtonFormField<Farm>(
                          value: _farmToSave,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.chooseFarm,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          items: _farms.map((farm) => DropdownMenuItem(value: farm, child: Text(farm.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (farm) => setState(() => _farmToSave = farm),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _loading ? null : _saveLocationToFarm,
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: Text(l10n.save),
                      ),
                    ]),
                  ],
                  if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                  if (current == null && !_loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(children: [
                        Icon(Icons.location_searching_rounded, size: 46, color: Color(0xFF527B58)),
                        SizedBox(height: 12),
                        Text(l10n.weatherChooseLocation, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF183F32))),
                        SizedBox(height: 6),
                        Text(l10n.weatherSearchDescription, textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                      ]),
                    ),
                  if (current != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: const Color(0xFF183F32), borderRadius: BorderRadius.circular(24)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_place ?? l10n.weatherSelectedLocation, style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 10),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Icon(Icons.wb_sunny_rounded, color: Color(0xFFFFD77A), size: 46),
                          const SizedBox(width: 14),
                          Text('${(current['temperature_2m'] as num).round()}°', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w300)),
                        ]),
                        Text('${l10n.weatherFeelsLike} ${(current['apparent_temperature'] as num?)?.round() ?? '—'}°', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 18),
                        Wrap(spacing: 18, runSpacing: 12, children: [
                          _metric(l10n.weatherHumidity, '${current['relative_humidity_2m']}%'),
                          _metric(l10n.weatherWind, '${current['wind_speed_10m']} km/h'),
                          _metric(l10n.weatherRainNow, '${current['precipitation']} mm'),
                          _metric(l10n.weatherWindDirection, '${current['wind_direction_10m']}°'),
                          _metric(l10n.weatherSunrise, _clock(_first(daily?['sunrise']))),
                          _metric(l10n.weatherSunset, _clock(_first(daily?['sunset']))),
                          _metric(l10n.weatherUv, '${_first(daily?['uv_index_max']) ?? '—'}'),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.weatherNextHours, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF183F32))),
                    const SizedBox(height: 10),
                    SizedBox(height: 104, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: times.length < 24 ? times.length : 24, itemBuilder: (context, index) {
                      final time = DateTime.tryParse(times[index].toString());
                      return Container(width: 76, margin: const EdgeInsets.only(right: 9), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text(time == null ? '--:--' : '${time.hour.toString().padLeft(2, '0')}:00'), const Icon(Icons.wb_cloudy_outlined, color: Color(0xFF527B58)), Text('${(temps[index] as num).round()}°', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${_valueAt(hourly?['precipitation_probability'], index) ?? 0}% ${l10n.weatherRainProbability}', style: const TextStyle(fontSize: 9, color: Colors.black54))]));
                    })),
                    const SizedBox(height: 22),
                    Text(l10n.weatherOutlook, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF183F32))),
                    const SizedBox(height: 8),
                    ..._dailyRows(daily),
                    const SizedBox(height: 20),
                    Text(l10n.weatherChanges, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF183F32))),
                    const SizedBox(height: 8),
                    if (alerts.isEmpty) Card(child: ListTile(leading: const Icon(Icons.check_circle_outline, color: Colors.green), title: Text(l10n.weatherNoChanges))),
                    ...alerts.map(
                      (item) => Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications_active_outlined,
                            color: Color(0xFFB36B2C),
                          ),
                          title: Text(item['title'].toString()),
                          subtitle: Text(
                            "${item['time']} · ${item['detail']}",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_forecast?['agricultural_note']?.toString() ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(l10n.weatherSource, style: TextStyle(color: Colors.black45, fontSize: 11)),
                  ],
                ],
              ),
            ),
    );
  }

  dynamic _first(dynamic values) => values is List && values.isNotEmpty ? values.first : null;
  dynamic _valueAt(dynamic values, int index) => values is List && index < values.length ? values[index] : null;
  String _clock(dynamic value) {
    final parsed = value == null ? null : DateTime.tryParse(value.toString());
    return parsed == null ? '—' : '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  Widget _metric(String label, String value) => SizedBox(width: 125, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))]));

  List<Widget> _dailyRows(Map<String, dynamic>? daily) {
    if (daily == null) return [];
    final l10n = AppLocalizations.of(context)!;
    final dates = daily['time'] as List<dynamic>? ?? [];
    final max = daily['temperature_2m_max'] as List<dynamic>? ?? [];
    final min = daily['temperature_2m_min'] as List<dynamic>? ?? [];
    final rain = daily['precipitation_probability_max'] as List<dynamic>? ?? [];
    return List.generate(dates.length, (i) => Card(color: Colors.white, child: ListTile(
      dense: true, leading: const Icon(Icons.wb_cloudy_outlined, color: Color(0xFF527B58)),
      title: Text(dates[i].toString()),
      subtitle: Text('${l10n.weatherRain} ${i < rain.length ? rain[i] : 0}% · ${_valueAt(daily['precipitation_sum'], i) ?? 0} mm'),
      trailing: Text('${(max[i] as num).round()}° / ${(min[i] as num).round()}°', style: const TextStyle(fontWeight: FontWeight.bold)),
    )));
  }
}
