import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/nav.dart';
import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';

// ───────────────────────── Cards ─────────────────────────

const List<BoxShadow> kShadowSoft = [
  BoxShadow(color: Color(0x0F0F3620), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(
      color: Color(0x2E0F3620),
      blurRadius: 24,
      spreadRadius: -12,
      offset: Offset(0, 8)),
];

/// `card-surface` of the web app: card background, 1px border, rounded, soft shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.card,
    this.borderColor = AppColors.border,
    this.borderWidth = 1,
    this.radius = 18,
    this.startBar,
    this.shadow = true,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  /// Coloured 4px bar on the leading edge (Tailwind `border-s-4`).
  final Color? startBar;
  final bool shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget inner = Padding(padding: padding, child: child);
    if (startBar != null) {
      inner = Stack(children: [
        Padding(padding: padding, child: child),
        PositionedDirectional(
            top: 0,
            bottom: 0,
            start: 0,
            width: 4,
            child: ColoredBox(color: startBar!)),
      ]);
    }
    final r = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
          color: color,
          borderRadius: r,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadow ? kShadowSoft : null),
      child: ClipRRect(
        borderRadius: r,
        child: onTap == null
            ? inner
            : Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: inner)),
      ),
    );
  }
}

/// Dashed rounded border box.
class DashedBox extends StatelessWidget {
  const DashedBox(
      {super.key,
      required this.child,
      this.color = AppColors.border,
      this.radius = 12,
      this.padding = EdgeInsets.zero,
      this.background,
      this.strokeWidth = 1,
      this.dash = 4,
      this.gap = 3});
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final double strokeWidth;
  final double dash;
  final double gap;
  @override
  Widget build(BuildContext context) => CustomPaint(
        foregroundPainter: _DashPainter(color, radius, strokeWidth, dash, gap),
        child: Container(
            padding: padding,
            decoration: BoxDecoration(
                color: background, borderRadius: BorderRadius.circular(radius)),
            child: child),
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius, this.sw, this.dash, this.gap);
  final Color color;
  final double radius, sw, dash, gap;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(sw / 2, sw / 2, size.width - sw, size.height - sw),
        Radius.circular(radius));
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + dash, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter o) =>
      o.color != color || o.radius != radius || o.sw != sw;
}

// ───────────────────────── Layout helpers ─────────────────────────

class GridCell extends StatelessWidget {
  const GridCell({super.key, this.span = 1, required this.child});
  final int span;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}

int colsFor(BuildContext c, {int base = 1, int? sm, int? md, int? lg}) {
  var n = base;
  if (c.isSm && sm != null) n = sm;
  if (c.isMd && md != null) n = md;
  if (c.isLg && lg != null) n = lg;
  return n;
}

/// CSS-grid like layout: [cols] equal columns, children stretch to equal row height.
/// Wrap a child in [GridCell] to make it span several columns.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid(
      {super.key,
      required this.cols,
      this.gap = 16,
      this.rowGap,
      required this.children});
  final int cols;
  final double gap;
  final double? rowGap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rg = rowGap ?? gap;
    if (cols <= 1) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: rg),
          children[i]
        ],
      ]);
    }
    return LayoutBuilder(builder: (context, c) {
      final colW = (c.maxWidth - gap * (cols - 1)) / cols;
      final rows = <List<Widget>>[];
      var cur = <Widget>[];
      var used = 0;
      for (final ch in children) {
        final span = math.min(ch is GridCell ? ch.span : 1, cols);
        if (used + span > cols) {
          rows.add(cur);
          cur = [];
          used = 0;
        }
        cur.add(SizedBox(width: span * colW + (span - 1) * gap, child: ch));
        used += span;
      }
      if (cur.isNotEmpty) rows.add(cur);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r > 0) SizedBox(height: rg),
          IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var i = 0; i < rows[r].length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                rows[r][i]
              ],
            ]),
          ),
        ],
      ]);
    });
  }
}

/// Vertical stack with uniform spacing (Tailwind `space-y-*`).
class VStack extends StatelessWidget {
  const VStack(
      {super.key,
      required this.children,
      this.gap = 12,
      this.crossAxisAlignment = CrossAxisAlignment.stretch});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: gap),
              children[i]
            ],
          ]);
}

// ───────────────────────── Page header & titles ─────────────────────────

class PageHeader extends StatelessWidget {
  const PageHeader(
      {super.key,
      this.eyebrow,
      required this.title,
      this.desc,
      this.actions = const []});
  final String? eyebrow;
  final String title;
  final String? desc;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final md = context.isMd;
    final text =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (eyebrow != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(eyebrow!.toUpperCase(),
              style: body(
                  size: 14,
                  w: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.7)),
        ),
      Text(title, style: display(size: md ? 36 : 30, height: 1.2)),
      if (desc != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 672),
              child:
                  Text(desc!, style: body(color: AppColors.mutedForeground))),
        ),
    ]);
    final act = actions.isEmpty
        ? null
        : Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: md && act != null
          ? Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              Flexible(
                  child: Align(
                      alignment: AlignmentDirectional.centerEnd, child: act))
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              text,
              if (act != null) ...[const SizedBox(height: 16), act]
            ]),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon});
  final String text;
  final Widget? icon;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          if (icon != null) ...[icon!, const SizedBox(width: 8)],
          Expanded(child: Text(text, style: display(size: 18)))
        ]),
      );
}

