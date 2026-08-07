import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Picks and compresses images for upload (T-070).
final class ImageService {
  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const int _maxUploadBytes = 2 * 1024 * 1024;

  /// Picks an image and compresses it under 2 MB. Returns null on cancel.
  Future<File?> pickAvatar({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null) {
      return null;
    }

    final file = File(picked.path);
    if (await file.length() <= _maxUploadBytes) {
      return file;
    }
    return _compress(file);
  }

  /// Picks a document photo at high resolution for AI table reading.
  Future<File?> pickKrsPhoto({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2560,
      maxHeight: 2560,
      imageQuality: 92,
    );
    return picked == null ? null : File(picked.path);
  }

  Future<File> _compress(File file) async {
    final targetPath =
        '${file.path}_compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 80,
      minWidth: 720,
      minHeight: 720,
    );
    if (result == null) {
      throw StateError('Image compression failed.');
    }
    return File(result.path);
  }
}
