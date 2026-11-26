import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/network/api_config.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../diagnosis/data/diagnosis_api_service.dart';

class DiagnosisQueueScreen extends StatefulWidget {
  const DiagnosisQueueScreen({super.key});

  @override
  State<DiagnosisQueueScreen> createState() => _DiagnosisQueueScreenState();
}

class _DiagnosisQueueScreenState extends State<DiagnosisQueueScreen> {
  final DiagnosisApiService _api = DiagnosisApiService();

  List<DiagnosisCase> _cases = [];
  bool _loading = true;
  bool _reviewing = false;
  String? _error;

  static const forest = Color(0xFF183F32);
  static const ink = Color(0xFF24352C);
  static const muted = Color(0xFF59665C);
  static const cream = Color(0xFFF7F6EF);
  static const green = Color(0xFF527B58);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cases = await _api.getQueue();

      if (!mounted) return;

      setState(() {
        _cases = cases;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyError(error);
        _loading = false;
      });
    }
  }

  Future<void> _review(DiagnosisCase item) async {
    if (_reviewing || !mounted) return;

    // The dialog owns its controllers. They are disposed by the dialog
    // only after its route has finished closing.
    final result = await showDialog<_ReviewResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DiagnosisReviewDialog(item: item),
    );

    if (result == null || !mounted) return;

    setState(() => _reviewing = true);

    try {
      await _api.review(
        caseId: item.id,
        validated: result.validated,
        diagnosis: result.diagnosis,
        advice: result.advice,
      );

      if (!mounted) return;

      _message(
        result.validated
            ? 'Diagnosis validated successfully.'
            : 'Case rejected and feedback saved.',
      );

      await _load();
    } catch (error) {
      if (mounted) {
        _message('Review failed: ${_friendlyError(error)}');
      }
    } finally {
      if (mounted) {
        setState(() => _reviewing = false);
      }
    }
  }

  String _imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return Uri.parse(ApiConfig.baseUrl).resolve(path).toString();
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }

      if (error.response?.statusCode == 401) {
        return 'Your session has expired. Please sign in again.';
      }

      if (error.response?.statusCode == 403) {
        return 'Only approved experts can review diagnosis cases.';
      }

      if (error.response?.statusCode == 404) {
        return 'This diagnosis case could not be found.';
      }

      if (error.response == null) {
        return 'Cannot connect to the server. Check your connection.';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  String _shortId(String id) {
    return id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  }

  Widget _caseCard(DiagnosisCase item) {
    final imageUrl = _imageUrl(item.photoPath);

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE1E8DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.photoPath.isNotEmpty)
            Image.network(
              imageUrl,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return Container(
                  height: 180,
                  color: cream,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: forest),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: cream,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image_outlined, color: muted, size: 30),
                      const SizedBox(height: 7),
                      Text(AppLocalizations.of(context)!.expertPhotoUnavailable, style: const TextStyle(color: muted)),
                    ],
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'CASE ${_shortId(item.id)}',
                        style: const TextStyle(
                          color: forest,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3D9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          color: Color(0xFF805B16),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  'Reported symptoms',
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.symptoms,
                  style: const TextStyle(color: ink, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'Farmer ID: ${item.farmerId}',
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _reviewing ? null : () => _review(item),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(
                      _reviewing ? 'Saving review...' : 'Review this case',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: forest,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: cream,
        textTheme: Theme.of(context).textTheme
            .apply(bodyColor: ink, displayColor: forest),
      ),
      child: Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.expertQueueTitle),
          backgroundColor: forest,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: AppLocalizations.of(context)!.expertRefresh,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: forest))
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: forest,
                        size: 45,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load the review queue.',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(backgroundColor: forest),
                        child: Text(AppLocalizations.of(context)!.communityRetry),
                      ),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                color: forest,
                onRefresh: _load,
                child: _cases.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.task_alt, size: 58, color: forest),
                          SizedBox(height: 14),
                          Center(
                            child: Text(
                              'No pending cases.',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Center(
                            child: Text(
                              'You are all caught up!',
                              style: TextStyle(color: muted),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) {
                          return _caseCard(_cases[index]);
                        },
                      ),
              ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Review dialog
// -----------------------------------------------------------------------------

class _ReviewResult {
  final bool validated;
  final String diagnosis;
  final String advice;

  const _ReviewResult({
    required this.validated,
    required this.diagnosis,
    required this.advice,
  });
}

class _DiagnosisReviewDialog extends StatefulWidget {
  final DiagnosisCase item;

  const _DiagnosisReviewDialog({required this.item});

  @override
  State<_DiagnosisReviewDialog> createState() => _DiagnosisReviewDialogState();
}

class _DiagnosisReviewDialogState extends State<_DiagnosisReviewDialog> {
  final TextEditingController _diagnosisController = TextEditingController();

  final TextEditingController _adviceController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const forest = Color(0xFF183F32);
  static const ink = Color(0xFF24352C);
  static const muted = Color(0xFF59665C);
  static const cream = Color(0xFFF7F6EF);

  @override
  void dispose() {
    _diagnosisController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: muted),
      floatingLabelStyle: const TextStyle(
        color: forest,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Color(0xFF788278)),
      filled: true,
      fillColor: cream,
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD8E1D6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: forest, width: 1.6),
      ),
    );
  }

  void _submit(bool validated) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final result = _ReviewResult(
      validated: validated,
      diagnosis: _diagnosisController.text.trim(),
      advice: _adviceController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.item.id;
    final shortId = id.length >= 8
        ? id.substring(0, 8).toUpperCase()
        : id.toUpperCase();

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Expert review',
        style: TextStyle(color: forest, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case $shortId',
                  style: const TextStyle(
                    color: forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Farmer symptoms',
                  style: TextStyle(color: ink, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.item.symptoms,
                    style: const TextStyle(color: ink, height: 1.5),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _diagnosisController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 3000,
                  style: const TextStyle(color: ink, fontSize: 15),
                  cursorColor: forest,
                  decoration: _decoration(
                    'Your diagnosis',
                    'Describe the likely crop problem...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Enter a diagnosis (at least 3 characters).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adviceController,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 5000,
                  style: const TextStyle(color: ink, fontSize: 15),
                  cursorColor: forest,
                  decoration: _decoration(
                    'Recommended action',
                    'Explain what the farmer should do...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Enter practical advice (at least 3 characters).';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.expertCancel, style: TextStyle(color: muted)),
        ),
        OutlinedButton(
          onPressed: () => _submit(false),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          child: Text(AppLocalizations.of(context)!.expertReject),
        ),
        FilledButton(
          onPressed: () => _submit(true),
          style: FilledButton.styleFrom(
            backgroundColor: forest,
            foregroundColor: Colors.white,
          ),
          child: Text(AppLocalizations.of(context)!.expertValidate),
        ),
      ],
    );
  }
}
