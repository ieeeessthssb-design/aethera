// Page expert « Validation des diagnostics IA » : ton interface d'origine
// (projet expert_validation), intégrée dans Aethera.
//
// Ajouts par rapport à ton fichier d'origine (l'interface ne change pas) :
//  - le cas envoyé par l'agriculteur depuis Aethera apparaît dans la liste
//    (il vient de DemoStore.submission) ;
//  - détails du cas : photo reçue, note écrite/dictée (traduite en français
//    si elle est en arabe), infos de la ferme, actions précédentes ;
//  - la décision de l'expert (confirmer / rejeter) revient à l'agriculteur.
import 'package:flutter/material.dart';

import '../core/case_service.dart';
import '../core/diagnosis_case.dart';
import '../core/scope.dart';
import '../core/translate_service.dart';

// ============================================================
// COULEURS (même palette que l'assistant vocal)
// ============================================================
const Color kGreen = Color(0xFF1B5E20);
const Color kGreenMid = Color(0xFF2E7D32);
const Color kGreenSoft = Color(0xFFC8E6C9);
const Color kBackground = Color(0xFFF2F5F2);
const Color kOrange = Color(0xFFEF6C00);
const Color kRed = Color(0xFFD32F2F);

Color confidenceColor(double score) {
  if (score > 0.8) return kGreenMid;
  if (score >= 0.5) return kOrange;
  return kRed;
}

IconData cropIcon(String crop) {
  switch (crop.toLowerCase()) {
    case 'olivier':
      return Icons.park;
    case 'blé':
      return Icons.grass;
    case 'agrumes':
      return Icons.spa;
    default:
      return Icons.eco;
  }
}

// ============================================================
// MENU DE L'EXPERT (seul le premier onglet est actif)
// ============================================================
class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const List<_NavItem> _navItems = [
  _NavItem('Validation des cas', Icons.fact_check),
  _NavItem('Posts communautaires', Icons.forum_outlined),
  _NavItem('Connaissances', Icons.menu_book_outlined),
  _NavItem('Consultations', Icons.support_agent),
  _NavItem('Alertes de risque', Icons.warning_amber_outlined),
];

class ExpertCasesPage extends StatefulWidget {
  const ExpertCasesPage({super.key});

  @override
  State<ExpertCasesPage> createState() => _ExpertCasesPageState();
}

class _ExpertCasesPageState extends State<ExpertCasesPage> {
  final CaseService _service = CaseService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<DiagnosisCase> _cases = []; // cas d'exemple (CaseService)

  /// Le cas envoyé par l'agriculteur depuis Aide rapide / Diagnostic.
  static const String _liveId = 'CAS-2048';

  DiagnosisCase? _live(DemoStore d) {
    final sub = d.submission;
    if (sub == null || d.caseStatus == CaseStatus.none) return null;
    final decided = d.caseStatus == CaseStatus.responded ||
        d.caseStatus == CaseStatus.resolved;
    final status = !decided
        ? ValidationStatus.pending
        : (d.expertDecision == 'rejected'
            ? ValidationStatus.rejected
            : ValidationStatus.confirmed);
    return DiagnosisCase(
      id: _liveId,
      crop: sub.crop,
      farmerName: 'Amine Ben Salem',
      aiPrediction: sub.aiPrediction,
      confidenceScore: sub.aiConfidence,
      aiRecommendation: sub.aiRecommendation,
      aiAnalysis: sub.aiAnalysis,
      farmerNotes: sub.note,
      location: 'Sousse',
      status: status,
      expertFeedback: decided ? d.expertVerdict : null,
      createdAt: sub.createdAt,
      photo: sub.photo,
      photoName: sub.photoName,
      inputMode: sub.spoken ? InputMode.voice : InputMode.typed,
      previousActions: sub.actions,
      farmContext: sub.farmContext,
      isFromFarmer: true,
    );
  }

  /// Cas de l'agriculteur (en premier) + cas d'exemple.
  List<DiagnosisCase> get _all {
    final live = _live(context.demo);
    return [if (live != null) live, ..._cases];
  }

