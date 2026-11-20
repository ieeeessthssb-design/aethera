// Shows a text written by the expert (French) in Arabic for a farmer who uses
// the Tunisian/Arabic interface. If the text is already Arabic, or the
// farmer uses French, it is shown as is. If translation fails, the original
// French is shown with a short note.
import 'package:flutter/material.dart';

import '../core/translate_service.dart';
import '../theme/colors.dart';
import '../theme/text.dart';

class TranslatedText extends StatefulWidget {
  const TranslatedText(this.text,
      {super.key, required this.toArabic, this.size = 14, this.weight});

  final String text;

  /// true = translate French -> Arabic (farmer uses the Arabic interface).
  final bool toArabic;
  final double size;
  final FontWeight? weight;

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _arabic;
  bool _loading = false;
  bool _failed = false;
  bool _showOriginal = false;

  bool get _needs =>
      widget.toArabic &&
      widget.text.trim().isNotEmpty &&
      !TranslateService.hasArabic(widget.text);

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(covariant TranslatedText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.toArabic != widget.toArabic) {
      _arabic = null;
      _failed = false;
      _showOriginal = false;
      _run();
    }
  }

  Future<void> _run() async {
    if (!_needs) return;
    final src = widget.text;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final ar = await TranslateService.frenchToArabic(src);
      if (!mounted || src != widget.text) return;
      setState(() {
        _arabic = ar;
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
final style = body(
  size: widget.size,
  w: widget.weight ?? FontWeight.normal,
);    if (!_needs) return Text(widget.text, style: style);
    if (_loading) {
      return Row(children: [
        const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Text('نترجمو في الرد…',
            style: body(size: 13, color: AppColors.mutedForeground)),
      ]);
    }
    final small = body(size: 12, color: AppColors.mutedForeground);
    if (_arabic != null && !_showOriginal) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_arabic!, style: style),
        const SizedBox(height: 2),
        Text('ترجمة آلية من الفرنسية', style: small),
        GestureDetector(
          onTap: () => setState(() => _showOriginal = true),
          child: Text('شوف النص الأصلي (فرنسي)',
              style: small.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline)),
        ),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
            width: double.infinity, child: Text(widget.text, style: style)),
      ),
      if (_failed) ...[
        const SizedBox(height: 2),
        Text('الترجمة مش متوفّرة توّا. هذا النص الأصلي بالفرنسية.',
            style: small.copyWith(color: AppColors.destructive)),
        GestureDetector(
          onTap: _run,
          child: Text('عاود حاول',
              style: small.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline)),
        ),
      ] else if (_arabic != null)
        GestureDetector(
          onTap: () => setState(() => _showOriginal = false),
          child: Text('شوف الترجمة',
              style: small.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline)),
        ),
    ]);
  }
}
