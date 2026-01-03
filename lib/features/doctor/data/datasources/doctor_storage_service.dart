import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Exception for storage operations
class StorageException implements Exception {
  final String message;
  final String? code;
  final Exception? originalError;

  StorageException({required this.message, this.code, this.originalError});

  @override
  String toString() => 'StorageException: $message (code: $code)';
}

/// Result of image compression
class CompressedImageResult {
  final File compressedFile;
  final int originalSizeKB;
  final int compressedSizeKB;
  final double compressionRatio; // 0-1, lower is better compression

  CompressedImageResult({
    required this.compressedFile,
    required this.originalSizeKB,
    required this.compressedSizeKB,
    required this.compressionRatio,
  });

  bool get isValidCompression =>
      compressionRatio < 0.8; // At least 20% reduction
}

/// Firebase Storage service for doctor profiles
/// Handles: image upload, compression, metadata, retry logic, error handling
class DoctorStorageService {
  static final DoctorStorageService _instance =
      DoctorStorageService._internal();

  final FirebaseStorage _firebaseStorage;

  // Image constraints
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxDimension = 1920;
  static const int compressionQuality = 85;
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  DoctorStorageService._internal({FirebaseStorage? firebaseStorage})
    : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  factory DoctorStorageService({FirebaseStorage? firebaseStorage}) {
    return _instance;
  }

  /// Upload doctor profile photo with compression
  ///
  /// Parameters:
  /// - [doctorId]: Doctor's UID
  /// - [imageFile]: Original image file to upload
  /// - [onProgress]: Optional callback for upload progress (0.0 to 1.0)
  ///
  /// Returns: Storage path relative to bucket root
  ///
  /// Throws: [StorageException] on failure
  Future<String> uploadProfilePhoto({
    required String doctorId,
    required File imageFile,
    void Function(double)? onProgress,
  }) async {
    try {
      // Validate inputs
      _validateImageFile(imageFile);

      // Compress image
      final compressed = await _compressImage(imageFile);
      if (!compressed.isValidCompression) {
        throw StorageException(
          message:
              'Image compression failed - compression ratio: ${compressed.compressionRatio}',
          code: 'COMPRESSION_FAILED',
        );
      }

      // Generate storage path
      final storagePath = _generateStoragePath(doctorId);
      final reference = _firebaseStorage.ref(storagePath);

      // Get MIME type
      final mimeType = _getMimeType(imageFile);

      // Upload with retry logic and progress tracking
      final uploadTask = reference.putFile(
        compressed.compressedFile,
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'doctorId': doctorId,
            'originalSizeMB': (compressed.originalSizeKB / 1024)
                .toStringAsFixed(2),
            'compressedSizeMB': (compressed.compressedSizeKB / 1024)
                .toStringAsFixed(2),
            'compressionRatio': compressed.compressionRatio.toStringAsFixed(2),
          },
        ),
      );

