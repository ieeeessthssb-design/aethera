import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';
import '../data/irrigation_api_service.dart';
import '../data/irrigation_providers.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends ConsumerState<DeviceManagementScreen> {
  static const _forest = Color(0xFF183F32);
  static const _cream = Color(0xFFF7F6EF);
  String? _farmId;
  bool _showAlerts = false;
  bool _busy = false;

  String _s(String en, String fr, String ar) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'fr': return fr;
      case 'ar': return ar;
      default: return en;
    }
  }

  IrrigationApiService get _api => IrrigationApiService(ApiClient(TokenStorage.instance));

  Future<void> _registerDevice(String farmId) async {
    final controller = TextEditingController();
    var isSimulated = true;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_s('Register device', 'Enregistrer un appareil', 'تسجيل جهاز')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(
          controller: controller,
          autofocus: true,
          maxLength: 100,
          decoration: InputDecoration(labelText: _s('Device name', 'Nom de l’appareil', 'اسم الجهاز'), hintText: 'Soil Sensor 01'),
        ), StatefulBuilder(builder: (context, setDialogState) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(_s('Simulated device', 'Appareil simulé', 'جهاز افتراضي')), subtitle: Text(_s('Generated readings from simulator.py', 'Mesures générées par simulator.py', 'قراءات مولدة بواسطة simulator.py')), value: isSimulated, onChanged: (v) => setDialogState(() => isSimulated = v))) ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(_s('Cancel', 'Annuler', 'إلغاء'))),
          FilledButton(onPressed: () { final value = controller.text.trim(); if (value.length >= 2) Navigator.pop(dialogContext, value); }, child: Text(_s('Register', 'Enregistrer', 'تسجيل'))),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().length < 2) return;
    setState(() => _busy = true);
    try {
      final created = await _api.createDevice(farmId: farmId, name: name.trim(), isSimulated: isSimulated);
      if (!mounted) return;
      ref.invalidate(farmDevicesProvider(farmId));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(_s('Device registered', 'Appareil enregistré', 'تم تسجيل الجهاز')),
          content: SelectableText('${_s('Save this key now. It is shown only once.', 'Enregistrez cette clé maintenant. Elle ne sera affichée qu’une fois.', 'احفظ هذا المفتاح الآن. سيظهر مرة واحدة فقط.')}\n\nDevice ID:\n${created['id']}\n\nDevice key:\n${created['device_key']}'),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) _message(_errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _errorText(Object error) => error.toString().replaceFirst('Exception: ', '');
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _showHistory(String farmId, Map<String, dynamic> device) async {
    try {
      final rows = await _api.getReadingHistory(farmId: farmId, deviceId: device['id'].toString(), limit: 30);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: Text('${device['name']} — ${_s('Recent readings', 'Mesures récentes', 'القراءات الأخيرة')}'),
        content: SizedBox(width: 520, child: rows.isEmpty
          ? Text(_s('No readings available.', 'Aucune mesure disponible.', 'لا توجد قراءات متاحة.'))
          : ListView.separated(shrinkWrap: true, itemCount: rows.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) {
              final row = rows[index];
              return ListTile(dense: true, title: Text('${row['soil_moisture']}% soil · ${row['temperature']}°C · ${row['humidity']}% RH'), subtitle: Text(row['recorded_at']?.toString() ?? ''), trailing: row['is_simulated'] == true ? const Text('SIM', style: TextStyle(color: Colors.deepPurple, fontSize: 10)) : null);
            })),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ));
    } catch (e) { if (mounted) _message(_errorText(e)); }
  }

  Future<void> _deactivate(String farmId, Map<String, dynamic> device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_s('Disable device?', 'Désactiver l’appareil ?', 'تعطيل الجهاز؟')),
        content: Text(_s('This revokes its ability to submit readings. It does not switch off a physical irrigation valve.', 'Cela bloque l’envoi de mesures. Cela ne ferme pas une vanne d’irrigation physique.', 'سيمنع الجهاز من إرسال القراءات، لكنه لا يغلق صمام الري فعلياً.')),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_s('Cancel', 'Annuler', 'إلغاء'))), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_s('Disable', 'Désactiver', 'تعطيل')))],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.deactivateDevice(farmId: farmId, deviceId: device['id'].toString());
      ref.invalidate(farmDevicesProvider(farmId));
      if (mounted) _message(_s('Device disabled.', 'Appareil désactivé.', 'تم تعطيل الجهاز.'));
    } catch (e) { if (mounted) _message(_errorText(e)); }
  }

  @override
  Widget build(BuildContext context) {
    final farmsAsync = ref.watch(myIrrigationFarmsProvider);
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream, foregroundColor: _forest, elevation: 0,
        title: Text(_s('Device Management', 'Gestion des appareils', 'إدارة الأجهزة'), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(tooltip: _s('Alerts', 'Alertes', 'التنبيهات'), onPressed: () => setState(() => _showAlerts = !_showAlerts), icon: Icon(_showAlerts ? Icons.sensors : Icons.notifications_active_outlined))],
      ),
      body: farmsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _centerMessage(_errorText(e)),
        data: (farms) {
          if (farms.isEmpty) return _centerMessage(_s('Create a farm before registering devices.', 'Créez une exploitation avant d’ajouter des appareils.', 'أنشئ مزرعة قبل تسجيل الأجهزة.'));
          final selectedId = farms.any((f) => f.id == _farmId) ? _farmId! : farms.first.id;
          final selectedFarm = farms.firstWhere((f) => f.id == selectedId);
          final devicesAsync = ref.watch(farmDevicesProvider(selectedId));
          final alertsAsync = ref.watch(farmAlertsProvider(selectedId));
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(farmDevicesProvider(selectedId)); ref.invalidate(farmAlertsProvider(selectedId)); await ref.read(farmDevicesProvider(selectedId).future); },
            child: ListView(padding: const EdgeInsets.all(18), children: [
              Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _forest, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.sensors_rounded, color: Colors.white, size: 34), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_s('IoT infrastructure', 'Infrastructure IoT', 'بنية إنترنت الأشياء'), style: const TextStyle(color: Colors.white70)), Text(selectedFarm.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)), Text(selectedFarm.location, style: const TextStyle(color: Colors.white70))]))])),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(value: selectedId, decoration: InputDecoration(labelText: _s('Farm', 'Exploitation', 'المزرعة'), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)), items: farms.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(), onChanged: (v) => setState(() => _farmId = v)),
              const SizedBox(height: 14),
              if (!_showAlerts) Row(children: [Expanded(child: Text(_s('Registered devices', 'Appareils enregistrés', 'الأجهزة المسجلة'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _forest))), FilledButton.icon(onPressed: _busy ? null : () => _registerDevice(selectedId), icon: const Icon(Icons.add), label: Text(_s('Add device', 'Ajouter', 'إضافة جهاز')))]),
              if (_showAlerts) Text(_s('Farm alerts', 'Alertes de la ferme', 'تنبيهات المزرعة'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _forest)),
              const SizedBox(height: 12),
              if (_showAlerts)
                alertsAsync.when(
                  data: (alerts) => Column(
                    children: alerts.map((a) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        title: Text(a['title']?.toString() ?? 'Alert'),
                        subtitle: Text(a['detail']?.toString() ?? ''),
                        trailing: TextButton(
                          onPressed: () async {
                            await _api.acknowledgeFarmAlert(
                              farmId: selectedId,
                              alertId: a['id'].toString(),
                            );
                            ref.invalidate(farmAlertsProvider(selectedId));
                          },
                          child: Text(_s('Acknowledge', 'Acquitter', 'تأكيد')),
                        ),
                      ),
                    )).toList(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (!_showAlerts) devicesAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _centerMessage(_errorText(e)),
                data: (devices) => devices.isEmpty ? _centerMessage(_s('No devices registered for this farm yet.', 'Aucun appareil enregistré pour cette ferme.', 'لا توجد أجهزة مسجلة لهذه المزرعة بعد.')) : Column(children: devices.map((d) => _deviceCard(selectedId, d)).toList()),
              ),
              const SizedBox(height: 20),
              Text(_s('Connection states: online ≤ 10 minutes; stale > 10 minutes; awaiting data = no readings received yet.', 'États : en ligne ≤ 10 min ; obsolète > 10 min ; en attente = aucune mesure reçue.', 'الحالات: متصل خلال 10 دقائق؛ قديم بعد 10 دقائق؛ بانتظار البيانات عند عدم وجود قراءات.'), style: const TextStyle(color: Colors.black54, height: 1.4)),
            ]),
          );
        },
      ),
    );
  }

  Widget _deviceCard(String farmId, Map<String, dynamic> device) {
    final id = device['id'].toString();
    final reading = ref.watch(latestDeviceReadingProvider('$farmId::$id'));
    final status = device['connection_status']?.toString() ?? 'unknown';
    final online = status == 'online';
    final disabled = status == 'disabled';
    final statusLabel = switch (status) {
      'online' => _s('Online', 'En ligne', 'متصل'),
      'stale' => _s('Stale', 'Données anciennes', 'البيانات قديمة'),
      'disabled' => _s('Disabled', 'Désactivé', 'معطّل'),
      _ => _s('Awaiting data', 'En attente de données', 'بانتظار البيانات'),
    };
    return Card(margin: const EdgeInsets.only(bottom: 12), color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE6EAE3))), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [CircleAvatar(backgroundColor: online ? const Color(0xFFE3F2E7) : const Color(0xFFFFF1DB), child: Icon(Icons.sensors, color: online ? Colors.green : Colors.orange)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(device['name']?.toString() ?? _s('IoT device', 'Appareil IoT', 'جهاز إنترنت الأشياء'), style: const TextStyle(fontWeight: FontWeight.w800, color: _forest)), if (device['is_simulated'] == true) Text(_s('SIMULATED', 'SIMULÉ', 'محاكاة'), style: const TextStyle(fontSize: 9, color: Colors.deepPurple, fontWeight: FontWeight.bold)), Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: online ? Colors.green : Colors.orange))])), if (!disabled) IconButton(tooltip: _s('Disable device', 'Désactiver', 'تعطيل الجهاز'), onPressed: () => _deactivate(farmId, device), icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent))]),
      const SizedBox(height: 8), SelectableText('${_s('ID', 'ID', 'المعرّف')}: $id', style: const TextStyle(fontSize: 11, color: Colors.black54)),
      Text('${_s('Last contact', 'Dernier contact', 'آخر اتصال')}: ${device['last_seen_at'] ?? _s('Never', 'Jamais', 'أبداً')}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
      Align(alignment: AlignmentDirectional.centerEnd, child: TextButton.icon(onPressed: () => _showHistory(farmId, device), icon: const Icon(Icons.history), label: Text(_s('Reading history', 'Historique des mesures', 'سجل القراءات')))),
      const Divider(height: 22),
      reading.when(loading: () => const LinearProgressIndicator(), error: (e, _) => Text(_errorText(e)), data: (r) => r == null ? Text(_s('No sensor readings received yet.', 'Aucune mesure reçue.', 'لم يتم استلام قراءات بعد.')) : Wrap(spacing: 18, runSpacing: 12, children: [ _metric(Icons.water_drop_outlined, _s('Soil', 'Sol', 'التربة'), '${r['soil_moisture']}%'), _metric(Icons.thermostat_outlined, _s('Temperature', 'Température', 'الحرارة'), '${r['temperature']}°C'), _metric(Icons.opacity, _s('Humidity', 'Humidité', 'الرطوبة'), '${r['humidity']}%') ])),
    ])));
  }

  Widget _metric(IconData icon, String label, String value) => SizedBox(width: 90, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: const Color(0xFF527B58)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: _forest))]));
  Widget _centerMessage(String message) => Padding(padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20), child: Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: _forest))));
}
