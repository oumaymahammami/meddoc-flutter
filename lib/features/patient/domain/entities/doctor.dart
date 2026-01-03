import 'dart:math';
import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final Specialty specialty;
  final Credentials credentials;
  final DoctorLocation location;
  final ConsultationModes consultationModes;
  final Pricing pricing;
  final Availability availability;
  final Ratings ratings;
  final Statistics statistics;
  final DoctorProfile profile;
  final SearchMetadata searchMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Doctor({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.credentials,
    required this.location,
    required this.consultationModes,
    required this.pricing,
    required this.availability,
    required this.ratings,
    required this.statistics,
    required this.profile,
    required this.searchMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$title $firstName $lastName';
  String get title => credentials.title;

  double calculateDistance(double userLat, double userLng) {
    return location.calculateDistance(userLat, userLng);
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    specialty,
    credentials,
    location,
    consultationModes,
    pricing,
    availability,
    ratings,
    statistics,
    profile,
    searchMetadata,
    createdAt,
    updatedAt,
  ];
}

class Specialty extends Equatable {
  final String id;
  final String name;
  final String category;
  final String? icon;
  final String? color;

  const Specialty({
    required this.id,
    required this.name,
    required this.category,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [id, name, category, icon, color];
}

class Credentials extends Equatable {
  final String title;
  final String rpps;
  final int conventionSector;
  final List<String> languages;

  const Credentials({
    required this.title,
    required this.rpps,
    required this.conventionSector,
    required this.languages,
  });

  @override
  List<Object?> get props => [title, rpps, conventionSector, languages];
}

class DoctorLocation extends Equatable {
  final String address;
  final String city;
  final String postalCode;
  final String country;
  final Coordinates coordinates;

  const DoctorLocation({
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.coordinates,
  });

  String get fullAddress => '$address, $postalCode $city';

  // Haversine formula for distance calculation
  double calculateDistance(double userLat, double userLng) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(userLat - coordinates.latitude);
    final dLng = _toRadians(userLng - coordinates.longitude);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(coordinates.latitude)) *
            cos(_toRadians(userLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    const pi = 3.141592653589793;
    return degrees * pi / 180;
  }

  @override
  List<Object?> get props => [address, city, postalCode, country, coordinates];
}

class Coordinates extends Equatable {
  final double latitude;
  final double longitude;

  const Coordinates({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class ConsultationModes extends Equatable {
  final bool inPerson;
  final bool video;
  final bool homeVisit;

  const ConsultationModes({
    required this.inPerson,
    required this.video,
    required this.homeVisit,
  });

  List<String> get availableModes {
    final modes = <String>[];
    if (inPerson) modes.add('Cabinet');
    if (video) modes.add('Visio');
    if (homeVisit) modes.add('Domicile');
    return modes;
  }

  @override
  List<Object?> get props => [inPerson, video, homeVisit];
}

class Pricing extends Equatable {
  final double inPersonFee;
  final double videoFee;
  final bool acceptsCarteVitale;
  final bool acceptsThirdPartyPayment;

  const Pricing({
    required this.inPersonFee,
    required this.videoFee,
    required this.acceptsCarteVitale,
    required this.acceptsThirdPartyPayment,
  });

  @override
  List<Object?> get props => [
    inPersonFee,
    videoFee,
    acceptsCarteVitale,
    acceptsThirdPartyPayment,
  ];
}

class Availability extends Equatable {
  final DateTime? nextAvailableSlot;
  final Map<String, List<TimeSlot>> schedule;
  final int averageResponseTime;

  const Availability({
    this.nextAvailableSlot,
    required this.schedule,
    required this.averageResponseTime,
  });

  String get nextAvailableText {
    if (nextAvailableSlot == null) return 'Non disponible';

    final now = DateTime.now();
    final difference = nextAvailableSlot!.difference(now);

    if (difference.inHours < 24) return 'Aujourd\'hui';
    if (difference.inDays < 7) return 'Cette semaine';
    if (difference.inDays < 14) return 'Prochaine semaine';
    return 'Dans ${difference.inDays} jours';
  }

  @override
  List<Object?> get props => [nextAvailableSlot, schedule, averageResponseTime];
}

class TimeSlot extends Equatable {
  final String start;
  final String end;

  const TimeSlot({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}

class Ratings extends Equatable {
  final double average;
  final int count;
  final Map<int, int> breakdown;

  const Ratings({
    required this.average,
    required this.count,
    required this.breakdown,
  });

  @override
  List<Object?> get props => [average, count, breakdown];
}

class Statistics extends Equatable {
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledByDoctor;
  final int experienceYears;

  const Statistics({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledByDoctor,
    required this.experienceYears,
  });

  double get completionRate =>
      totalAppointments > 0 ? (completedAppointments / totalAppointments) : 0;

  @override
  List<Object?> get props => [
    totalAppointments,
    completedAppointments,
    cancelledByDoctor,
    experienceYears,
  ];
}

class DoctorProfile extends Equatable {
  final String bio;
  final String? photoUrl;
  final List<String> education;
  final List<String> certifications;

  const DoctorProfile({
    required this.bio,
    this.photoUrl,
    required this.education,
    required this.certifications,
  });

  @override
  List<Object?> get props => [bio, photoUrl, education, certifications];
}

class SearchMetadata extends Equatable {
  final bool isActive;
  final bool isAcceptingNewPatients;
  final bool isVerified;
  final double popularityScore;
  final DateTime lastUpdated;

  const SearchMetadata({
    required this.isActive,
    required this.isAcceptingNewPatients,
    required this.isVerified,
    required this.popularityScore,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    isActive,
    isAcceptingNewPatients,
    isVerified,
    popularityScore,
    lastUpdated,
  ];
}
