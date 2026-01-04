import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

/// Service to geocode doctor addresses and update their coordinates in Firestore
class GeocodingService {
  final FirebaseFirestore _firestore;

  GeocodingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Geocode a single doctor's address and update Firestore
  Future<bool> geocodeDoctorAddress(
    String doctorId, {
    bool forceReGeocode = false,
  }) async {
    try {
      final doctorDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        debugPrint('Doctor $doctorId not found');
        return false;
      }

      final data = doctorDoc.data()!;
      final locationMap = data['location'] as Map<String, dynamic>?;

      if (locationMap == null) {
        debugPrint('No location data for doctor $doctorId');
        return false;
      }

      final address = locationMap['address']?.toString() ?? '';
      final city = locationMap['city']?.toString() ?? '';
      final postalCode = locationMap['postalCode']?.toString() ?? '';
      final country = locationMap['country']?.toString() ?? 'France';

      // Check if coordinates already exist and are not default (0, 0)
      final coordsMap = locationMap['coordinates'] as Map<String, dynamic>?;
      final existingLat = (coordsMap?['latitude'] ?? 0.0) as num;
      final existingLng = (coordsMap?['longitude'] ?? 0.0) as num;

      if (!forceReGeocode && existingLat != 0.0 && existingLng != 0.0) {
        debugPrint('Doctor $doctorId already has valid coordinates');
        return true;
      }

      // Build full address for geocoding
      final fullAddress = '$address, $postalCode $city, $country';

      if (address.isEmpty || city.isEmpty) {
        debugPrint('Incomplete address for doctor $doctorId');
        return false;
      }

      debugPrint('Geocoding address: $fullAddress');

      // Geocode the address
      final locations = await locationFromAddress(fullAddress);

      if (locations.isEmpty) {
        debugPrint('No coordinates found for address: $fullAddress');
        return false;
      }

      final location = locations.first;

      // Update Firestore with new coordinates
      await _firestore.collection('doctors').doc(doctorId).update({
        'location.coordinates': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      });

      debugPrint(
        '✅ Updated coordinates for doctor $doctorId: ${location.latitude}, ${location.longitude}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error geocoding doctor $doctorId: $e');
      return false;
    }
  }

  /// Geocode all doctors' addresses (use with caution - can be rate limited)
  Future<Map<String, dynamic>> geocodeAllDoctors({
    int? limit,
    bool forceReGeocode = false,
  }) async {
    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;

    try {
      Query query = _firestore.collection('doctors');

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      debugPrint('Processing ${snapshot.docs.length} doctors...');

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final locationMap = data['location'] as Map<String, dynamic>?;

        if (locationMap == null) {
          skippedCount++;
          continue;
        }

        // Check if coordinates already exist and are not default
        final coordsMap = locationMap['coordinates'] as Map<String, dynamic>?;
        final existingLat = (coordsMap?['latitude'] ?? 0.0) as num;
        final existingLng = (coordsMap?['longitude'] ?? 0.0) as num;

        if (!forceReGeocode && existingLat != 0.0 && existingLng != 0.0) {
          skippedCount++;
          continue;
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));

        final success = await geocodeDoctorAddress(
          doc.id,
          forceReGeocode: forceReGeocode,
        );
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      return {
        'success': successCount,
        'failed': failCount,
        'skipped': skippedCount,
        'total': snapshot.docs.length,
      };
    } catch (e) {
      debugPrint('Error in batch geocoding: $e');
      return {
        'success': successCount,
        'failed': failCount,
        'skipped': skippedCount,
        'error': e.toString(),
      };
    }
  }

  /// Manually set coordinates for a doctor
  Future<void> setDoctorCoordinates(
    String doctorId,
    double latitude,
    double longitude,
  ) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'location.coordinates': {'latitude': latitude, 'longitude': longitude},
    });
    debugPrint(
      '✅ Manually set coordinates for doctor $doctorId: $latitude, $longitude',
    );
  }

  /// Verify if an address can be geocoded
  Future<Map<String, dynamic>?> testGeocoding(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      final location = locations.first;
      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp?.toString(),
      };
    } catch (e) {
      debugPrint('Test geocoding failed: $e');
      return null;
    }
  }
}
