import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/doctor.dart';
import '../domain/entities/specialty_entity.dart';
import '../domain/entities/search_filters.dart';

class DoctorSearchDatasource {
  final FirebaseFirestore _firestore;

  DoctorSearchDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Search doctors with filters and ranking (Stream for real-time updates)
  Stream<List<Doctor>> searchDoctorsStream(SearchFilters filters) async* {
    // Primary source: doctors collection (contains rich profile fields)
    Query<Map<String, dynamic>> query = _firestore.collection('doctors');

    // Apply hard filters
    if (filters.onlyAcceptingNewPatients) {
      query = query.where(
        'searchMetadata.isAcceptingNewPatients',
        isEqualTo: true,
      );
    }

    if (filters.onlyVerified) {
      query = query.where('searchMetadata.isVerified', isEqualTo: true);
    }

    if (filters.specialtyId != null) {
      query = query.where('specialty.id', isEqualTo: filters.specialtyId);
    }

    if (filters.city != null) {
      query = query.where('location.city', isEqualTo: filters.city);
    }

    // Consultation mode filter
    if (filters.consultationModes.contains(ConsultationMode.video)) {
      query = query.where('consultationModes.video', isEqualTo: true);
    } else if (filters.consultationModes.contains(ConsultationMode.inPerson)) {
      query = query.where('consultationModes.inPerson', isEqualTo: true);
    }

    // Listen to real-time updates
    await for (var snapshot in query.limit(100).snapshots()) {
      // Convert to Doctor entities
      List<Doctor> doctors = snapshot.docs
          .map((doc) => _doctorFromFirestore(doc.data(), doc.id))
          .toList();

      // Apply client-side filters
      doctors = _applyClientFilters(doctors, filters);

      // Calculate ranking scores and sort
      doctors = _rankAndSortDoctors(doctors, filters);

      yield doctors;
    }
  }

  /// Search doctors with filters and ranking
  Future<List<Doctor>> searchDoctors(SearchFilters filters) async {
    // Primary source: doctors collection (contains rich profile fields)
    Query<Map<String, dynamic>> query = _firestore.collection('doctors');

    // Apply hard filters
    if (filters.onlyAcceptingNewPatients) {
      query = query.where(
        'searchMetadata.isAcceptingNewPatients',
        isEqualTo: true,
      );
    }

    if (filters.onlyVerified) {
      query = query.where('searchMetadata.isVerified', isEqualTo: true);
    }

    if (filters.specialtyId != null) {
      query = query.where('specialty.id', isEqualTo: filters.specialtyId);
    }

    if (filters.city != null) {
      query = query.where('location.city', isEqualTo: filters.city);
    }

    // Consultation mode filter
    if (filters.consultationModes.contains(ConsultationMode.video)) {
      query = query.where('consultationModes.video', isEqualTo: true);
    } else if (filters.consultationModes.contains(ConsultationMode.inPerson)) {
      query = query.where('consultationModes.inPerson', isEqualTo: true);
    }

    // Execute query
    final snapshot = await query.limit(100).get();

    // Convert to Doctor entities
    List<Doctor> doctors = snapshot.docs
        .map((doc) => _doctorFromFirestore(doc.data(), doc.id))
        .toList();

    // Apply client-side filters
    doctors = _applyClientFilters(doctors, filters);

    // Calculate ranking scores and sort
    doctors = _rankAndSortDoctors(doctors, filters);

    return doctors;
  }