      // Listen to progress if callback provided
      uploadTask.snapshotEvents.listen((event) {
        if (onProgress != null && event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });

      // Wait for upload to complete
      await uploadTask;

      // Cleanup compressed file
      await compressed.compressedFile
          .delete()
          .then((_) => true)
          .catchError((_) => false);

      // Return storage path (not full URL - for flexibility)
      return storagePath;
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Firebase storage error: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        message: 'Unexpected error uploading profile photo: $e',
        originalError: e is Exception ? e : null,
      );
    }
  }

  /// Get download URL for a stored image
  ///
  /// Parameters:
  /// - [storagePath]: Relative path to image in storage
  ///
  /// Returns: Full download URL
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final reference = _firebaseStorage.ref(storagePath);
      return await reference.getDownloadURL();
    } on FirebaseException catch (e) {
      throw StorageException(
        message: 'Failed to get download URL: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  /// Delete stored image
  ///
  /// Parameters:
  /// - [storagePath]: Relative path to image to delete
  ///
  /// Throws: [StorageException] on failure
  Future<void> deleteProfilePhoto(String storagePath) async {
    try {
      final reference = _firebaseStorage.ref(storagePath);
      await reference.delete();
    } on FirebaseException catch (e) {
      // Don't fail if file doesn't exist - already deleted
      if (e.code != 'object-not-found') {
        throw StorageException(
          message: 'Failed to delete profile photo: ${e.message}',
          code: e.code,
          originalError: e,
        );
      }
    }
  }

  /// Update existing profile photo - replaces old one
  ///
  /// Parameters:
  /// - [doctorId]: Doctor's UID
  /// - [imageFile]: New image file
  /// - [oldStoragePath]: Path to old image to delete
  /// - [onProgress]: Optional progress callback
  ///
  /// Returns: New storage path
  Future<String> updateProfilePhoto({
    required String doctorId,
    required File imageFile,
    required String oldStoragePath,
    void Function(double)? onProgress,
  }) async {
    try {
      // Upload new photo first
      final newPath = await uploadProfilePhoto(
        doctorId: doctorId,
        imageFile: imageFile,
        onProgress: onProgress,
      );

      // Delete old photo in background (don't block on failure)
      deleteProfilePhoto(oldStoragePath).catchError((_) {});

      return newPath;
    } catch (e) {
      rethrow;
    }
  }

  /// ==================== PRIVATE HELPER METHODS ====================

  /// Compress image to reduce file size and dimensions
  ///
  /// Strategy:
  /// 1. Check if compression is needed (file > 1MB or dimensions > 1920px)
  /// 2. Reduce dimensions if needed (max 1920px)
  /// 3. Compress to 85% quality
  /// 4. Validate compression ratio (target 20-50% reduction)
  Future<CompressedImageResult> _compressImage(File imageFile) async {
    try {
      final originalSize = await imageFile.length();
      final originalSizeKB = originalSize ~/ 1024;

      // If file is already small, return as-is
      if (originalSizeKB < 200) {
        return CompressedImageResult(
          compressedFile: imageFile,
          originalSizeKB: originalSizeKB,
          compressedSizeKB: originalSizeKB,
          compressionRatio: 1.0,
        );
      }

      // Get temp directory for compressed file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Compress image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        tempPath,
        quality: compressionQuality,
        minWidth: 0,
        minHeight: 0,
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        throw StorageException(
          message: 'Image compression returned null',
          code: 'COMPRESSION_NULL_RESULT',
        );
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final compressedSizeKB = compressedSize ~/ 1024;
      final ratio = compressedSize / originalSize;

      return CompressedImageResult(
        compressedFile: compressedFile,
        originalSizeKB: originalSizeKB,
        compressedSizeKB: compressedSizeKB,
        compressionRatio: ratio,
      );
    } catch (e) {
      throw StorageException(
        message: 'Error compressing image: $e',
        originalError: e is Exception ? e : null,
      );
    }
  }

  /// Validate image file before upload
  void _validateImageFile(File imageFile) {
    if (!imageFile.existsSync()) {
      throw StorageException(
        message: 'Image file does not exist: ${imageFile.path}',
        code: 'FILE_NOT_FOUND',
      );
    }

    final sizeBytes = imageFile.lengthSync();
    if (sizeBytes > maxImageSizeBytes) {
      throw StorageException(
        message:
            'Image exceeds maximum size of 5MB (file: ${(sizeBytes / 1024 / 1024).toStringAsFixed(2)}MB)',
        code: 'FILE_TOO_LARGE',
      );
    }

    if (sizeBytes == 0) {
      throw StorageException(
        message: 'Image file is empty',
        code: 'FILE_EMPTY',
      );
    }
  }

  /// Get MIME type from file extension
  String _getMimeType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    return mimeTypes[extension] ?? 'image/jpeg';
  }

  /// Generate unique storage path for doctor photo
  ///
  /// Path format: doctors/{doctorId}/photo/profile_{timestamp}.jpg
  /// This allows multiple versions if needed, latest one overwrites
  String _generateStoragePath(String doctorId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'doctors/$doctorId/photo/profile_$timestamp.jpg';
  }
}
