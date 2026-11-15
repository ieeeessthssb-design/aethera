import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';
import '../widgets/ab.dart';
import '../widgets/app_shell.dart';
import '../widgets/toast.dart';

class _Post {
  const _Post(this.who, this.loc, this.type, this.kind, this.t, this.body,
      {this.note, this.img = false, required this.likes, required this.c});
  final String who, loc, type, t, body;
  final Trust kind;
  final String? note;
  final bool img;
  final int likes, c;
}

const _posts = [
  _Post(
      'Hedi M.',
      'Msaken',
      'Solution',
      Trust.expert,
      'Shade nets cut transplant losses in July',
      'I used 35% shade nets for the first 2 weeks after transplanting. Losses dropped a lot.',
      note:
          'Reviewed by Dr. L. Trabelsi: consistent with heat-stress guidance.',
      likes: 48,
      c: 12),
  _Post(
      'Rim B.',
      'Kalâa Kebira',
      'Experience',
      Trust.community,
      'Citric acid to unclog drippers',
      'Every 3 weeks I run diluted citric acid through the lines. Works for me with our hard water.',
      likes: 31,
      c: 9),
  _Post(
      'Anonymous WhatsApp forward',
      'Shared',
      'Claim',
      Trust.unverified,
      '“Spray bleach on tomatoes to stop all diseases”',
      'Seen in a group this week.',
      note:
          'Flagged: no evidence; may damage plants. Awaiting expert response.',
      likes: 3,
      c: 21),
  _Post(
      'Sami K.',
      'Sidi Bouzid',
      'Problem',
      Trust.community,
      'Brown rings on lower tomato leaves',
      'Started after the humid nights last week. Anyone else?',
      img: true,
      likes: 14,
      c: 7),
];

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  Trust? _f;

  @override
  Widget build(BuildContext context) {
    const filters = <(Trust?, String)>[
      (null, 'All posts'),
      (Trust.expert, '🟢 Expert Verified'),
      (Trust.community, '🟡 Community Experience'),
      (Trust.unverified, '🔴 Needs Verification')
    ];
    return AppShell(
      role: Role.farmer,
      path: '/community',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        PageHeader(
          eyebrow: 'Farmer community',
          title: "Share experience. Know what's verified.",
          desc:
              'Moderated. Community posts are experience, not fact — until an expert reviews them.',
          actions: [
            const ProtoTag(),
            AppButton(
                label: 'New post',
                onPressed: () =>
                    showToast(context, 'Post composer — prototype'))
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (k, t) in filters)
              GestureDetector(
                onTap: () => setState(() => _f = k),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: _f == k ? AppColors.secondary : AppColors.card,
                      border: Border.all(
                          color:
                              _f == k ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(t, style: body(size: 14, w: FontWeight.w600)),
                ),
              ),
          ]),
        ),
        VStack(gap: 16, children: [
          for (final p in _posts.where((p) => _f == null || p.kind == _f))
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                    color: AppColors.muted,
                                    shape: BoxShape.circle),
                                child: Text(p.who[0],
                                    style: body(w: FontWeight.w700))),
                            const SizedBox(width: 12),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.who, style: body(w: FontWeight.w700)),
                                  Text('${p.loc} · ${p.type}',
                                      style: body(
                                          size: 12,
                                          color: AppColors.mutedForeground))
                                ]),
                          ]),
                          TrustLabel(p.kind),
                        ]),
                    const SizedBox(height: 12),
                    Text(p.t, style: display(size: 18)),
                    Text(p.body, style: body(color: AppColors.mutedForeground)),
                    if (p.img)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                  'assets/images/tomato-leaf.jpg',
                                  height: 160,
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Shared crop photo'))),
                    if (p.note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Tinted(
                          color: p.kind == Trust.expert
                              ? AppColors.successSoft
                              : AppColors.dangerSoft,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                    p.kind == Trust.expert
                                        ? LucideIcons.shieldCheck
                                        : LucideIcons.flag,
                                    size: 16,
                                    color: AppColors.foreground),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(p.note!, style: body(size: 14)))
                              ]),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(LucideIcons.thumbsUp,
                          size: 16, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text('${p.likes}',
                          style:
                              body(size: 14, color: AppColors.mutedForeground)),
                      const SizedBox(width: 16),
                      const Icon(LucideIcons.messageCircle,
                          size: 16, color: AppColors.mutedForeground),
                      const SizedBox(width: 4),
                      Text('${p.c}',
                          style:
                              body(size: 14, color: AppColors.mutedForeground)),
                      const Spacer(),
                      if (p.kind != Trust.expert)
                        TextLink('Request verification',
                            onTap: () => showToast(
                                context, 'Sent for expert verification',
                                kind: ToastKind.success)),
                    ]),
                  ]),
            ),
        ]),
      ]),
    );
  }
}
