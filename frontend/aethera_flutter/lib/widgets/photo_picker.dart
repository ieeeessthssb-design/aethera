import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/colors.dart';
import '../theme/lucide_icons.dart';
import '../theme/text.dart';

/// A photo chosen by the user (or the bundled sample leaf when the camera/gallery is unavailable).
class PickedPhoto {
  const PickedPhoto({this.path, required this.name, required this.bytes});
  final String? path;
  final String name;
  final int bytes;

  static const sample =
      PickedPhoto(name: 'tomato_leaf_0610.jpg', bytes: 1258291);

  ImageProvider get provider => path == null
      ? const AssetImage('assets/images/tomato-leaf.jpg')
      : FileImage(File(path!)) as ImageProvider;
  String get sizeLabel => bytes >= 1048576
      ? '${(bytes / 1048576).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).round()} KB';
}

Future<PickedPhoto?> pickPhoto(BuildContext context,
    {ImageSource? source}) async {
  ImageSource? src = source;
  src ??= await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        ListTile(
            leading: const Icon(LucideIcons.camera, color: AppColors.primary),
            title: Text('Take photo', style: body(w: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(
            leading: const Icon(LucideIcons.upload, color: AppColors.primary),
            title: Text('Upload image', style: body(w: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (src == null) return null;
  try {
    final x = await ImagePicker()
        .pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (x == null) return null;
    final name = x.path.split(RegExp(r'[\\/]')).last;
    return PickedPhoto(path: x.path, name: name, bytes: await x.length());
  } catch (_) {
    // Camera/gallery unavailable (simulator, denied permission): fall back to the sample photo like the web prototype.
    return PickedPhoto.sample;
  }
}
