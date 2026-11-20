import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/scope.dart';
import '../theme/lucide_icons.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/photo_picker.dart';
import '../widgets/risk.dart';
import '../widgets/toast.dart';

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _crop = 'tomato';
  String _symptom = 'leaf_spots';
  String _gov = 'Sousse';
  final _details = TextEditingController();
  final _locality = TextEditingController();
  late DateTime _date = DateTime.now();
  PickedPhoto? _photo;
  bool _busy = false;

  @override
  void dispose() {
    _details.dispose();
    _locality.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = context.l;
    final c = Backend.client;
    final user = context.auth.user;
    if (c == null || user == null) return;
    setState(() => _busy = true);
    String? photoPath;
    final p = _photo;
    if (p != null && p.path != null) {
      final rnd = Random().nextInt(1 << 31).toRadixString(16);
      final safe = p.name.replaceAll(RegExp(r'[^\w.]'), '_');
      final path =
          '${user.id}/${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}$rnd-$safe';
      try {
        await c.storage.from('report-photos').upload(path, File(p.path!));
        photoPath = path;
      } catch (_) {}
    }
    try {
      await c.from('risk_reports').insert({
        'crop': _crop,
        'symptom_category': _symptom,
        'symptoms': _details.text,
        'governorate': _gov,
        'locality': _locality.text.isEmpty ? null : _locality.text,
        'observed_on': _iso(_date),
        'photo_path': photoPath,
        'user_id': user.id,
      });
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, l.t('sent'), kind: ToastKind.success);
      Navigator.of(context).pushReplacementNamed('/radar');
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showToast(context, l.t('aiError'), kind: ToastKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final auth = context.auth;
    return AppShell(
      role: Role.farmer,
      path: '/report',
      child: ListenableBuilder(
        listenable: auth,
        builder: (context, _) =>
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          PageHeader(
              eyebrow: l.navLabel('Risk Radar'),
              title: l.t('reportProblem'),
              desc: l.t('privacyNote')),
          if (!auth.ready)
            const SizedBox.shrink()
          else if (auth.user == null)
            const SignInCta()
          else
            Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 672),
                    child: _form(context))),
        ]),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final l = context.l;
    return AppCard(
      child: ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 16, children: [
        FieldLabel(l.t('crop'),
            child: AppSelect(
                height: 44,
                value: _crop,
                options: kCrops,
                labelOf: l.label,
                onChanged: (v) => setState(() => _crop = v))),
        FieldLabel(l.t('symptom'),
            child: AppSelect(
                height: 44,
                value: _symptom,
                options: kSymptoms,
                labelOf: l.label,
                onChanged: (v) => setState(() => _symptom = v))),
        GridCell(
            span: 2,
            child: FieldLabel(l.t('details'),
                child: AppTextField(
                    controller: _details, maxLines: 3, maxLength: 1000))),
        FieldLabel(l.t('governorate'),
            child: AppSelect(
                height: 44,
                value: _gov,
                options: kGovernorates,
                onChanged: (v) => setState(() => _gov = v))),
        FieldLabel(l.t('locality'),
            child: AppTextField(
                controller: _locality, height: 44, maxLength: 100)),
        FieldLabel(
          l.t('observedOn'),
          child: AppTextField(
            height: 44,
            readOnly: true,
            controller: TextEditingController(text: _iso(_date)),
            onTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        FieldLabel(
          l.t('photo'),
          gap: 8,
          child: Row(children: [
            AppButton(
              variant: BtnVariant.outline,
              icon: LucideIcons.camera,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              label: _photo == null
                  ? l.t('photo').split(' (').first
                  : _photo!.name,
              onPressed: () async {
                final p = await pickPhoto(context, source: null);
                if (p != null && mounted) setState(() => _photo = p);
              },
            ),
            if (_photo != null)
              GestureDetector(
                  onTap: () => setState(() => _photo = null),
                  child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(LucideIcons.x, size: 16))),
          ]),
        ),
        GridCell(
            span: 2,
            child: AppButton(
                label: l.t('submit'),
                expand: true,
                loading: _busy,
                onPressed: _busy ? null : _submit)),
      ]),
    );
  }
}
