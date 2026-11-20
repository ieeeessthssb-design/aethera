import 'package:flutter/painting.dart' show ImageProvider;

// ============================================================
// MODÈLE DE DONNÉES : un cas soumis à l'expert
// (renommé ValidationStatus : Aethera a déjà un enum CaseStatus
//  pour le parcours de l'agriculteur)
// ============================================================

/// Comment l'agriculteur a donné sa question / ses symptômes.
enum InputMode { unknown, typed, voice }

enum ValidationStatus { pending, confirmed, rejected }

/// Niveau de confiance de l'IA (pour le filtre).
enum ConfidenceLevel { high, medium, low }

extension ValidationStatusLabel on ValidationStatus {
  String get label => switch (this) {
        ValidationStatus.pending => 'En attente',
        ValidationStatus.confirmed => 'Confirmé',
        ValidationStatus.rejected => 'Rejeté',
      };

  /// Valeur échangée avec l'API : "pending", "confirmed" ou "rejected".
  String get apiValue => name;

  static ValidationStatus fromApi(String? value) => ValidationStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ValidationStatus.pending,
      );
}

extension ConfidenceLevelLabel on ConfidenceLevel {
  String get label => switch (this) {
        ConfidenceLevel.high => 'Élevée (> 80%)',
        ConfidenceLevel.medium => 'Moyenne (50% - 80%)',
        ConfidenceLevel.low => 'Faible (< 50%)',
      };
}

class DiagnosisCase {
  const DiagnosisCase({
    required this.id,
    required this.crop,
    required this.farmerName,
    this.imageUrl,
    required this.aiPrediction,
    required this.confidenceScore,
    required this.aiRecommendation,
    this.aiAnalysis = '',
    required this.farmerNotes,
    required this.location,
    required this.status,
    this.expertFeedback,
    required this.createdAt,
    this.photo,
    this.photoName,
    this.inputMode = InputMode.unknown,
    this.previousActions = const [],
    this.farmContext = '',
    this.isFromFarmer = false,
  });

  final String id;
  final String crop;
  final String farmerName;

  /// Photo de la feuille / plante (null = icône à la place).
  final String? imageUrl;

  /// Diagnostic initial généré par l'IA.
  final String aiPrediction;

  /// Score de confiance de l'IA, entre 0.0 et 1.0.
  final double confidenceScore;

  final String aiRecommendation;

  /// Analyse détaillée de l'IA (affichée dans le panneau de détails).
  final String aiAnalysis;

  final String farmerNotes;
  final String location;
  final ValidationStatus status;

  /// Note de l'expert (confirmation) ou motif / correction (rejet).
  final String? expertFeedback;

  final DateTime createdAt;

  /// Photo reçue de l'agriculteur dans Aethera (en mémoire). Prioritaire
  /// sur [imageUrl].
  final ImageProvider? photo;

  /// Nom du fichier envoyé par l'agriculteur.
  final String? photoName;

  /// Note écrite ou dictée.
  final InputMode inputMode;

  /// Ce que l'agriculteur a fait avant d'envoyer le cas.
  final List<String> previousActions;

  /// Contexte de la ferme (culture, surface, irrigation…).
  final String farmContext;

  /// true = cas envoyé depuis l'application par l'agriculteur.
  final bool isFromFarmer;

  bool get hasPhoto =>
      photo != null || (imageUrl != null && imageUrl!.isNotEmpty);

  int get confidencePercent => (confidenceScore * 100).round();

  ConfidenceLevel get confidenceLevel {
    if (confidenceScore > 0.8) return ConfidenceLevel.high;
    if (confidenceScore >= 0.5) return ConfidenceLevel.medium;
    return ConfidenceLevel.low;
  }

  DiagnosisCase copyWith({ValidationStatus? status, String? expertFeedback}) {
    return DiagnosisCase(
      id: id,
      crop: crop,
      farmerName: farmerName,
      imageUrl: imageUrl,
      aiPrediction: aiPrediction,
      confidenceScore: confidenceScore,
      aiRecommendation: aiRecommendation,
      aiAnalysis: aiAnalysis,
      farmerNotes: farmerNotes,
      location: location,
      status: status ?? this.status,
      expertFeedback: expertFeedback ?? this.expertFeedback,
      createdAt: createdAt,
      photo: photo,
      photoName: photoName,
      inputMode: inputMode,
      previousActions: previousActions,
      farmContext: farmContext,
      isFromFarmer: isFromFarmer,
    );
  }

  factory DiagnosisCase.fromJson(Map<String, dynamic> json) {
    final rawScore = (json['confidenceScore'] as num).toDouble();
    return DiagnosisCase(
      id: json['id'] as String,
      crop: json['crop'] as String,
      farmerName: json['farmerName'] as String,
      imageUrl: json['imageUrl'] as String?,
      aiPrediction: json['aiPrediction'] as String,
      // Accepte un score entre 0 et 1, ou un pourcentage entre 0 et 100.
      confidenceScore: rawScore > 1 ? rawScore / 100 : rawScore,
      aiRecommendation: json['aiRecommendation'] as String? ?? '',
      aiAnalysis: json['aiAnalysis'] as String? ?? '',
      farmerNotes: json['farmerNotes'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: ValidationStatusLabel.fromApi(json['status'] as String?),
      expertFeedback: json['expertFeedback'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      photoName: json['photoName'] as String?,
      inputMode: switch (json['inputMode']) {
        'voice' => InputMode.voice,
        'typed' => InputMode.typed,
        _ => InputMode.unknown,
      },
      previousActions: ((json['previousActions'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      farmContext: json['farmContext'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'crop': crop,
        'farmerName': farmerName,
        'imageUrl': imageUrl,
        'aiPrediction': aiPrediction,
        'confidenceScore': confidenceScore,
        'aiRecommendation': aiRecommendation,
        'aiAnalysis': aiAnalysis,
        'farmerNotes': farmerNotes,
        'location': location,
        'status': status.apiValue,
        'expertFeedback': expertFeedback,
        'createdAt': createdAt.toIso8601String(),
        'photoName': photoName,
        'inputMode': inputMode.name,
        'previousActions': previousActions,
        'farmContext': farmContext,
      };
}

/// Date au format jj/mm/aaaa.
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
