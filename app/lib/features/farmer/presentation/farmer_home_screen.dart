import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../irrigation/data/irrigation_providers.dart';
import '../../weather/data/weather_providers.dart';
import 'farm_api_service.dart';

class FarmerHomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigate;

  const FarmerHomeScreen({super.key, this.onNavigate});

  @override
  ConsumerState<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends ConsumerState<FarmerHomeScreen> {
  static const Color forest = Color(0xFF183F32);
  static const Color green = Color(0xFF527B58);
  static const Color cream = Color(0xFFF7F6EF);
  static const Color ink = Color(0xFF24352C);
  static const Color muted = Color(0xFF657168);
  static const Color border = Color(0xFFE6EAE2);

  final FarmApiService _farmApi = FarmApiService();
  List<Farm> _farms = const [];
  Farm? _selectedFarm;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadFarms();
  }

  Future<void> _loadFarms() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final farms = await _farmApi.getMyFarms();
      if (!mounted) return;
      setState(() {
        _farms = farms;
        if (_selectedFarm == null || !farms.any((f) => f.id == _selectedFarm!.id)) {
          _selectedFarm = farms.isEmpty ? null : farms.first;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadFarms();
    final farm = _selectedFarm;
    if (farm != null) {
      ref.invalidate(farmDevicesProvider(farm.id));
      ref.invalidate(farmAlertsProvider(farm.id));
      ref.invalidate(farmWeatherForecastProvider(farm.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 620;

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: forest,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsetsDirectional.fromSTEB(compact ? 18 : 30, 18, compact ? 18 : 30, 34),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _header(l10n),
                    const SizedBox(height: 28),
                    _welcome(l10n),
                    const SizedBox(height: 22),
                    _farmContextCard(l10n),
                    const SizedBox(height: 22),
                    _sectionTitle(l10n.weatherFarmTitle, l10n.weather),
                    const SizedBox(height: 13),
                    _weatherOverview(l10n),
                    const SizedBox(height: 27),
                    _sectionTitle(l10n.dashboardOperations, l10n.dashboardDevices),
                    const SizedBox(height: 13),
                    _deviceOverview(l10n),
                    const SizedBox(height: 27),
                    _sectionTitle(l10n.dashboardAlerts, l10n.dashboardDevices),
                    const SizedBox(height: 13),
                    _alertsOverview(l10n),
                    const SizedBox(height: 27),
                    _sectionTitle(l10n.dashboardTitle, l10n.dashboardFarmProfile),
                    const SizedBox(height: 13),
                    _farmSummary(l10n),
                    const SizedBox(height: 27),
                    _sectionTitle(l10n.exploreTools, l10n.preferences),
                    const SizedBox(height: 13),
                    _toolsGrid(context, isRtl, l10n, compact: compact),
                    const SizedBox(height: 22),
                    Center(
                      child: Text(
                        'AETHERA · SMART AGRICULTURE',
                        style: TextStyle(color: muted.withValues(alpha: .8), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: forest, borderRadius: BorderRadius.circular(15)),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AETHERA', style: TextStyle(color: forest, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1.8)),
              Text(l10n.dashboardSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10)),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.tryAgain,
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded, color: forest),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48), backgroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _welcome(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.greeting.toUpperCase(), style: const TextStyle(color: green, fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(l10n.welcomeTitle, style: const TextStyle(color: ink, fontSize: 29, height: 1.12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(l10n.welcomeSubtitle, style: const TextStyle(color: muted, fontSize: 13, height: 1.5)),
      ],
    );
  }

  Widget _farmContextCard(AppLocalizations l10n) {
    final farm = _selectedFarm;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: AlignmentDirectional.topStart, end: AlignmentDirectional.bottomEnd, colors: [Color(0xFF183F32), Color(0xFF285B43)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: forest.withValues(alpha: .13), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.agriculture_rounded, color: Color(0xFFDCEBCB), size: 20),
            const SizedBox(width: 9),
            Expanded(child: Text(l10n.chooseFarm, style: const TextStyle(color: Color(0xFFDCEBCB), fontWeight: FontWeight.w700, fontSize: 12))),
            if (!_loading && !_failed && _farms.isNotEmpty)
              _pill('${_farms.length} ${l10n.farms.toLowerCase()}', Colors.white.withValues(alpha: .13), Colors.white),
          ]),
          const SizedBox(height: 15),
          if (_loading)
            const LinearProgressIndicator(minHeight: 3, color: Color(0xFFDCEBCB), backgroundColor: Colors.white24)
          else if (_failed)
            Row(children: [
              Expanded(child: Text(l10n.farmLoadError, style: const TextStyle(color: Colors.white, fontSize: 12))),
              TextButton(onPressed: _loadFarms, child: Text(l10n.tryAgain, style: const TextStyle(color: Color(0xFFDCEBCB)))),
            ])
          else if (_farms.isEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.noFarms, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(l10n.addFirstFarm, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
            ])
          else
            Column(
              children: _farms.map((item) {
                final isSelected = item.id == farm?.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? Colors.white.withValues(alpha: .15) : Colors.white.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() => _selectedFarm = item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Row(children: [
                          Icon(isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: const Color(0xFFDCEBCB), size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 3),
                            Text(item.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ])),
                          if (item.areaHectares != null) Text('${item.areaHectares!.toStringAsFixed(1)} ${l10n.hectares}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 17),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => widget.onNavigate?.call(1),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDCEBCB)),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(l10n.yourFarms),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weatherOverview(AppLocalizations l10n) {
    if (_loading) return const _DashboardLoadingCard();
    if (_failed) {
      return _stateCard(
        Icons.cloud_off_outlined,
        l10n.farmLoadError,
        l10n.tryAgain,
        _loadFarms,
      );
    }

    final farm = _selectedFarm;
    if (farm == null) {
      return _stateCard(
        Icons.location_searching_rounded,
        l10n.weatherChooseLocation,
        l10n.addFarm,
        () => widget.onNavigate?.call(1),
      );
    }

    if (farm.latitude == null || farm.longitude == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_on_outlined, color: forest),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.weatherChooseLocation,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.weatherSearchDescription,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.dashboardWeatherAction,
              onPressed: () => widget.onNavigate?.call(5),
              icon: const Icon(Icons.arrow_forward_rounded, color: green),
            ),
          ],
        ),
      );
    }

    final forecastAsync = ref.watch(farmWeatherForecastProvider(farm.id));
    return forecastAsync.when(
      loading: () => const _DashboardLoadingCard(),
      error: (_, __) => _stateCard(
        Icons.cloud_off_outlined,
        l10n.weatherLoadError,
        l10n.tryAgain,
        () => ref.invalidate(farmWeatherForecastProvider(farm.id)),
      ),
      data: (forecast) {
        final currentValue = forecast['current'];
        if (currentValue is! Map) {
          return _stateCard(
            Icons.cloud_off_outlined,
            l10n.weatherLoadError,
            l10n.tryAgain,
            () => ref.invalidate(farmWeatherForecastProvider(farm.id)),
          );
        }
        final current = Map<String, dynamic>.from(currentValue);
        final temperature = current['temperature_2m'];
        final feelsLike = current['apparent_temperature'];
        final humidity = current['relative_humidity_2m'];
        final wind = current['wind_speed_10m'];
        final rain = current['precipitation'];
        final notableChanges = forecast['notable_changes'] is List
            ? (forecast['notable_changes'] as List).length
            : 0;

        return Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [Color(0xFFFFFFFF), Color(0xFFF0F5EC)],
            ),
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFDDE8DA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EFE1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFF527B58),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          farm.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.dashboardWeatherAction,
                    onPressed: () => widget.onNavigate?.call(5),
                    icon: const Icon(Icons.open_in_new_rounded, color: green),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    temperature is num ? '${temperature.round()}°' : '—',
                    style: const TextStyle(
                      color: forest,
                      fontSize: 42,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      '${l10n.weatherFeelsLike} ${feelsLike is num ? '${feelsLike.round()}°' : '—'}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (notableChanges > 0)
                    _pill(
                      '$notableChanges ${l10n.weatherChanges}',
                      const Color(0xFFFFF0D8),
                      const Color(0xFF815B19),
                    ),
                ],
              ),
              const SizedBox(height: 17),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _weatherMetric(
                    Icons.water_drop_outlined,
                    l10n.weatherHumidity,
                    humidity is num ? '${humidity.round()}%' : '—',
                  ),
                  _weatherMetric(
                    Icons.air_rounded,
                    l10n.weatherWind,
                    wind is num ? '${wind.round()} km/h' : '—',
                  ),
                  _weatherMetric(
                    Icons.grain_rounded,
                    l10n.weatherRainNow,
                    rain is num ? '${rain.toStringAsFixed(1)} mm' : '—',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _weatherMetric(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: green, size: 16),
          const SizedBox(width: 7),
          Text(
            '$label  $value',
            style: const TextStyle(
              color: ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceOverview(AppLocalizations l10n) {
    if (_loading) return const _DashboardLoadingCard();
    if (_failed) return _stateCard(Icons.cloud_off_outlined, l10n.farmLoadError, l10n.tryAgain, _loadFarms);
    final farm = _selectedFarm;
    if (farm == null) return _stateCard(Icons.sensors_off_outlined, l10n.dashboardNoDevices, l10n.addFarm, () => widget.onNavigate?.call(1));

    final devicesAsync = ref.watch(farmDevicesProvider(farm.id));
    return devicesAsync.when(
      loading: () => const _DashboardLoadingCard(),
      error: (_, __) => _stateCard(Icons.cloud_off_outlined, l10n.dashboardDeviceLoadError, l10n.tryAgain, () => ref.invalidate(farmDevicesProvider(farm.id))),
      data: (devices) {
        if (devices.isEmpty) {
          return _stateCard(Icons.sensors_off_outlined, l10n.dashboardNoDevices, l10n.dashboardViewIrrigation, () => widget.onNavigate?.call(2));
        }
        final active = devices.where((device) => device['connection_status'] == 'online').length;
        final inactive = devices.where((device) => device['connection_status'] == 'stale' || device['connection_status'] == 'disabled').length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: _statCard(Icons.sensors_rounded, '$active', l10n.dashboardOnline, const Color(0xFFE7F0E5))),
              const SizedBox(width: 10),
              Expanded(child: _statCard(Icons.sensors_off_outlined, '$inactive', l10n.dashboardInactive, const Color(0xFFF1EEE6))),
            ]),
            const SizedBox(height: 12),
            ...devices.take(3).map((device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _deviceCard(device, farm.id, l10n),
            )),
            if (devices.length > 3)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: () => widget.onNavigate?.call(2),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(l10n.dashboardViewIrrigation),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _alertsOverview(AppLocalizations l10n) {
    final farm = _selectedFarm;
    if (_loading) return const _DashboardLoadingCard();
    if (_failed) return _stateCard(Icons.cloud_off_outlined, l10n.farmLoadError, l10n.tryAgain, _loadFarms);
    if (farm == null) return _stateCard(Icons.notifications_none_rounded, l10n.dashboardNoAlerts, l10n.addFarm, () => widget.onNavigate?.call(1));

    final alertsAsync = ref.watch(farmAlertsProvider(farm.id));
    return alertsAsync.when(
      loading: () => const _DashboardLoadingCard(),
      error: (_, __) => _stateCard(Icons.cloud_off_outlined, l10n.dashboardDeviceLoadError, l10n.tryAgain, () => ref.invalidate(farmAlertsProvider(farm.id))),
      data: (alerts) {
        if (alerts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
            child: Row(children: [
              const Icon(Icons.verified_outlined, color: green),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.dashboardNoAlerts, style: const TextStyle(color: muted, fontSize: 12, height: 1.4))),
            ]),
          );
        }
        return Column(children: alerts.take(5).map((alert) {
          final severity = (alert['severity'] ?? 'notable').toString();
          final alertId = (alert['id'] ?? '').toString();
          final critical = severity == 'critical' || severity == 'warning';
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: border)),
            child: ListTile(
              leading: Icon(Icons.notifications_active_outlined, color: critical ? const Color(0xFFB45B42) : const Color(0xFFB18432)),
              title: Text((alert['title'] ?? '').toString(), style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w800)),
              subtitle: Text((alert['detail'] ?? '').toString(), style: const TextStyle(color: muted, fontSize: 11, height: 1.35)),
              trailing: IconButton(
                tooltip: l10n.dashboardAcknowledge,
                onPressed: alertId.isEmpty ? null : () async {
                  try {
                    await ref.read(irrigationApiServiceProvider).acknowledgeFarmAlert(farmId: farm.id, alertId: alertId);
                    ref.invalidate(farmAlertsProvider(farm.id));
                  } catch (_) {
                    ref.invalidate(farmAlertsProvider(farm.id));
                  }
                },
                icon: const Icon(Icons.done_rounded, color: green),
              ),
            ),
          );
        }).toList());
      },
    );
  }

  Widget _deviceCard(Map<String, dynamic> device, String farmId, AppLocalizations l10n) {
    final id = (device['id'] ?? '').toString();
    final name = (device['name'] ?? l10n.irrigationDevice).toString();
    final active = device['is_active'] == true;
    final connectionStatus = (device['connection_status'] ?? 'unknown').toString();
    final statusLabel = connectionStatus == 'online'
        ? l10n.dashboardOnline
        : connectionStatus == 'disabled'
            ? l10n.dashboardDisabled
            : connectionStatus == 'stale'
                ? l10n.dashboardStale
                : l10n.dashboardUnknown;
    final statusColor = connectionStatus == 'online'
        ? forest
        : connectionStatus == 'disabled'
            ? const Color(0xFF8A4D3D)
            : const Color(0xFF815B19);
    final statusBackground = connectionStatus == 'online'
        ? const Color(0xFFE7F0E5)
        : connectionStatus == 'disabled'
            ? const Color(0xFFF4EAE6)
            : const Color(0xFFFFF3D9);
    final readingAsync = id.isEmpty ? null : ref.watch(latestDeviceReadingProvider('$farmId::$id'));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEAF1E8), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.sensors_rounded, color: forest)),
          const SizedBox(width: 11),
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13))),
          _pill(statusLabel, statusBackground, statusColor),
        ]),
        const SizedBox(height: 13),
        if (readingAsync == null)
          Text(l10n.dashboardNoReading, style: const TextStyle(color: muted, fontSize: 12))
        else
          readingAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => Text(l10n.irrigationReadingUnavailable, style: const TextStyle(color: muted, fontSize: 12)),
            data: (reading) {
              if (reading == null) return Text(l10n.dashboardNoReading, style: const TextStyle(color: muted, fontSize: 12));
              final moisture = reading['soil_moisture'];
              final recordedAt = DateTime.tryParse((reading['recorded_at'] ?? '').toString())?.toLocal();
              final time = recordedAt == null ? '—' : '${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.water_drop_outlined, color: green, size: 17),
                  const SizedBox(width: 7),
                  Expanded(child: Text(l10n.dashboardLatestMoisture, style: const TextStyle(color: muted, fontSize: 11))),
                  Text(moisture is num ? '${moisture.toStringAsFixed(1)}%' : '—', style: const TextStyle(color: forest, fontSize: 15, fontWeight: FontWeight.w900)),
                ]),
                if (recordedAt != null) ...[
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 13, color: muted),
                    const SizedBox(width: 5),
                    Expanded(child: Text(l10n.dashboardReadingTime(time), style: const TextStyle(color: muted, fontSize: 10))),
                    if (reading['is_simulated'] == true) _pill(l10n.dashboardSimulated, const Color(0xFFFFF3D9), const Color(0xFF815B19)),
                  ]),
                ],
              ]);
            },
          ),
      ]),
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color tint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: forest, size: 19)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w900)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w600))])),
      ]),
    );
  }

  Widget _farmSummary(AppLocalizations l10n) {
    if (_loading) return const _DashboardLoadingCard();
    if (_failed) return _stateCard(Icons.cloud_off_outlined, l10n.farmLoadError, l10n.tryAgain, _loadFarms);
    if (_farms.isEmpty || _selectedFarm == null) return _stateCard(Icons.add_business_outlined, l10n.noFarms, l10n.addFarm, () => widget.onNavigate?.call(1));
    final farm = _selectedFarm!;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.check_circle_outline_rounded, color: green, size: 19), const SizedBox(width: 8), Expanded(child: Text(farm.name, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14))), const Icon(Icons.verified_user_outlined, color: muted, size: 18)]),
        const SizedBox(height: 13),
        const Divider(height: 1, color: border),
        const SizedBox(height: 13),
        _detailRow(Icons.location_on_outlined, farm.location),
        if (farm.areaHectares != null) ...[const SizedBox(height: 10), _detailRow(Icons.square_foot_rounded, '${l10n.area}: ${farm.areaHectares!.toStringAsFixed(1)} ${l10n.hectares}')],
        if (farm.soilType != null && farm.soilType!.isNotEmpty) ...[const SizedBox(height: 10), _detailRow(Icons.terrain_outlined, farm.soilType!)],
        if (farm.irrigationType != null && farm.irrigationType!.isNotEmpty) ...[const SizedBox(height: 10), _detailRow(Icons.water_drop_outlined, farm.irrigationType!)],
      ]),
    );
  }

  Widget _detailRow(IconData icon, String text) => Row(children: [Icon(icon, color: green, size: 17), const SizedBox(width: 9), Expanded(child: Text(text, style: const TextStyle(color: muted, fontSize: 12)))]);

  Widget _stateCard(IconData icon, String title, String action, VoidCallback onTap) {
    return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: border)), child: Row(children: [Icon(icon, color: green, size: 25), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600))), TextButton(onPressed: onTap, child: Text(action))]));
  }

  Widget _sectionTitle(String title, String tag) => Row(children: [Expanded(child: Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w900))), Text(tag.toUpperCase(), style: const TextStyle(color: green, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800))]);

  Widget _pill(String label, Color background, Color foreground) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)), child: Text(label, style: TextStyle(color: foreground, fontSize: 9, fontWeight: FontWeight.w800)));

  Widget _toolsGrid(BuildContext context, bool isRtl, AppLocalizations l10n, {required bool compact}) {
    final tools = [
      (Icons.auto_awesome_rounded, l10n.assistant, 3),
      (Icons.document_scanner_outlined, l10n.diagnosis, 4),
      (Icons.water_drop_outlined, l10n.irrigation, 2),
      (Icons.wb_sunny_outlined, l10n.weather, 5),
      (Icons.groups_2_outlined, l10n.community, 6),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: compact ? 2 : 3, mainAxisSpacing: 11, crossAxisSpacing: 11, childAspectRatio: compact ? 1.5 : 1.65),
      itemBuilder: (context, index) {
        final item = tools[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => widget.onNavigate?.call(item.$3),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(item.$1, color: green, size: 23),
                const Spacer(),
                Text(item.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)),
                Align(alignment: AlignmentDirectional.centerEnd, child: Icon(isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: green, size: 16)),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6EAE2))),
        child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF527B58)))),
      );
}
