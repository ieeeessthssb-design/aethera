import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';

InputDecoration fieldDecoration(
        {String? hint,
        double radius = 12,
        EdgeInsetsGeometry? padding,
        Widget? prefix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: body(color: AppColors.mutedForeground.withValues(alpha: .7)),
      filled: true,
      fillColor: AppColors.background,
      isDense: false,
      prefixIcon: prefix,
      contentPadding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.ring, width: 2)),
    );

/// Small bold label above a field (`text-sm font-semibold`).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, required this.child, this.gap = 4});
  final String text;
  final Widget child;
  final double gap;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: body(size: 14, w: FontWeight.w600)),
        SizedBox(height: gap),
        child,
      ]);
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.hint,
    this.height = 48,
    this.maxLines = 1,
    this.minLines,
    this.obscure = false,
    this.keyboardType,
    this.onChanged,
    this.maxLength,
    this.fontSize = 16,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.fillColor,
  });
  final TextEditingController? controller;
  final String? hint;
  final double height;
  final int maxLines;
  final int? minLines;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLength;
  final double fontSize;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final multi = maxLines != 1;
    final dec = fieldDecoration(
        hint: hint,
        padding: EdgeInsets.symmetric(
            horizontal: multi ? 14 : 12, vertical: multi ? 14 : 0));
    return SizedBox(
      height: multi ? null : height,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines ?? (multi ? maxLines : null),
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLength: maxLength,
        autofocus: autofocus,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        style: body(size: fontSize),
        textDirection: Directionality.of(context),
        textAlign: TextAlign.start,
        textAlignVertical:
            multi ? TextAlignVertical.top : TextAlignVertical.center,
        decoration: dec.copyWith(
            counterText: '', fillColor: fillColor ?? AppColors.background),
      ),
    );
  }
}

/// Dropdown styled like the web `<select>`.
class AppSelect extends StatelessWidget {
  const AppSelect(
      {super.key,
      required this.value,
      required this.options,
      required this.onChanged,
      this.height = 48,
      this.labelOf});
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final double height;
  final String Function(String)? labelOf;
  @override
  Widget build(BuildContext context) {
    final v = options.contains(value) ? value : null;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: v,
          isExpanded: true,
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(LucideIcons.chevronDown,
              size: 18, color: AppColors.mutedForeground),
          style: body(),
          items: [
            for (final o in options)
              DropdownMenuItem(
                  value: o,
                  child: Text(labelOf?.call(o) ?? o,
                      overflow: TextOverflow.ellipsis, style: body()))
          ],
          onChanged: (x) {
            if (x != null) onChanged(x);
          },
        ),
      ),
    );
  }
}
