import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/fields.dart';
import '../widgets/toast.dart';

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});
  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  bool _edit = false;
  final Map<String, String> _f = {
    'Name': 'Ferme Ben Salem — Plot A',
    'Location': 'Msaken, Sousse',
    'Size': '2.5 ha',
    'Main crop': 'Tomato (Jul–Dec)',
    'Secondary crops': 'Olive (0.4 ha), Onion',
    'Irrigation': 'Drip irrigation',
    'Water source': 'Private well (quota)',
    'Water availability': 'Limited',
    'Soil': 'Sandy-loam, slightly saline',
    'Objectives': 'Save water · Reduce disease losses',
  };
  late final Map<String, TextEditingController> _ctl = {
    for (final e in _f.entries) e.key: TextEditingController(text: e.value)
  };

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      role: Role.farmer,
      path: '/farm',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(
          eyebrow: 'My farm',
          title: 'Farm profile',
          desc: 'Every recommendation uses this context.',
          actions: [
            const ProtoTag(),
            AppButton(
              variant: _edit ? BtnVariant.primary : BtnVariant.outline,
              icon: _edit ? LucideIcons.save : LucideIcons.pencil,
              label: _edit ? 'Save' : 'Edit',
              onPressed: () {
                if (_edit) {
                  for (final e in _ctl.entries) {
                    _f[e.key] = e.value.text;
                  }
                  showToast(context, 'Farm profile saved',
                      kind: ToastKind.success);
                }
                setState(() => _edit = !_edit);
              },
            ),
          ],
        ),
        AppCard(
          child:
              ResponsiveGrid(cols: colsFor(context, sm: 2), gap: 16, children: [
            for (final k in _f.keys)
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k,
                    style: body(size: 14, color: AppColors.mutedForeground)),
                if (_edit) ...[
                  const SizedBox(height: 4),
                  AppTextField(controller: _ctl[k])
                ] else
                  Text(_f[k]!, style: body(size: 18, w: FontWeight.w600)),
              ]),
          ]),
        ),
      ]),
    );
  }
}
