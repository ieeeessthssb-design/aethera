import 'diagnosis_case.dart';

class CaseServiceException implements Exception {
  const CaseServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

// ============================================================
// SERVICE : seul endroit à modifier pour brancher l'API réelle
//
// Pour l'instant : 8 cas fictifs en mémoire + Future.delayed
// pour simuler le réseau.
//
// Pour brancher le backend, remplace le corps de chaque méthode
// par un appel http / dio, par exemple :
//   fetchCases()   -> GET  /api/cases
//   confirmCase()  -> POST /api/cases/{id}/confirm   {"note": "..."}
//   rejectCase()   -> POST /api/cases/{id}/reject    {"reason": "..."}
// et transforme la réponse avec DiagnosisCase.fromJson(...).
// ============================================================
class CaseService {
  CaseService() : _cases = _buildSampleCases();

  final List<DiagnosisCase> _cases;

  /// Liste des cas soumis à l'expert.
  Future<List<DiagnosisCase>> fetchCases() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return List.of(_cases);
  }

  /// L'expert confirme le diagnostic de l'IA (note optionnelle).
  Future<DiagnosisCase> confirmCase(String id, {String? note}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _update(id, ValidationStatus.confirmed, note);
  }

  /// L'expert rejette le diagnostic : le motif / la correction est obligatoire.
  Future<DiagnosisCase> rejectCase(String id, String reason) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return _update(id, ValidationStatus.rejected, reason);
  }

  DiagnosisCase _update(String id, ValidationStatus status, String? feedback) {
    final index = _cases.indexWhere((c) => c.id == id);
    if (index == -1) throw const CaseServiceException('Cas introuvable.');
    final updated = _cases[index].copyWith(
      status: status,
      expertFeedback: feedback,
    );
    _cases[index] = updated;
    return updated;
  }

  // ----------------------------------------------------------
  // Données fictives (à supprimer quand l'API sera branchée).
  // Le cas envoyé par l'agriculteur dans Aethera n'est PAS ici : il
  // vient de DemoStore.submission (voir expert_cases.dart).
  // ----------------------------------------------------------
  static List<DiagnosisCase> _buildSampleCases() {
    return [
      DiagnosisCase(
        id: 'CAS-1001',
        crop: 'Tomate',
        farmerName: 'Ahmed Ben Salah',
        aiPrediction: 'Mildiou de la tomate',
        confidenceScore: 0.91,
        aiAnalysis:
            "Taches brunes à bordure huileuse sur les feuilles basses et début de duvet blanc au revers. L'humidité nocturne élevée favorise cette maladie.",
        aiRecommendation:
            "Retirer les feuilles atteintes, aérer la culture, éviter de mouiller le feuillage et appliquer un traitement préventif à base de cuivre.",
        farmerNotes:
            "Les feuilles du bas jaunissent et des taches brunes apparaissent depuis 3 jours, après plusieurs nuits humides.",
        location: 'Nabeul',
        farmContext: 'Tomate · 1,2 ha · Goutte-à-goutte',
        inputMode: InputMode.typed,
        previousActions: [
          'Aide rapide : question posée',
          'Irrigation du soir maintenue depuis 1 semaine',
          'Aucun traitement appliqué',
        ],
        status: ValidationStatus.pending,
        createdAt: DateTime(2026, 11, 14, 8, 40),
      ),
      DiagnosisCase(
        id: 'CAS-1002',
        crop: 'Olivier',
        farmerName: 'Mounir Trabelsi',
        aiPrediction: 'Œil de paon sur olivier',
        confidenceScore: 0.67,
        aiAnalysis:
            "Taches circulaires sombres avec halo jaunâtre sur la face supérieure des feuilles. Confusion possible avec une carence ou un stress hydrique.",
        aiRecommendation:
            "Tailler pour aérer la ramure, ramasser les feuilles tombées et traiter au cuivre en période de pluie.",
        farmerNotes:
            "Des taches rondes sombres sur les feuilles, et certaines tombent au sol.",
        location: 'Sfax',
        farmContext: 'Olivier · 6 ha · Pluvial',
        inputMode: InputMode.voice,
        previousActions: [
          'Diagnostic : symptômes décrits',
          'Taille légère en octobre',
        ],
        status: ValidationStatus.pending,
        createdAt: DateTime(2026, 11, 13, 16, 15),
      ),
      DiagnosisCase(
        id: 'CAS-1003',
        crop: 'Blé',
        farmerName: 'Salma Gharbi',
        aiPrediction: 'Rouille jaune',
        confidenceScore: 0.88,
        aiAnalysis:
            "Pustules jaunes alignées en stries le long des nervures, typiques de la rouille jaune par temps frais et humide.",
        aiRecommendation:
            "Traiter rapidement avec un fongicide homologué et surveiller les parcelles voisines.",
        farmerNotes: "Des stries jaunes sur les feuilles, la poudre jaune colle aux doigts.",
        location: 'Béja',
        status: ValidationStatus.confirmed,
        expertFeedback:
            "Diagnostic correct. Traiter dès l'apparition des pustules.",
        createdAt: DateTime(2026, 11, 10, 11, 5),
      ),
      DiagnosisCase(
        id: 'CAS-1004',
        crop: 'Agrumes',
        farmerName: 'Karim Jlassi',
        aiPrediction: 'Carence en azote',
        confidenceScore: 0.42,
        aiAnalysis:
            "Jaunissement général des feuilles âgées, sans taches nettes. Le diagnostic est incertain : une asphyxie racinaire donne des signes proches.",
        aiRecommendation:
            "Faire une analyse foliaire puis apporter une fumure azotée adaptée.",
        farmerNotes:
            "Les feuilles de mes orangers pâlissent depuis le début de l'automne.",
        location: 'Cap Bon',
        status: ValidationStatus.pending,
        createdAt: DateTime(2026, 11, 12, 9, 30),
      ),
      DiagnosisCase(
        id: 'CAS-1005',
        crop: 'Tomate',
        farmerName: 'Ines Mansouri',
        aiPrediction: 'Alternariose',
        confidenceScore: 0.74,
        aiAnalysis:
            "Zone sombre et enfoncée à l'extrémité des fruits. L'IA a proposé une alternariose.",
        aiRecommendation:
            "Éliminer les fruits atteints et appliquer un fongicide adapté.",
        farmerNotes: "Le bas de mes tomates devient noir et mou.",
        location: 'Bizerte',
        status: ValidationStatus.rejected,
        expertFeedback:
            "Il s'agit plutôt d'une carence en calcium (nécrose apicale). Régulariser l'arrosage.",
        createdAt: DateTime(2026, 11, 9, 14, 20),
      ),
      DiagnosisCase(
        id: 'CAS-1006',
        crop: 'Poivron',
        farmerName: 'Hichem Dridi',
        aiPrediction: 'Oïdium du poivron',
        confidenceScore: 0.93,
        aiAnalysis:
            "Feutrage blanc poudreux sur la face inférieure des feuilles, avec jaunissement de la face supérieure.",
        aiRecommendation:
            "Traiter au soufre mouillable, aérer les serres et limiter l'excès d'azote.",
        farmerNotes: "Une poudre blanche sous les feuilles de mes poivrons sous serre.",
        location: 'Kairouan',
        status: ValidationStatus.confirmed,
        createdAt: DateTime(2026, 11, 8, 10, 0),
      ),
      DiagnosisCase(
        id: 'CAS-1007',
        crop: 'Olivier',
        farmerName: 'Rached Ouni',
        aiPrediction: "Teigne de l'olivier",
        confidenceScore: 0.58,
        aiAnalysis:
            "Olives avec petits trous et chute prématurée. Les signes peuvent aussi correspondre à d'autres ravageurs.",
        aiRecommendation:
            "Installer des pièges et surveiller les vols avant tout traitement.",
        farmerNotes: "Des petits trous sur les olives et beaucoup tombent avant maturité.",
        location: 'Sousse',
        status: ValidationStatus.rejected,
        expertFeedback:
            "Les piqûres évoquent la mouche de l'olivier. Poser des pièges à phéromone.",
        createdAt: DateTime(2026, 11, 7, 17, 45),
      ),
      DiagnosisCase(
        id: 'CAS-1008',
        crop: 'Blé',
        farmerName: 'Amel Chaouch',
        aiPrediction: 'Septoriose du blé',
        confidenceScore: 0.82,
        aiAnalysis:
            "Taches allongées brun clair avec petits points noirs, qui montent des feuilles basses vers les feuilles hautes.",
        aiRecommendation:
            "Traiter au stade dernière feuille et prévoir une rotation des cultures.",
        farmerNotes:
            "Des taches brunes sur les feuilles du bas qui montent peu à peu.",
        location: 'Jendouba',
        status: ValidationStatus.pending,
        createdAt: DateTime(2026, 11, 15, 7, 55),
      ),
    ];
  }
}
