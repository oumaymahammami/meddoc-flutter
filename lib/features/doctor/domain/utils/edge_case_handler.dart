import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';

/// Retries a Firestore operation with exponential backoff
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 500),
}) async {
  int attempts = 0;

  while (attempts < maxAttempts) {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      attempts++;

      // Don't retry on permission errors
      if (e.code == 'permission-denied') {
        log('Permission denied, not retrying');
        rethrow;
      }

      // Don't retry on invalid data
      if (e.code == 'invalid-argument') {
        log('Invalid argument, not retrying');
        rethrow;
      }

      if (attempts >= maxAttempts) {
        log('Max retries reached for operation');
        rethrow;
      }

      // Exponential backoff
      final delay = initialDelay * (1 << (attempts - 1));
      log('Retry attempt $attempts after ${delay.inMilliseconds}ms');
      await Future.delayed(delay);
    }
  }

  throw Exception('Failed after $maxAttempts attempts');
}

/// Handles concurrent update conflicts
class ConcurrentUpdateHandler {
  /// Check if a conflict occurred (last-write-wins)
  static bool hasConflict(DateTime localTime, DateTime remoteTime) {
    return localTime.isBefore(remoteTime);
  }

  /// Resolve conflict by merging local and remote changes
  static Map<String, dynamic> mergeChanges({
    required Map<String, dynamic> localChanges,
    required Map<String, dynamic> remoteData,
  }) {
    final merged = {...remoteData};

    // Apply local changes on top of remote
    for (final entry in localChanges.entries) {
      if (entry.value is Map) {
        if (merged[entry.key] is Map) {
          // Merge nested maps
          (merged[entry.key] as Map).addAll(entry.value as Map);
        } else {
          merged[entry.key] = entry.value;
        }
      } else {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }
}

/// Handles offline storage and sync
class OfflineHandler {
  /// Queue changes for sync when offline
  static void queueChanges(Map<String, dynamic> changes) {
    // Implementation would use local storage (SharedPreferences or Hive)
    log('Queued offline changes: $changes');
  }

  /// Sync queued changes when connection restored
  static Future<void> syncQueuedChanges() async {
    // Implementation would retrieve and apply queued changes
    log('Syncing queued offline changes');
  }
}

/// Handles storage errors
class StorageErrorHandler {
  static String getErrorMessage(String errorCode) {
    return switch (errorCode) {
      'storage-full' => 'Storage quota exceeded. Please try again later.',
      'object-not-found' => 'File not found. It may have been deleted.',
      'unauthorized' => 'You do not have permission to access this file.',
      'cancelled' => 'Upload cancelled by user.',
      'unknown' => 'An unknown storage error occurred.',
      _ => 'Storage error: $errorCode',
    };
  }

  /// Cleanup orphaned storage files
  static Future<void> cleanupOrphanedFiles(List<String> storagePaths) async {
    log('Cleaning up ${storagePaths.length} orphaned files');
    // Would implement actual cleanup logic
  }
}

/// Handles permission errors
class PermissionErrorHandler {
  static String getErrorMessage(String field) {
    return 'You do not have permission to edit: $field';
  }

  static bool isFieldRestricted(String field) {
    const restrictedFields = {
      'verification',
      'visibility',
      'metrics',
      'createdAt',
      'uid',
    };
    return restrictedFields.contains(field);
  }
}

/// Handles validation errors
class ValidationErrorHandler {
  static String getDisplayMessage(String fieldName, String validationMessage) {
    return '$fieldName: $validationMessage';
  }

  static List<String> formatErrors(List<dynamic> errors) {
    return errors.map((e) => e.toString()).toList();
  }
}

/// Handles network issues
class NetworkErrorHandler {
  static String getErrorMessage(String errorCode) {
    return switch (errorCode) {
      'unavailable' => 'Service unavailable. Please try again later.',
      'deadline-exceeded' => 'Request timed out. Please check your connection.',
      'network-error' =>
        'Network error. Please check your internet connection.',
      _ => 'Network error: $errorCode',
    };
  }

  static bool isRetryable(String errorCode) {
    return [
      'unavailable',
      'deadline-exceeded',
      'network-error',
      'internal',
      'aborted',
    ].contains(errorCode);
  }
}

/// Handles data consistency
class DataConsistencyHandler {
  /// Validate profile data consistency
  static List<String> validateConsistency({
    required String fullName,
    required bool inPersonMode,
    required double inPersonPrice,
    required bool videoMode,
    required double videoPrice,
  }) {
    final issues = <String>[];

    if (fullName.trim().isEmpty) {
      issues.add('Full name is required');
    }

    if (!inPersonMode && !videoMode) {
      issues.add('At least one consultation mode must be enabled');
    }

    if (inPersonMode && inPersonPrice <= 0) {
      issues.add('In-person price must be greater than 0');
    }

    if (videoMode && videoPrice <= 0) {
      issues.add('Video price must be greater than 0');
    }

    return issues;
  }

  /// Check for required field combinations
  static List<String> validateDependencies({
    required bool hasClinic,
    required String? clinicAddress,
    required String? clinicCity,
  }) {
    final issues = <String>[];

    if (hasClinic && (clinicAddress == null || clinicAddress.isEmpty)) {
      issues.add('Clinic requires an address');
    }

    if (hasClinic && (clinicCity == null || clinicCity.isEmpty)) {
      issues.add('Clinic requires a city');
    }

    return issues;
  }
}

/// Graceful degradation for partial failures
class GracefulDegradation {
  /// Handle partial update success
  static void handlePartialSuccess({
    required bool fieldsUpdated,
    required bool photoUpdated,
    required String? errorMessage,
  }) {
    if (fieldsUpdated && !photoUpdated) {
      log('Profile updated but photo upload failed: $errorMessage');
    } else if (!fieldsUpdated && photoUpdated) {
      log('Photo uploaded but profile update failed: $errorMessage');
    }
  }

  /// Fallback data when sync fails
  static Map<String, dynamic> getFallbackProfile({
    required String uid,
    required String email,
  }) {
    return {
      'uid': uid,
      'email': email,
      'fullName': '',
      'bio': null,
      'contacts': {'phone': null, 'email': null},
      'clinic': null,
      'consultationModes': {'inPerson': false, 'video': false},
      'pricing': {'inPersonTND': 0.0, 'videoTND': 0.0},
      'languages': [],
      'acceptingNewPatients': true,
    };
  }
}

/// Specific error classes for better error handling
class OfflineEditException implements Exception {
  final String message;
  final Map<String, dynamic> queuedChanges;

  OfflineEditException(this.message, this.queuedChanges);

  @override
  String toString() => message;
}

class ConcurrentUpdateException implements Exception {
  final String message;
  final DateTime localTime;
  final DateTime remoteTime;

  ConcurrentUpdateException(this.message, this.localTime, this.remoteTime);

  @override
  String toString() => '$message - Local: $localTime, Remote: $remoteTime';
}

class PartialUpdateException implements Exception {
  final String message;
  final Map<String, dynamic>? successfulUpdates;
  final String? failedField;

  PartialUpdateException(
    this.message, {
    this.successfulUpdates,
    this.failedField,
  });

  @override
  String toString() => message;
}

class StorageQuotaException implements Exception {
  final String message;

  StorageQuotaException(this.message);

  @override
  String toString() => message;
}

class PermissionDeniedException implements Exception {
  final String message;
  final String? restrictedField;

  PermissionDeniedException(this.message, {this.restrictedField});

  @override
  String toString() => message;
}
