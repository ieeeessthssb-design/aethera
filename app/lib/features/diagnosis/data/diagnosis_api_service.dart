import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/token_storage.dart';

class DiagnosisCase {
  final String id;
  final String farmerId;
  final String farmId;
  final String symptoms;
  final String status;
  final String photoPath;
  final String? expertDiagnosis;
  final String? expertAdvice;
  final DateTime? createdAt;

  const DiagnosisCase({
    required this.id,
    required this.farmerId,
    required this.farmId,
    required this.symptoms,
    required this.status,
    required this.photoPath,
    this.expertDiagnosis,
    this.expertAdvice,
    this.createdAt,
  });

  factory DiagnosisCase.fromJson(Map<String, dynamic> json) {
    return DiagnosisCase(
      id: json['id'].toString(),
      farmerId: json['farmer_id']?.toString() ?? '',
      farmId: json['farm_id']?.toString() ?? '',
      symptoms: json['symptoms'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_review',
      photoPath: json['photo_path'] as String? ?? '',
      expertDiagnosis: json['expert_diagnosis'] as String?,
      expertAdvice: json['expert_advice'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

class DiagnosisApiService {
  DiagnosisApiService() : _dio = ApiClient(TokenStorage.instance).dio;

  final Dio _dio;

  Future<DiagnosisCase> submit({
    required String farmId,
    required String symptoms,
    required XFile photo,
  }) async {
    final bytes = await photo.readAsBytes();

    final form = FormData.fromMap({
      'farm_id': farmId,
      'symptoms': symptoms,
      'photo': MultipartFile.fromBytes(
        bytes,
        filename: photo.name.isEmpty ? 'crop_photo.jpg' : photo.name,
      ),
    });

    final response = await _dio.post(
      '/diagnoses',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    return DiagnosisCase.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<DiagnosisCase>> getMyCases() async {
    final response = await _dio.get('/diagnoses/mine');
    return _parseCases(response.data);
  }

  Future<List<DiagnosisCase>> getQueue() async {
    final response = await _dio.get('/diagnoses/queue');
    return _parseCases(response.data);
  }

  List<DiagnosisCase> _parseCases(dynamic data) {
    return (data as List)
        .map((item) => DiagnosisCase.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList();
  }

  Future<DiagnosisCase> review({
    required String caseId,
    required bool validated,
    required String diagnosis,
    required String advice,
  }) async {
    final response = await _dio.post(
      '/diagnoses/$caseId/review',
      data: {
        'status': validated ? 'validated' : 'rejected',
        'expert_diagnosis': diagnosis,
        'expert_advice': advice,
      },
    );

    return DiagnosisCase.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}