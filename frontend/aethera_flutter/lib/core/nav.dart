import 'package:flutter/material.dart';

/// Navigation helpers (the web app's <Link to="..."> equivalents).
///
/// [go]   pushes a page so the system back button returns to the previous one.
/// [goTab] replaces the current page (used by menus so tabs do not stack up).
Future<T?> go<T extends Object?>(BuildContext context, String path) =>
    Navigator.of(context).pushNamed<T>(path);
Future<T?> goTab<T extends Object?, R extends Object?>(
        BuildContext context, String path) =>
    Navigator.of(context).pushReplacementNamed<T, R>(path);

/// Responsive helpers using Tailwind's breakpoints (sm 640, md 768, lg 1024).
extension Bp on BuildContext {
  double get vw => MediaQuery.sizeOf(this).width;
  bool get isSm => vw >= 640;
  bool get isMd => vw >= 768;
  bool get isLg => vw >= 1024;
}
