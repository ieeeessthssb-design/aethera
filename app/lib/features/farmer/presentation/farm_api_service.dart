

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class Farm {
  final String id;
  final String name;
  final String location;
  final double? areaHectares;
  final String? soilType;
  final String? irrigationType;
  final double? latitude;
  final double? longitude;

  const Farm({
    required this.id,
    required this.name,
    required this.location,
    this.areaHectares,
    this.soilType,
    this.irrigationType,
    this.latitude,
    this.longitude,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'].toString(),
      name: json['name'] as String,
      location: json['location'] as String,
      areaHectares: (json['area_hectares'] as num?)?.toDouble(),
      soilType: json['soil_type'] as String?,
      irrigationType: json['irrigation_type'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'area_hectares': areaHectares,
      'soil_type': soilType,
      'irrigation_type': irrigationType,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class FarmApiService {
  FarmApiService() : _apiClient = ApiClient(TokenStorage.instance);

  final ApiClient _apiClient;

  Future<List<Farm>> getMyFarms() async {
    final response = await _apiClient.dio.get('/farms');

    final data = response.data as List;

    return data
        .map((item) => Farm.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<Farm> updateFarmCoordinates({
    required String farmId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.dio.patch(
      '/farms/$farmId/location',
      data: {'latitude': latitude, 'longitude': longitude},
    );
    return Farm.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Farm> createFarm(Farm farm) async {
    final response = await _apiClient.dio.post(
      '/farms',
      data: farm.toJson(),
    );

    return Farm.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
