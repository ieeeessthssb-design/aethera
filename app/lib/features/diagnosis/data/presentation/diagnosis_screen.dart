import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../farmer/presentation/farm_api_service.dart';
import '../diagnosis_api_service.dart';

const _forest = Color(0xFF183F32);
const _ink = Color(0xFF24352C);
const _green = Color(0xFF527B58);
const _cream = Color(0xFFF7F6EF);

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _farmApi = FarmApiService();
  final _diagnosisApi = DiagnosisApiService();
  final _picker = ImagePicker();
  final _symptomsController = TextEditingController();

  List<Farm> _farms = [];
  List<DiagnosisCase> _cases = [];
  String? _farmId;
  XFile? _photo;
  Uint8List? _photoBytes;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _farmApi.getMyFarms(),
        _diagnosisApi.getMyCases(),
      ]);

      if (!mounted) return;

      setState(() {
        _farms = results[0] as List<Farm>;
        _cases = results[1] as List<DiagnosisCase>;
        _farmId ??= _farms.isNotEmpty ? _farms.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.diagnosisLoadError;
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final selected = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (selected == null) return;

      final bytes = await selected.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photo = selected;
        _photoBytes = bytes;
      });
    } catch (e) {
      _showMessage(AppLocalizations.of(context)!.diagnosisPhotoError);
    }
  }

  Future<void> _submit() async {
    final symptoms = _symptomsController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (_farmId == null) {
      _showMessage(l10n.diagnosisAddFarm);
      return;
    }
    if (_photo == null) {
      _showMessage(l10n.diagnosisSelectPhoto);
      return;
    }
    if (symptoms.length < 5) {
      _showMessage(l10n.diagnosisDescribeSymptoms);
      return;
    }

    setState(() => _submitting = true);

    try {
      final created = await _diagnosisApi.submit(
        farmId: _farmId!,
        symptoms: symptoms,
        photo: _photo!,
      );

      if (!mounted) return;

      setState(() {
        _cases.insert(0, created);
        _photo = null;
        _photoBytes = null;
        _symptomsController.clear();
        _submitting = false;
      });

      _showMessage(l10n.diagnosisCaseSubmitted);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(l10n.diagnosisSubmissionFailed(_errorMessage(e)));
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      return AppLocalizations.of(context)!.diagnosisServerError(
        error.response?.statusCode?.toString() ?? 'connection',
      );
    }
    return error.toString();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending_review':
        return l10n.diagnosisPendingStatus;
      case 'validated':
        return l10n.diagnosisValidatedStatus;
      case 'rejected':
        return l10n.diagnosisRejectedStatus;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'validated':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _forest,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF59665C))),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm() {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle(l10n.diagnosisNew, l10n.diagnosisInstructions),
            DropdownButtonFormField<String>(
              initialValue: _farmId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.diagnosisSelectFarm,
                border: OutlineInputBorder(),
              ),
              items: _farms.map((farm) {
                return DropdownMenuItem(
                  value: farm.id,
                  child: Text(
                    '${farm.name} — ${farm.location}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _farmId = value),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _submitting ? null : _pickPhoto,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text(
                _photo == null
                    ? l10n.diagnosisChoosePhoto
                    : l10n.diagnosisChangePhoto,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _forest,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_photoBytes != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _photoBytes!,
                  height: 190,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _symptomsController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.diagnosisSymptoms,
                hintText: l10n.diagnosisSymptomExample,
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting || _farms.isEmpty ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting ? l10n.diagnosisSubmitting : l10n.diagnosisSubmit,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            if (_farms.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  l10n.diagnosisFarmRequired,
                  style: const TextStyle(color: Colors.deepOrange),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(DiagnosisCase item) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _statusLabel(item.status),
                    style: TextStyle(
                      color: _statusColor(item.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.eco_outlined, color: _green),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.symptoms, style: const TextStyle(color: _forest)),
            if (item.expertDiagnosis != null) ...[
              const Divider(height: 22),
              Text(
                l10n.diagnosisExpertDiagnosis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 5),
              Text(item.expertDiagnosis!, style: const TextStyle(color: _ink)),
            ],
            if (item.expertAdvice != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.diagnosisExpertRecommendation,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _forest,
                ),
              ),
              const SizedBox(height: 5),
              Text(item.expertAdvice!, style: const TextStyle(color: _ink)),
            ],
            if (item.createdAt != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.diagnosisSubmittedAt(
                  item.createdAt!.toLocal().toString().substring(0, 16),
                ),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(l10n.diagnosisTitle),
        backgroundColor: _forest,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.diagnosisRefresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _forest))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadData,
                      child: Text(l10n.diagnosisRetry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSubmissionForm(),
                  const SizedBox(height: 24),
                  _sectionTitle(
                    l10n.diagnosisMyCases,
                    l10n.diagnosisCasesDescription,
                  ),
                  if (_cases.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 25),
                      child: Center(
                        child: Text(
                          l10n.diagnosisNoCases,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._cases.map(_buildCaseCard),
                ],
              ),
            ),
    );
  }
}