/// Lucide icon shortcut.
class LIcon extends StatelessWidget {
  const LIcon(this.icon, {super.key, this.size = 20, this.color});
  final IconData icon;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Icon(icon,
      size: size, color: color ?? DefaultTextStyle.of(context).style.color);
}

// ───────────────────────── Badges ─────────────────────────

enum Conf { high, medium, low }

class Confidence extends StatelessWidget {
  const Confidence({super.key, required this.level, this.value});
  final Conf level;
  final int? value;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, bars, name) = switch (level) {
      Conf.high => (AppColors.successSoft, AppColors.success, 3, 'High'),
      Conf.medium => (
          AppColors.warningSoft,
          AppColors.accentForeground,
          2,
          'Medium'
        ),
      Conf.low => (AppColors.dangerSoft, AppColors.destructive, 1, 'Low'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var b = 1; b <= 3; b++)
                Container(
                  margin: EdgeInsetsDirectional.only(end: b < 3 ? 2 : 0),
                  width: 4,
                  height: 4.0 + b * 3,
                  decoration: BoxDecoration(
                      color: fg.withValues(alpha: b <= bars ? 1 : .25),
                      borderRadius: BorderRadius.circular(2)),
                ),
            ]),
        const SizedBox(width: 8),
        Flexible(
            child: Text('${value != null ? '$value% · ' : ''}$name confidence',
                style: body(size: 14, w: FontWeight.w600, color: fg))),
      ]),
    );
  }
}

enum Trust { expert, community, unverified, ai }

class TrustLabel extends StatelessWidget {
  const TrustLabel(this.kind, {super.key});
  final Trust kind;
  @override
  Widget build(BuildContext context) {
    final (text, bg, fg, icon) = switch (kind) {
      Trust.expert => (
          'Expert Verified',
          AppColors.successSoft,
          AppColors.success,
          LucideIcons.shieldCheck
        ),
      Trust.community => (
          'Community Experience',
          AppColors.warningSoft,
          AppColors.accentForeground,
          LucideIcons.users
        ),
      Trust.unverified => (
          'Needs Verification',
          AppColors.dangerSoft,
          AppColors.destructive,
          LucideIcons.alertTriangle
        ),
      Trust.ai => (
          'AI-generated guidance',
          AppColors.secondary,
          AppColors.secondaryForeground,
          LucideIcons.sparkles
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Flexible(
            child: Text(text,
                style: body(size: 12, w: FontWeight.w600, color: fg))),
      ]),
    );
  }
}

class ProtoTag extends StatelessWidget {
  const ProtoTag({super.key});
  @override
  Widget build(BuildContext context) => DashedBox(
        color: AppColors.earth.withValues(alpha: .5),
        radius: 6,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text('PROTOTYPE DATA',
            style: body(
                size: 11,
                w: FontWeight.w500,
                color: AppColors.earth,
                letterSpacing: 0.55,
                height: 16 / 11)),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.muted, borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: body(
                size: 12,
                w: FontWeight.w500,
                color: AppColors.mutedForeground)),
      );
}

/// Small coloured chip used for NEW / Resolved / Best match tags.
class Tag extends StatelessWidget {
  const Tag(this.text,
      {super.key,
      this.bg = AppColors.accent,
      this.fg = AppColors.accentForeground,
      this.size = 12});
  final String text;
  final Color bg;
  final Color fg;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child:
            Text(text, style: body(size: size, w: FontWeight.w700, color: fg)),
      );
}

class Stat extends StatelessWidget {
  const Stat(
      {super.key,
      required this.label,
      required this.value,
      this.sub,
      this.icon});
  final String label;
  final String value;
  final String? sub;
  final Widget? icon;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: Text(label,
                    style: body(size: 14, color: AppColors.mutedForeground))),
            if (icon != null) icon!
          ]),
          const SizedBox(height: 4),
          Text(value, style: display(size: 24)),
          if (sub != null)
            Text(sub!, style: body(size: 12, color: AppColors.mutedForeground)),
        ]),
      );
}

class Journey extends StatelessWidget {
  const Journey({super.key, required this.steps, this.active});
  final List<String> steps;
  final int? active;
  @override
  Widget build(BuildContext context) => Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < steps.length; i++)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color:
                          i == active ? AppColors.primary : AppColors.secondary,
                      borderRadius: BorderRadius.circular(999)),
                  child: Text(steps[i],
                      style: body(
                          size: 14,
                          w: FontWeight.w600,
                          color: i == active
                              ? AppColors.primaryForeground
                              : AppColors.secondaryForeground)),
                ),
                if (i < steps.length - 1)
                  Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text('→',
                          style: body(
                              size: 14, color: AppColors.mutedForeground))),
              ]),
          ]);
}

