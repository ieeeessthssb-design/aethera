import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_providers.dart';
import '../../farmer/presentation/farm_api_service.dart';
import 'irrigation_api_service.dart';

final irrigationApiServiceProvider =
    Provider<IrrigationApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return IrrigationApiService(apiClient);
});

final myIrrigationFarmsProvider = FutureProvider<List<Farm>>((ref) async {
  return FarmApiService().getMyFarms();
});

final farmDevicesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, farmId) async {
    final service = ref.watch(irrigationApiServiceProvider);
    return service.getDevices(farmId);
  },
);

final latestDeviceReadingProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, key) async {
  final parts = key.split('::');
  if (parts.length != 2) {
    throw ArgumentError('Invalid device reading key');
  }

  final service = ref.watch(irrigationApiServiceProvider);
  return service.getLatestReading(
    farmId: parts[0],
    deviceId: parts[1],
  );
});
final farmAlertsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, farmId) async {
    final service = ref.watch(irrigationApiServiceProvider);
    return service.getFarmAlerts(farmId);
  },
);