  /// Get all specialties
  Future<List<SpecialtyEntity>> getSpecialties() async {
    final snapshot = await _firestore
        .collection('specialties')
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();

    return snapshot.docs
        .map((doc) => _specialtyFromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get popular specialties (top 8)
  Future<List<SpecialtyEntity>> getPopularSpecialties() async {
    final snapshot = await _firestore
        .collection('specialties')
        .where('isActive', isEqualTo: true)
        .orderBy('statistics.popularityRank')
        .limit(8)
        .get();

    return snapshot.docs
        .map((doc) => _specialtyFromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Get doctor by ID
  Future<Doctor?> getDoctorById(String doctorId) async {
    final doc = await _firestore.collection('doctors').doc(doctorId).get();

    if (!doc.exists) return null;

    return _doctorFromFirestore(doc.data()!, doc.id);
  }

  /// Apply client-side filters that can't be done in Firestore
  List<Doctor> _applyClientFilters(
    List<Doctor> doctors,
    SearchFilters filters,
  ) {
    return doctors.where((doctor) {
      // Distance filter
      if (filters.maxDistance != null &&
          filters.userLatitude != null &&
          filters.userLongitude != null) {
        final distance = doctor.calculateDistance(
          filters.userLatitude!,
          filters.userLongitude!,
        );
        if (distance > filters.maxDistance!) return false;
      }

      // Rating filter
      if (filters.minRating != null) {
        if (doctor.ratings.average < filters.minRating!) return false;
      }

      // Price filter
      if (filters.maxPrice != null) {
        final price = filters.consultationModes.contains(ConsultationMode.video)
            ? doctor.pricing.videoFee
            : doctor.pricing.inPersonFee;
        if (price > filters.maxPrice!) return false;
      }

      // Language filter
      if (filters.languages.isNotEmpty) {
        final hasLanguage = filters.languages.any(
          (lang) => doctor.credentials.languages.contains(lang),
        );
        if (!hasLanguage) return false;
      }

      // Date availability filter
      if (filters.availableFrom != null) {
        if (doctor.availability.nextAvailableSlot == null) return false;
        if (doctor.availability.nextAvailableSlot!.isAfter(
          filters.availableFrom!,
        )) {
          if (filters.availableTo != null) {
            if (doctor.availability.nextAvailableSlot!.isAfter(
              filters.availableTo!,
            )) {
              return false;
            }
          }
        }
      }

      // Search query (name, specialty, city, keywords)
      if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
        final query = filters.searchQuery!.toLowerCase();
        final matchesName = doctor.fullName.toLowerCase().contains(query);
        final matchesSpecialty = doctor.specialty.name.toLowerCase().contains(
          query,
        );
        final matchesCity = doctor.location.city.toLowerCase().contains(query);
        if (!matchesName && !matchesSpecialty && !matchesCity) return false;
      }

      return true;
    }).toList();
  }

  /// Rank and sort doctors based on relevance score
  List<Doctor> _rankAndSortDoctors(
    List<Doctor> doctors,
    SearchFilters filters,
  ) {
    // Calculate score for each doctor
    final doctorsWithScores = doctors.map((doctor) {
      final score = _calculateRelevanceScore(doctor, filters);
      return {'doctor': doctor, 'score': score};
    }).toList();

    // Sort based on selected sort option
    switch (filters.sortBy) {
      case SortBy.relevance:
        doctorsWithScores.sort(
          (a, b) => (b['score'] as double).compareTo(a['score'] as double),
        );
        break;

      case SortBy.distance:
        if (filters.userLatitude != null && filters.userLongitude != null) {
          doctorsWithScores.sort((a, b) {
            final distA = (a['doctor'] as Doctor).calculateDistance(
              filters.userLatitude!,
              filters.userLongitude!,
            );
            final distB = (b['doctor'] as Doctor).calculateDistance(
              filters.userLatitude!,
              filters.userLongitude!,
            );
            return distA.compareTo(distB);
          });
        }
        break;

      case SortBy.rating:
        doctorsWithScores.sort(
          (a, b) => (b['doctor'] as Doctor).ratings.average.compareTo(
            (a['doctor'] as Doctor).ratings.average,
          ),
        );
        break;

      case SortBy.availability:
        doctorsWithScores.sort((a, b) {
          final dateA = (a['doctor'] as Doctor).availability.nextAvailableSlot;
          final dateB = (b['doctor'] as Doctor).availability.nextAvailableSlot;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateA.compareTo(dateB);
        });
        break;

      case SortBy.price:
        doctorsWithScores.sort((a, b) {
          final priceA =
              filters.consultationModes.contains(ConsultationMode.video)
              ? (a['doctor'] as Doctor).pricing.videoFee
              : (a['doctor'] as Doctor).pricing.inPersonFee;
          final priceB =
              filters.consultationModes.contains(ConsultationMode.video)
              ? (b['doctor'] as Doctor).pricing.videoFee
              : (b['doctor'] as Doctor).pricing.inPersonFee;
          return priceA.compareTo(priceB);
        });
        break;
    }

    return doctorsWithScores.map((item) => item['doctor'] as Doctor).toList();
  }

  /// Calculate relevance score for ranking (0-100)
  double _calculateRelevanceScore(Doctor doctor, SearchFilters filters) {
    double score = 0;

    // 1. Specialty Match (40 points)
    if (filters.specialtyId != null) {
      if (doctor.specialty.id == filters.specialtyId) {
        score += 40;
      }
    } else {
      score += 20; // Partial score if no specialty filter
    }

    // 2. Proximity Score (25 points)
    if (filters.userLatitude != null && filters.userLongitude != null) {
      final distance = doctor.calculateDistance(
        filters.userLatitude!,
        filters.userLongitude!,
      );

      if (distance < 2) {
        score += 25;
      } else if (distance < 5) {
        score += 20;
      } else if (distance < 10) {
        score += 15;
      } else if (distance < 20) {
        score += 10;
      } else if (distance < 50) {
        score += 5;
      }
    } else {
      score += 12; // Default if no location
    }

    // 3. Availability Score (15 points)
    if (doctor.availability.nextAvailableSlot != null) {
      final daysUntilAvailable = doctor.availability.nextAvailableSlot!
          .difference(DateTime.now())
          .inDays;

      if (daysUntilAvailable == 0) {
        score += 15;
      } else if (daysUntilAvailable <= 7) {
        score += 12;
      } else if (daysUntilAvailable <= 14) {
        score += 8;
      } else if (daysUntilAvailable <= 30) {
        score += 5;
      } else {
        score += 2;
      }
    }

    // 4. Rating Score (10 points)
    if (doctor.ratings.average >= 4.5) {
      score += 10;
    } else if (doctor.ratings.average >= 4.0) {
      score += 8;
    } else if (doctor.ratings.average >= 3.5) {
      score += 6;
    } else if (doctor.ratings.average >= 3.0) {
      score += 4;
    } else {
      score += 2;
    }

    // 5. Popularity Score (5 points)
    score += (doctor.searchMetadata.popularityScore / 100) * 5;

    // 6. Verification Bonus (5 points)
    if (doctor.searchMetadata.isVerified) {
      score += 3;
    }
    if (doctor.searchMetadata.isAcceptingNewPatients) {
      score += 2;
    }

    return min(100, score);
  }

  // Firestore converters
  Doctor _doctorFromFirestore(Map<String, dynamic> data, String id) {
    Map<String, dynamic> _map(String key) {
      final value = data[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return <String, dynamic>{};
    }

    Map<String, dynamic> _subMap(Map<String, dynamic> parent, String key) {
      final value = parent[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return <String, dynamic>{};
    }

    DateTime _tsOrNow(dynamic ts) {
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      return DateTime.now();
    }

    double _toDouble(dynamic v, {double fallback = 0}) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? fallback;
      return fallback;
    }

    // Support both legacy schema and the current doctors collection schema.
    final specialtyMap = _map('specialty');
    final credentialsMap = _map('credentials');
    final locationMap = _map('location');
    final coordinatesMap = _subMap(locationMap, 'coordinates');
    final consultationModesMap = _map('consultationModes');
    final pricingMap = _map('pricing');
    final availabilityMap = _map('availability');
    final ratingsMap = _map('ratings');
    final statisticsMap = _map('statistics');
    final profileMap = _map('profile');
    final searchMetadataMap = _map('searchMetadata');
    final clinicMap = _map('clinic');
    final contactsMap = _map('contacts');
    final photoMap = _map('photo');

    String _firstName() {
      final full =
          (data['fullName'] ?? contactsMap['fullName'] ?? data['name'] ?? '')
              .toString()
              .trim();
      if (full.isEmpty) return '';
      final parts = full.split(' ');
      return parts.isNotEmpty ? parts.first : full;
    }

    String _lastName() {
      final full =
          (data['fullName'] ?? contactsMap['fullName'] ?? data['name'] ?? '')
              .toString()
              .trim();
      if (full.isEmpty) return '';
      final parts = full.split(' ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' ');
      }
      return '';
    }

    // Fallback specialty when no nested map is present
    final specialtyId =
        specialtyMap['id']?.toString() ?? data['specialtyId']?.toString() ?? '';
    final specialtyName =
        specialtyMap['name']?.toString() ??
        data['specialtyName']?.toString() ??
        '';

    return Doctor(
      id: id,
      firstName: data['firstName']?.toString().trim().isNotEmpty == true
          ? data['firstName'].toString()
          : _firstName(),
      lastName: data['lastName']?.toString() ?? _lastName(),
      email:
          data['email']?.toString() ?? contactsMap['email']?.toString() ?? '',
      phone:
          data['phone']?.toString() ?? contactsMap['phone']?.toString() ?? '',
      specialty: Specialty(
        id: specialtyId,
        name: specialtyName,
        category: specialtyMap['category']?.toString() ?? '',
        icon: specialtyMap['icon'],
        color: specialtyMap['color'],
      ),
      credentials: Credentials(
        title:
            credentialsMap['title']?.toString() ??
            (data['title']?.toString() ?? 'Dr.'),
        rpps: credentialsMap['rpps']?.toString() ?? '',
        conventionSector: credentialsMap['conventionSector'] ?? 1,
        languages: List<String>.from(
          credentialsMap['languages'] ?? data['languages'] ?? ['fr'],
        ),
      ),
      location: DoctorLocation(
        address:
            locationMap['address']?.toString() ??
            clinicMap['addressLine']?.toString() ??
            '',
        city:
            locationMap['city']?.toString() ??
            clinicMap['city']?.toString() ??
            '',
        postalCode:
            locationMap['postalCode']?.toString() ??
            clinicMap['postalCode']?.toString() ??
            '',
        country: locationMap['country']?.toString() ?? 'France',
        coordinates: Coordinates(
          latitude: _toDouble(coordinatesMap['latitude']),
          longitude: _toDouble(coordinatesMap['longitude']),
        ),
      ),
      consultationModes: ConsultationModes(
        inPerson:
            consultationModesMap['inPerson'] ?? clinicMap['inPerson'] ?? true,
        video: consultationModesMap['video'] ?? clinicMap['video'] ?? false,
        homeVisit: consultationModesMap['homeVisit'] ?? false,
      ),
      pricing: Pricing(
        inPersonFee: _toDouble(
          pricingMap['inPersonFee'] ?? pricingMap['inPersonTND'],
          fallback: 50.0,
        ),
        videoFee: _toDouble(
          pricingMap['videoFee'] ?? pricingMap['videoTND'],
          fallback: 40.0,
        ),
        acceptsCarteVitale: pricingMap['acceptsCarteVitale'] ?? true,
        acceptsThirdPartyPayment:
            pricingMap['acceptsThirdPartyPayment'] ?? false,
      ),
      availability: Availability(
        nextAvailableSlot: availabilityMap['nextAvailableSlot'] is Timestamp
            ? (availabilityMap['nextAvailableSlot'] as Timestamp).toDate()
            : availabilityMap['nextAvailableSlot'] is DateTime
            ? availabilityMap['nextAvailableSlot'] as DateTime
            : null,
        schedule: {}, // Simplified for now
        averageResponseTime: availabilityMap['averageResponseTime'] ?? 120,
      ),
      ratings: Ratings(
        average: _toDouble(data['averageRating'] ?? ratingsMap['average']),
        count: data['reviewCount'] ?? ratingsMap['count'] ?? 0,
        breakdown: Map<int, int>.from(ratingsMap['breakdown'] ?? {}),
      ),
      statistics: Statistics(
        totalAppointments: statisticsMap['totalAppointments'] ?? 0,
        completedAppointments: statisticsMap['completedAppointments'] ?? 0,
        cancelledByDoctor: statisticsMap['cancelledByDoctor'] ?? 0,
        experienceYears: statisticsMap['experienceYears'] ?? 0,
      ),
      profile: DoctorProfile(
        bio: profileMap['bio']?.toString() ?? data['bio']?.toString() ?? '',
        photoUrl: profileMap['photoUrl'] ?? photoMap['url'],
        education: List<String>.from(profileMap['education'] ?? []),
        certifications: List<String>.from(profileMap['certifications'] ?? []),
      ),
      searchMetadata: SearchMetadata(
        isActive: searchMetadataMap['isActive'] ?? true,
        isAcceptingNewPatients:
            searchMetadataMap['isAcceptingNewPatients'] ??
            data['acceptingNewPatients'] ??
            true,
        isVerified: searchMetadataMap['isVerified'] ?? false,
        popularityScore: _toDouble(
          searchMetadataMap['popularityScore'],
          fallback: 50.0,
        ),
        lastUpdated: _tsOrNow(searchMetadataMap['lastUpdated']),
      ),
      createdAt: _tsOrNow(data['createdAt']),
      updatedAt: _tsOrNow(data['updatedAt']),
    );
  }

  SpecialtyEntity _specialtyFromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return SpecialtyEntity(
      id: id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'],
      nameAr: data['nameAr'],
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'medical',
      color: data['color'] ?? '#4FC3F7',
      gradient: List<String>.from(data['gradient'] ?? ['#4FC3F7', '#00BFA5']),
      keywords: List<String>.from(data['keywords'] ?? []),
      commonConditions: List<String>.from(data['commonConditions'] ?? []),
      statistics: SpecialtyStatistics(
        doctorCount: data['statistics']['doctorCount'] ?? 0,
        averageWaitTime: data['statistics']['averageWaitTime'] ?? 7,
        popularityRank: data['statistics']['popularityRank'] ?? 99,
      ),
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 999,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