  /// Décision de l'expert sur le cas de l'agriculteur : elle lui revient
  /// via DemoStore (écran « Expert consultation » côté agriculteur).
  Future<DiagnosisCase> _decideLive(
      DiagnosisCase c, bool confirm, String text) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final plan = confirm
        ? c.aiRecommendation
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
if (!mounted) {
  return c.copyWith(
    status: confirm ? ValidationStatus.confirmed : ValidationStatus.rejected,
    expertFeedback: text,
  );
}    context.demo.set(
      caseStatus: CaseStatus.resolved,
      expertDecision: confirm ? 'confirmed' : 'rejected',
      expertVerdict:
          text.isNotEmpty ? text : 'Diagnostic confirmé : ${c.aiPrediction}',
      expertPlan: plan,
    );
    return c.copyWith(
      status: confirm ? ValidationStatus.confirmed : ValidationStatus.rejected,
      expertFeedback: text,
    );
  }
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  String _search = '';
  ValidationStatus? _statusFilter; // null = Tous
  ConfidenceLevel? _confidenceFilter; // null = Tous
  String? _selectedId; // cas affiché dans le panneau de détails

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // DONNÉES
  // ============================================================

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchCases();
      if (!mounted) return;
      setState(() {
        _cases = List.of(list);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Impossible de charger les cas. Vérifiez votre connexion.';
      });
    }
  }

  DiagnosisCase? get _selected {
    final id = _selectedId;
    if (id == null) return null;
    for (final c in _all) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<DiagnosisCase> get _filtered {
    final q = _search.trim().toLowerCase();
    return _all.where((c) {
      if (_statusFilter != null && c.status != _statusFilter) return false;
      if (_confidenceFilter != null && c.confidenceLevel != _confidenceFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return c.id.toLowerCase().contains(q) ||
          c.crop.toLowerCase().contains(q) ||
          c.farmerName.toLowerCase().contains(q) ||
          c.aiPrediction.toLowerCase().contains(q);
    }).toList();
  }

  bool get _hasActiveFilters =>
      _search.trim().isNotEmpty ||
      _statusFilter != null ||
      _confidenceFilter != null;

  int _count(ValidationStatus status) =>
      _all.where((c) => c.status == status).length;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _search = '';
      _statusFilter = null;
      _confidenceFilter = null;
    });
  }

  // ============================================================
  // ACTIONS : détails, confirmer, rejeter
  // ============================================================

  void _openDetails(DiagnosisCase c) {
    // Quand l'expert ouvre le cas de l'agriculteur, son suivi passe à
    // « en cours de revue ».
    final demo = context.demo;
    if (c.isFromFarmer && demo.caseStatus == CaseStatus.submitted) {
      demo.set(caseStatus: CaseStatus.reviewing);
    }
    setState(() => _selectedId = c.id);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDetails() {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeEndDrawer();
    }
  }

  Future<void> _confirm(DiagnosisCase c) async {
    if (_isSubmitting) return;
    final note = await showDialog<String>(
      context: context,
      builder: (_) => _ConfirmDialog(item: c),
    );
    if (note == null || !mounted) return;
    await _submit(
      () => c.isFromFarmer
          ? _decideLive(c, true, note)
          : _service.confirmCase(c.id, note: note.isEmpty ? null : note),
      'Cas ${c.id} confirmé',
    );
  }

  Future<void> _reject(DiagnosisCase c) async {
    if (_isSubmitting) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(item: c),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
    await _submit(
      () => c.isFromFarmer
          ? _decideLive(c, false, reason)
          : _service.rejectCase(c.id, reason),
      'Cas ${c.id} rejeté',
    );
  }

  Future<void> _submit(
    Future<DiagnosisCase> Function() action,
    String successMessage,
  ) async {
    setState(() => _isSubmitting = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _cases = [for (final c in _cases) c.id == updated.id ? updated : c];
        _isSubmitting = false;
      });
      _closeDetails();
      _snack(successMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _snack('Une erreur est survenue. Réessayez.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // AFFICHAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final detailsWidth = width < 460 ? width * 0.92 : 440.0;

    return Directionality(
      textDirection: TextDirection.ltr, // page expert en français
      child: Theme(
        data: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kGreen),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        child: ListenableBuilder(
          listenable: context.demo,
          builder: (context, _) => _buildScaffold(isWide, width, detailsWidth),
        ),
      ),
    );
  }

  Widget _buildScaffold(bool isWide, double width, double detailsWidth) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackground,
      drawer: isWide ? null : _buildNavDrawer(),
      endDrawer: Drawer(
        width: detailsWidth,
        backgroundColor: Colors.white,
        child: _buildDetailsPanel(),
      ),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) ...[
              _buildRail(extended: width >= 1150),
              Container(width: 1, color: Colors.grey.shade300),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      _buildHeader(isWide, width),
                      Expanded(child: _buildBody()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Navigation ----------

  Widget _buildRail({required bool extended}) {
    return NavigationRail(
      backgroundColor: Colors.white,
      selectedIndex: 0,
      extended: extended,
      labelType:
          extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      indicatorColor: kGreenSoft,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Icon(Icons.eco, color: kGreen, size: 32),
      ),
      destinations: [
        for (var i = 0; i < _navItems.length; i++)
          NavigationRailDestination(
            icon: Icon(_navItems[i].icon),
            label: Text(_navItems[i].label),
            disabled: i != 0,
          ),
      ],
      onDestinationSelected: (_) {},
    );
  }

  Widget _buildNavDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.eco, color: kGreen, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Espace Expert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _navItems.length; i++)
              ListTile(
                leading: Icon(_navItems[i].icon),
                title: Text(_navItems[i].label),
                enabled: i == 0,
                selected: i == 0,
                selectedColor: kGreen,
                selectedTileColor: kGreenSoft,
                onTap: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- En-tête vert ----------

  Widget _buildHeader(bool isWide, double width) {
    final pending = _count(ValidationStatus.pending);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isWide)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Menu',
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Validation des diagnostics IA',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.amberAccent, size: 10),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Liste des cas • $pending en attente',
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (width >= 600)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white38),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Expert agricole',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------- Corps de la page ----------

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kGreen));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: kGreen),
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCounters(),
          const SizedBox(height: 16),
          _buildFilters(),
          const SizedBox(height: 16),
          _buildCaseList(),
        ],
      ),
    );
  }

  /// Grille adaptative : le nombre de colonnes dépend de la largeur.
  Widget _adaptiveGrid({
    required List<Widget> children,
    required double minItemWidth,
    double gap = 12,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final maxColumns = children.isEmpty ? 1 : children.length;
        final columns = ((available + gap) / (minItemWidth + gap))
            .floor()
            .clamp(1, maxColumns)
            .toInt();
        final itemWidth = (available - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }

  // ---------- Compteurs ----------

  Widget _buildCounters() {
    return _adaptiveGrid(
      minItemWidth: 150,
      children: [
        _CounterCard(
          label: 'Total',
          value: _all.length,
          icon: Icons.folder_open,
          color: Colors.blue.shade700,
          bg: const Color(0xFFF5F9FF),
          border: const Color(0xFFBBDEFB),
        ),
        _CounterCard(
          label: 'En attente',
          value: _count(ValidationStatus.pending),
          icon: Icons.hourglass_top,
          color: const Color(0xFFB26A00),
          bg: const Color(0xFFFFFDE7),
          border: const Color(0xFFFFE0B2),
        ),
        _CounterCard(
          label: 'Confirmés',
          value: _count(ValidationStatus.confirmed),
          icon: Icons.check_circle_outline,
          color: kGreenMid,
          bg: const Color(0xFFF1F8F1),
          border: kGreenSoft,
        ),
        _CounterCard(
          label: 'Rejetés',
          value: _count(ValidationStatus.rejected),
          icon: Icons.cancel_outlined,
          color: kRed,
          bg: const Color(0xFFFFF5F5),
          border: const Color(0xFFFFCDD2),
        ),
      ],
    );
  }

  // ---------- Filtres ----------

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FILTRES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D6E63),
                  letterSpacing: 0.5,
                ),
              ),
              TextButton.icon(
                onPressed: _hasActiveFilters ? _resetFilters : null,
                icon: Icon(
                  Icons.refresh,
                  size: 16,
                  color: _hasActiveFilters ? kRed : Colors.grey,
                ),
                label: Text(
                  'Réinitialiser les filtres',
                  style: TextStyle(
                    color: _hasActiveFilters ? kRed : Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFFECB3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher : culture, agriculteur, diagnostic ou ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close),
                      tooltip: 'Effacer',
                    ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _filterLabel('Statut'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Tous', _statusFilter == null,
                  () => setState(() => _statusFilter = null)),
              for (final s in ValidationStatus.values)
                _chip(s.label, _statusFilter == s,
                    () => setState(() => _statusFilter = s)),
            ],
          ),
          const SizedBox(height: 14),
          _filterLabel("Confiance de l'IA"),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Tous', _confidenceFilter == null,
                  () => setState(() => _confidenceFilter = null)),
              for (final level in ConfidenceLevel.values)
                _chip(level.label, _confidenceFilter == level,
                    () => setState(() => _confidenceFilter = level)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6D4C41),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: kGreenSoft,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? kGreen : const Color(0xFF444444),
      ),
      side: BorderSide(color: selected ? kGreen : Colors.grey.shade300),
    );
  }

  // ---------- Liste des cas ----------

  Widget _buildCaseList() {
    final items = _filtered;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 40, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            const Text('Aucun cas ne correspond aux filtres.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            '${items.length} cas',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6D4C41),
            ),
          ),
        ),
        _adaptiveGrid(
          minItemWidth: 340,
          children: [
            for (final c in items)
              _CaseCard(
                item: c,
                isSubmitting: _isSubmitting,
                onOpen: () => _openDetails(c),
                onConfirm: () => _confirm(c),
                onReject: () => _reject(c),
              ),
          ],
        ),
      ],
    );
  }

  // ---------- Panneau de détails (à droite) ----------

  Widget _buildDetailsPanel() {
    final c = _selected;
    if (c == null) return const SizedBox.shrink();
    return _CaseDetails(
      item: c,
      isSubmitting: _isSubmitting,
      onClose: _closeDetails,
      onConfirm: () => _confirm(c),
      onReject: () => _reject(c),
    );
  }
}