/// Horizontal progress bar (rounded track + fill).
class Bar extends StatelessWidget {
  const Bar(
      {super.key,
      required this.fraction,
      this.height = 12,
      this.fill = AppColors.primary,
      this.track = AppColors.muted});
  final double fraction;
  final double height;
  final Color fill;
  final Color track;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          color: track,
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
              widthFactor: fraction.clamp(0, 1).toDouble(),
              child: Container(
                  decoration: BoxDecoration(
                      color: fill, borderRadius: BorderRadius.circular(999)))),
        ),
      );
}

/// A round numbered badge (1, 2, 3…) used in ordered lists.
class NumDot extends StatelessWidget {
  const NumDot(this.n, {super.key, this.size = 28, this.fontSize = 14});
  final int n;
  final double size;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Text('$n',
            style: body(
                size: fontSize,
                w: FontWeight.w700,
                color: AppColors.primaryForeground,
                height: 1)),
      );
}

/// Rounded tinted box (e.g. `rounded-xl bg-muted p-3`).
class Tinted extends StatelessWidget {
  const Tinted(
      {super.key,
      required this.child,
      this.color = AppColors.muted,
      this.padding = const EdgeInsets.all(12),
      this.radius = 12,
      this.borderColor});
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border:
                borderColor == null ? null : Border.all(color: borderColor!)),
        child: child,
      );
}

/// "Label: **value**" rich text.
TextSpan kv(String k, String v, {double size = 14}) => TextSpan(children: [
      TextSpan(
          text: '$k: ',
          style: body(size: size, color: AppColors.mutedForeground)),
      TextSpan(text: v, style: body(size: size, w: FontWeight.w700)),
    ]);

// ───────────────────────── Buttons ─────────────────────────

enum BtnVariant { primary, accent, outline, ghost, soft }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.variant = BtnVariant.primary,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.fontSize = 15,
    this.loading = false,
  });
  final String? label;
  final Widget? child;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final BtnVariant variant;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final double fontSize;
  final bool loading;

  /// Link-style button that navigates to [path].
  static Widget link(BuildContext context, String path, String label,
          {BtnVariant variant = BtnVariant.primary,
          IconData? icon,
          IconData? trailingIcon,
          bool expand = false,
          EdgeInsetsGeometry? padding,
          double fontSize = 15,
          bool tab = false}) =>
      AppButton(
          label: label,
          icon: icon,
          trailingIcon: trailingIcon,
          variant: variant,
          expand: expand,
          fontSize: fontSize,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          onPressed: () => tab ? goTab(context, path) : go(context, path));

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      BtnVariant.primary => (
          AppColors.primary,
          AppColors.primaryForeground,
          null
        ),
      BtnVariant.accent => (AppColors.accent, AppColors.accentForeground, null),
      BtnVariant.outline => (
          AppColors.card,
          AppColors.foreground,
          AppColors.input
        ),
      BtnVariant.ghost => (Colors.transparent, AppColors.foreground, null),
      BtnVariant.soft => (
          AppColors.secondary,
          AppColors.secondaryForeground,
          null
        ),
    };
    final disabled = onPressed == null || loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: fontSize > 16 ? 20 : 18, color: fg),
          const SizedBox(width: 8)
        ],
        if (child != null)
          Flexible(
              child: DefaultTextStyle(
                  style: body(size: fontSize, w: FontWeight.w600, color: fg),
                  textAlign: TextAlign.center,
                  child: child!)),
        if (label != null)
          Flexible(
              child: Text(label!,
                  textAlign: TextAlign.center,
                  style: body(
                      size: fontSize,
                      w: FontWeight.w600,
                      color: fg,
                      height: 1.3))),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 20, color: fg)
        ],
      ],
    );
    return Opacity(
      opacity: disabled && !loading ? .5 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: border == null ? BorderSide.none : BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                  padding: padding,
                  child:
                      Center(widthFactor: 1, heightFactor: 1, child: content))),
        ),
      ),
    );
  }
}

/// Text-only link, e.g. "View crop plan →".
class TextLink extends StatelessWidget {
  const TextLink(this.text,
      {super.key,
      this.onTap,
      this.path,
      this.size = 14,
      this.color = AppColors.primary,
      this.align});
  final String text;
  final VoidCallback? onTap;
  final String? path;
  final double size;
  final Color color;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap ?? (path == null ? null : () => go(context, path!)),
        child: Text(text,
            textAlign: align,
            style: body(size: size, w: FontWeight.w600, color: color)),
      );
}

/// Whole-area tap wrapper with ripple, used for list rows and tiles.
class Tappable extends StatelessWidget {
  const Tappable(
      {super.key,
      required this.child,
      this.onTap,
      this.radius = 12,
      this.color});
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
      color: color ?? Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child));
}

/// Subtle dotted background (`field-pattern` utility of the web app).
class FieldPattern extends StatelessWidget {
  const FieldPattern({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DotsPainter(), child: child);
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.primary.withValues(alpha: .09);
    for (double y = 9; y < size.height; y += 18) {
      for (double x = 9; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), .5, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
