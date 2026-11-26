import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/irrigation_providers.dart';
import '../../../l10n/generated/app_localizations.dart';

class IrrigationScreen extends ConsumerStatefulWidget {
  const IrrigationScreen({super.key});

  @override
  ConsumerState<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends ConsumerState<IrrigationScreen> {
  String? _selectedFarmId;
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    _monitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      if (_selectedFarmId != null) {
        ref.invalidate(farmDevicesProvider(_selectedFarmId!));
      }
      ref.invalidate(latestDeviceReadingProvider);
    });
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  static const Color _forest = Color(0xFF183F32);
  static const Color _green = Color(0xFF527B58);
  static const Color _cream = Color(0xFFF7F6EF);

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(myIrrigationFarmsProvider);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.irrigationTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _cream,
        foregroundColor: _forest,
        elevation: 0,
      ),
      body: farmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _errorState(
          AppLocalizations.of(context)!.irrigationLoadFarmsError,
          () => ref.invalidate(myIrrigationFarmsProvider),
        ),
        data: (farms) {
          if (farms.isEmpty) {
            return _emptyState(
              Icons.agriculture_outlined,
              AppLocalizations.of(context)!.irrigationNoFarms,
              AppLocalizations.of(context)!.irrigationAddFarmFirst,
            );
          }

          final selectedFarm = farms.any(
            (farm) => farm.id == _selectedFarmId,
          )
              ? _selectedFarmId!
              : farms.first.id;

          final farm = farms.firstWhere((item) => item.id == selectedFarm);
          final devicesAsync = ref.watch(farmDevicesProvider(selectedFarm));

          return RefreshIndicator(
            color: _green,
            onRefresh: () async {
              ref.invalidate(farmDevicesProvider(selectedFarm));
              ref.invalidate(latestDeviceReadingProvider);
              await ref.read(farmDevicesProvider(selectedFarm).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                _introCard(context),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.irrigationSelectFarm,
                  style: TextStyle(
                    color: _forest,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFarm,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      items: farms.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFarmId = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  farm.location,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.irrigationConnectedDevices,
                        style: TextStyle(
                          color: _forest,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: AppLocalizations.of(context)!.irrigationRefresh,
                      onPressed: () {
                        ref.invalidate(farmDevicesProvider(selectedFarm));
                        ref.invalidate(latestDeviceReadingProvider);
                      },
                      icon: const Icon(Icons.refresh_rounded, color: _green),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                devicesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(35),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => _errorState(
                    AppLocalizations.of(context)!.irrigationLoadDevicesError,
                    () => ref.invalidate(farmDevicesProvider(selectedFarm)),
                  ),
                  data: (devices) {
                    if (devices.isEmpty) {
                      return _emptyState(
                        Icons.sensors_off_outlined,
                        AppLocalizations.of(context)!.irrigationNoDevices,
                        AppLocalizations.of(context)!.irrigationNoDevicesDescription,
                      );
                    }

                    return Column(
                      children: devices.map((device) {
                        final deviceId =
                            (device['id'] ?? device['device_id'] ?? '')
                                .toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 13),
                          child: _deviceCard(
                            device: device,
                            farmId: selectedFarm,
                            deviceId: deviceId,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1E8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, color: _forest),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.irrigationInfo,
                          style: TextStyle(
                            color: _forest,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _introCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: _forest,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.irrigationMonitorFarm,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  AppLocalizations.of(context)!.irrigationMonitorDescription,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(
            Icons.water_drop_rounded,
            size: 48,
            color: Color(0xFFB9DFC0),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard({
    required Map<String, dynamic> device,
    required String farmId,
    required String deviceId,
  }) {
    final name = (device['name'] ??
            device['device_name'] ??
            device['type'] ??
            AppLocalizations.of(context)!.irrigationDevice)
        .toString();

    final status = (device['connection_status'] ?? device['status'] ?? 'unknown').toString();
    final isActive = device['is_active'] != false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.sensors_rounded,
                    color: _forest,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _forest,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deviceId.isEmpty ? AppLocalizations.of(context)!.irrigationDeviceIdUnavailable : deviceId,
                        style: const TextStyle(color: Colors.black45, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (device['last_seen_at'] != null)
                        Text(
                          '${_localized('Last contact', 'Dernier contact', 'آخر اتصال')}: ${DateTime.tryParse(device['last_seen_at'].toString())?.toLocal().toString().split('.').first ?? '—'}',
                          style: const TextStyle(color: Colors.black45, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                _connectionBadge(status),
              ],
            ),
            const Divider(height: 25),
            Text(
              AppLocalizations.of(context)!.irrigationLatestReading,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _forest,
              ),
            ),
            const SizedBox(height: 10),
            if (deviceId.isEmpty)
              Text(
                AppLocalizations.of(context)!.irrigationDeviceIdUnreadable,
                style: const TextStyle(color: Colors.black54),
              )
            else
              _readingContent(farmId, deviceId),
            if (isActive) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: deviceId.isEmpty ? null : () => _confirmDeactivate(farmId, deviceId, name),
                  icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                  label: Text(_localized('Disable device', 'Désactiver l’appareil', 'تعطيل الجهاز')),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _readingContent(String farmId, String deviceId) {
    final reading = ref.watch(
      latestDeviceReadingProvider('$farmId::$deviceId'),
    );

    return reading.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, stack) => Text(
        AppLocalizations.of(context)!.irrigationReadingUnavailable,
        style: TextStyle(color: Colors.black54, fontSize: 13),
      ),
      data: (data) {
        if (data == null || data.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.irrigationNoReadings,
            style: TextStyle(color: Colors.black54, fontSize: 13),
          );
        }

        final recordedAt = DateTime.tryParse((data['recorded_at'] ?? '').toString());
        final age = recordedAt == null ? null : DateTime.now().difference(recordedAt.toLocal());
        final isFresh = age != null && age >= Duration.zero && age <= const Duration(minutes: 10);
        final sensorRows = <(String, String)>[
          ('Soil moisture', '${data['soil_moisture'] ?? '—'} %'),
          ('Temperature', '${data['temperature'] ?? '—'} °C'),
          ('Humidity', '${data['humidity'] ?? '—'} %'),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isFresh ? const Color(0xFFEAF1E8) : const Color(0xFFFFF2DF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(isFresh ? Icons.check_circle_outline : Icons.schedule, size: 16,
                    color: isFresh ? _forest : Colors.orange.shade800),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  recordedAt == null
                      ? _localized('Reading time unavailable', 'Heure de lecture indisponible', 'وقت القراءة غير متاح')
                      : '${_localized(isFresh ? 'Fresh reading' : 'Stale reading', isFresh ? 'Lecture récente' : 'Lecture ancienne', isFresh ? 'قراءة حديثة' : 'قراءة قديمة')} · ${_formatAge(age!)}',
                  style: TextStyle(fontSize: 12, color: isFresh ? _forest : Colors.orange.shade900),
                )),
              ]),
            ),
            ...sensorRows.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(child: Text(row.$1, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                Text(row.$2, style: const TextStyle(color: _forest, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            )),
          ],
        );
      },
    );
  }

  String _localized(String en, String fr, String ar) {
    final language = Localizations.localeOf(context).languageCode;
    if (language == 'fr') return fr;
    if (language == 'ar') return ar;
    return en;
  }

  String _formatAge(Duration age) {
    if (age.inDays > 0) return '${age.inDays}d ${age.inHours.remainder(24)}h';
    if (age.inHours > 0) return '${age.inHours}h ${age.inMinutes.remainder(60)}m';
    if (age.inMinutes > 0) return '${age.inMinutes}m';
    return '${age.inSeconds}s';
  }

  Widget _connectionBadge(String status) {
    final normalized = status.toLowerCase();
    final online = normalized == 'online';
    final disabled = normalized == 'disabled';
    final label = switch (normalized) {
      'online' => _localized('Online', 'En ligne', 'متصل'),
      'stale' => _localized('Stale', 'Données anciennes', 'بيانات قديمة'),
      'disabled' => _localized('Disabled', 'Désactivé', 'معطّل'),
      _ => _localized('Awaiting data', 'En attente de données', 'بانتظار البيانات'),
    };
    final color = online ? _forest : (disabled ? Colors.grey : Colors.orange.shade800);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: online ? const Color(0xFFEAF1E8) : (disabled ? Colors.grey.shade100 : const Color(0xFFFFF2DF)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _confirmDeactivate(String farmId, String deviceId, String deviceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_localized('Disable device?', 'Désactiver l’appareil ?', 'هل تريد تعطيل الجهاز؟')),
        content: Text(_localized(
          '“$deviceName” will stop accepting sensor readings until it is replaced or re-enabled by an administrator. This does not switch off a physical irrigation valve.',
          '« $deviceName » cessera d’accepter les mesures. Cette action ne commande pas une vanne d’irrigation physique.',
          'سيتوقف الجهاز عن استقبال القراءات. هذا الإجراء لا يتحكم في صمام الري الفعلي.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(_localized('Cancel', 'Annuler', 'إلغاء'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: Text(_localized('Disable', 'Désactiver', 'تعطيل'))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(irrigationApiServiceProvider).deactivateDevice(farmId: farmId, deviceId: deviceId);
      ref.invalidate(farmDevicesProvider(farmId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_localized('Device disabled.', 'Appareil désactivé.', 'تم تعطيل الجهاز.')),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_localized('Could not disable the device.', 'Impossible de désactiver l’appareil.', 'تعذر تعطيل الجهاز.')),
      ));
    }
  }


  Widget _emptyState(IconData icon, String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: _green),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 45,
              color: _green,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.irrigationRetry),
            ),
          ],
        ),
      ),
    );
  }
}