// ============================================================
// WIDGETS RÉUTILISABLES
// ============================================================

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final ValidationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, icon) = switch (status) {
      ValidationStatus.pending => (
          const Color(0xFFFFF8E1),
          const Color(0xFFB26A00),
          const Color(0xFFFFD54F),
          Icons.hourglass_top,
        ),
      ValidationStatus.confirmed => (
          const Color(0xFFE8F5E9),
          kGreen,
          kGreenSoft,
          Icons.check_circle,
        ),
      ValidationStatus.rejected => (
          const Color(0xFFFFEBEE),
          const Color(0xFFC62828),
          const Color(0xFFFFCDD2),
          Icons.cancel,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar(this.score);

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = confidenceColor(score);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Miniature de la plante : photo de l'agriculteur si reçue, sinon photo
/// (URL), sinon icône stylisée.
class _CropThumb extends StatelessWidget {
  const _CropThumb({
    required this.crop,
    this.imageUrl,
    this.photo,
    this.size = 56,
    this.radius = 12,
  });

  final String crop;
  final String? imageUrl;
  final ImageProvider? photo;
  final double size;
  final double radius;

  Widget _fallback() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Icon(cropIcon(crop), size: size * 0.5, color: kGreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final Widget child = photo != null
        ? Image(
            image: photo!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          )
        : (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : _fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: child),
    );
  }
}

/// Bloc coloré titre + texte (même style que les cartes de l'assistant vocal).
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.content,
    required this.borderColor,
    required this.bgColor,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String content;
  final Color borderColor;
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content.isEmpty ? '—' : content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons Rejeter / Confirmer (actifs seulement pour un cas en attente).
class _DecisionButtons extends StatelessWidget {
  const _DecisionButtons({
    required this.isSubmitting,
    required this.onConfirm,
    required this.onReject,
  });

  final bool isSubmitting;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isSubmitting ? null : onReject,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rejeter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kRed,
              side: BorderSide(
                color: isSubmitting ? Colors.grey.shade300 : kRed,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : onConfirm,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Text('Confirmer'),
            style: FilledButton.styleFrom(backgroundColor: kGreenMid),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CARTE D'UN CAS (liste)
// ============================================================
class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.isSubmitting,
    required this.onOpen,
    required this.onConfirm,
    required this.onReject,
  });

  final DiagnosisCase item;
  final bool isSubmitting;
  final VoidCallback onOpen;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID, date et statut
              Row(
                children: [
                  Text(
                    item.id,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatDate(item.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  _StatusBadge(item.status),
                ],
              ),
              const SizedBox(height: 12),

              // Miniature + culture + agriculteur + région
              Row(
                children: [
                  _CropThumb(
                      crop: item.crop,
                      imageUrl: item.imageUrl,
                      photo: item.photo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.crop,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _IconLine(Icons.person_outline, item.farmerName),
                        const SizedBox(height: 2),
                        _IconLine(Icons.place_outlined, item.location),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Diagnostic IA + confiance
              const Text(
                'DIAGNOSTIC IA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8D6E63),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.aiPrediction,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _ConfidenceBar(item.confidenceScore),

              // Actions rapides (cas en attente uniquement)
              if (item.status == ValidationStatus.pending) ...[
                const SizedBox(height: 14),
                _DecisionButtons(
                  isSubmitting: isSubmitting,
                  onConfirm: onConfirm,
                  onReject: onReject,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PANNEAU DE DÉTAILS (à droite)
// ============================================================
class _CaseDetails extends StatelessWidget {
  const _CaseDetails({
    required this.item,
    required this.isSubmitting,
    required this.onClose,
    required this.onConfirm,
    required this.onReject,
  });

  final DiagnosisCase item;
  final bool isSubmitting;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Détails du cas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: 'Fermer',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image agrandie
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: LayoutBuilder(
                      builder: (context, constraints) => _CropThumb(
                        crop: item.crop,
                        imageUrl: item.imageUrl,
                        photo: item.photo,
                        size: constraints.maxWidth,
                        radius: 16,
                      ),
                    ),
                  ),
                  if (item.photo != null || item.photoName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.photo_camera_outlined,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.photoName != null
                                ? "Photo envoyée par l'agriculteur · ${item.photoName}"
                                : "Photo envoyée par l'agriculteur",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        item.id,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDate(item.createdAt),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      _StatusBadge(item.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.crop,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _IconLine(Icons.person_outline, item.farmerName),
                  const SizedBox(height: 2),
                  _IconLine(Icons.place_outlined, item.location),
                  const SizedBox(height: 16),

                  // Note de l'agriculteur : telle qu'il l'a écrite ou dictée
                  // (traduite en français si elle est en arabe).
                  _FarmerNoteBlock(item: item),
                  const SizedBox(height: 12),

                  if (item.farmContext.isNotEmpty) ...[
                    _InfoBlock(
                      title: 'INFORMATIONS SUR LA FERME',
                      content: item.farmContext,
                      borderColor: const Color(0xFFD7CCC8),
                      bgColor: const Color(0xFFFBF7F4),
                      icon: Icons.agriculture_outlined,
                      iconColor: const Color(0xFF6D4C41),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (item.previousActions.isNotEmpty) ...[
                    _ActionsBlock(actions: item.previousActions),
                    const SizedBox(height: 12),
                  ],

                  // Analyse de l'IA + score
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD1C4E9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.search,
                                size: 16, color: Colors.deepPurple),
                            SizedBox(width: 6),
                            Text(
                              "ANALYSE DE L'IA",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.aiPrediction,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _ConfidenceBar(item.confidenceScore),
                        if (item.aiAnalysis.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            item.aiAnalysis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _InfoBlock(
                    title: "RECOMMANDATIONS DE L'IA",
                    content: item.aiRecommendation,
                    borderColor: kGreenSoft,
                    bgColor: const Color(0xFFF1F8F1),
                    icon: Icons.check_circle_outline,
                    iconColor: kGreenMid,
                  ),

                  if (item.expertFeedback != null &&
                      item.expertFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoBlock(
                      title: item.status == ValidationStatus.rejected
                          ? 'MOTIF DU REJET / CORRECTION'
                          : "NOTE DE L'EXPERT",
                      content: item.expertFeedback!,
                      borderColor: item.status == ValidationStatus.rejected
                          ? const Color(0xFFFFCDD2)
                          : const Color(0xFFBBDEFB),
                      bgColor: item.status == ValidationStatus.rejected
                          ? const Color(0xFFFFF5F5)
                          : const Color(0xFFF5F9FF),
                      icon: Icons.rate_review_outlined,
                      iconColor: item.status == ValidationStatus.rejected
                          ? kRed
                          : Colors.blue.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (item.status == ValidationStatus.pending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _DecisionButtons(
                isSubmitting: isSubmitting,
                onConfirm: onConfirm,
                onReject: onReject,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// NOTE DE L'AGRICULTEUR (écrite ou dictée, traduite si arabe)
// ============================================================
class _FarmerNoteBlock extends StatefulWidget {
  const _FarmerNoteBlock({required this.item});

  final DiagnosisCase item;

  @override
  State<_FarmerNoteBlock> createState() => _FarmerNoteBlockState();
}

class _FarmerNoteBlockState extends State<_FarmerNoteBlock> {
  String? _french; // traduction
  bool _loading = false;
  bool _failed = false;
  bool _showOriginal = false;

  bool get _isArabic => TranslateService.hasArabic(widget.item.farmerNotes);

  @override
  void initState() {
    super.initState();
    _translate();
  }

  @override
  void didUpdateWidget(covariant _FarmerNoteBlock old) {
    super.didUpdateWidget(old);
    if (old.item.farmerNotes != widget.item.farmerNotes) {
      _french = null;
      _failed = false;
      _translate();
    }
  }

  Future<void> _translate() async {
    if (!_isArabic) return;
    final note = widget.item.farmerNotes;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final fr = await TranslateService.arabicToFrench(note);
      if (!mounted || note != widget.item.farmerNotes) return;
      setState(() {
        _french = fr;
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

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFB26A00);
    final note = widget.item.farmerNotes;

    Widget body;
    if (note.isEmpty) {
      body = const Text('—', style: TextStyle(fontSize: 14));
    } else if (!_isArabic) {
      body = Text(note,
          style: const TextStyle(
              fontSize: 14, height: 1.4, color: Color(0xFF333333)));
    } else if (_loading) {
      body = const Row(children: [
        SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: color)),
        SizedBox(width: 8),
        Text('Traduction en cours…',
            style: TextStyle(fontSize: 13, color: Color(0xFF777777))),
      ]);
    } else if (_french != null && !_showOriginal) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_french!,
              style: const TextStyle(
                  fontSize: 14, height: 1.4, color: Color(0xFF333333))),
          const SizedBox(height: 4),
          Text("Traduit automatiquement de l'arabe",
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600)),
        ],
      );
    } else {
      // original arabe (affiché si traduction indisponible ou demandé)
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: double.infinity,
              child: Text(note,
                  style: const TextStyle(
                      fontSize: 15, height: 1.5, color: Color(0xFF333333))),
            ),
          ),
          if (_failed) ...[
            const SizedBox(height: 6),
            Text(
                'Traduction automatique indisponible pour le moment. '
                'Texte original affiché.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 16, color: color),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  "NOTES DE L'AGRICULTEUR",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          body,
          if (_isArabic && _french != null) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _showOriginal = !_showOriginal),
              child: Text(
                _showOriginal ? 'Voir la traduction' : "Voir l'original (arabe)",
                style: const TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
          if (_isArabic && _failed) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: _translate,
              child: const Text('Réessayer la traduction',
                  style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ce que l'agriculteur a fait avant d'envoyer le cas.
class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF455A64);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFD8DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, size: 16, color: color),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  "ACTIONS PRÉCÉDENTES DE L'AGRICULTEUR",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 6, color: color),
                  ),
                  Expanded(
                    child: Text(a,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Color(0xFF333333))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// BOÎTES DE DIALOGUE : confirmer / rejeter
// ============================================================

/// Confirmation avec note optionnelle. Renvoie la note ('' si vide),
/// ou null si l'expert annule.
class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({required this.item});

  final DiagnosisCase item;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer le diagnostic'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.item.id} • ${widget.item.aiPrediction}'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Note de l'expert (optionnelle)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: kGreenMid),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

/// Rejet : le motif / la correction est obligatoire.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.item});

  final DiagnosisCase item;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _controller.text.trim();
    return AlertDialog(
      title: const Text('Rejeter le diagnostic'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.item.id} • ${widget.item.aiPrediction}'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet / diagnostic corrigé (obligatoire)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed:
              reason.isEmpty ? null : () => Navigator.of(context).pop(reason),
          style: FilledButton.styleFrom(backgroundColor: kRed),
          child: const Text('Rejeter'),
        ),
      ],
    );
  }
}
