import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfileModel {
  final String uid;
  final String fullName;
  final String? bio;
  final String specialtyId;
  final String specialtyName;
  final String? requestedSpecialtyId;
  final ContactsModel contacts;
  final ClinicModel clinic;
  final ConsultationModesModel consultationModes;
  final PricingModel pricing;
  final List<String> languages;
  final bool acceptingNewPatients;
  final PhotoModel? photo;
  final VisibilityModel visibility;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DoctorProfileModel({
    required this.uid,
    required this.fullName,
    this.bio,
    required this.specialtyId,
    required this.specialtyName,
    this.requestedSpecialtyId,
    required this.contacts,
    required this.clinic,
    required this.consultationModes,
    required this.pricing,
    required this.languages,
    required this.acceptingNewPatients,
    this.photo,
    required this.visibility,
    this.createdAt,
    this.updatedAt,
  });

  factory DoctorProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return DoctorProfileModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      bio: map['bio'],
      specialtyId: map['specialtyId'] ?? '',
      specialtyName: map['specialtyName'] ?? '',
      requestedSpecialtyId: map['requestedSpecialtyId'],
      contacts: ContactsModel.fromMap(map['contacts'] ?? {}),
      clinic: ClinicModel.fromMap(map['clinic'] ?? {}),
      consultationModes: ConsultationModesModel.fromMap(
        map['consultationModes'] ?? {},
      ),
      pricing: PricingModel.fromMap(map['pricing'] ?? {}),
      languages: List<String>.from(map['languages'] ?? []),
      acceptingNewPatients: map['acceptingNewPatients'] ?? true,
      photo: map['photo'] != null ? PhotoModel.fromMap(map['photo']) : null,
      visibility: VisibilityModel.fromMap(map['visibility'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap({bool includeAdminOnly = false}) {
    return {
      'uid': uid,
      'fullName': fullName,
      'bio': bio,
      'specialtyId': specialtyId,
      'specialtyName': specialtyName,
      'requestedSpecialtyId': requestedSpecialtyId,
      'contacts': contacts.toMap(),
      'clinic': clinic.toMap(),
      'consultationModes': consultationModes.toMap(),
      'pricing': pricing.toMap(),
      'languages': languages,
      'acceptingNewPatients': acceptingNewPatients,
      'photo': photo?.toMap(),
      'visibility': visibility.toMap(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}

class ContactsModel {
  final String phone;
  final String email;

  ContactsModel({required this.phone, required this.email});

  factory ContactsModel.fromMap(Map<String, dynamic> map) {
    return ContactsModel(phone: map['phone'] ?? '', email: map['email'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'phone': phone, 'email': email};
  }
}

class ClinicModel {
  final String? cabinetNumber;
  final String addressLine;
  final String city;
  final String postalCode;
  final GeoModel? geo;

  ClinicModel({
    this.cabinetNumber,
    required this.addressLine,
    required this.city,
    required this.postalCode,
    this.geo,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      cabinetNumber: map['cabinetNumber'],
      addressLine: map['addressLine'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      geo: map['geo'] != null ? GeoModel.fromMap(map['geo']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cabinetNumber': cabinetNumber,
      'addressLine': addressLine,
      'city': city,
      'postalCode': postalCode,
      'geo': geo?.toMap(),
    };
  }
}

class GeoModel {
  final double latitude;
  final double longitude;

  GeoModel({required this.latitude, required this.longitude});

  factory GeoModel.fromMap(Map<String, dynamic> map) {
    return GeoModel(
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class ConsultationModesModel {
  final bool inPerson;
  final bool video;

  ConsultationModesModel({required this.inPerson, required this.video});

  factory ConsultationModesModel.fromMap(Map<String, dynamic> map) {
    return ConsultationModesModel(
      inPerson: map['inPerson'] ?? true,
      video: map['video'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {'inPerson': inPerson, 'video': video};
  }
}

class PricingModel {
  final double? inPersonTND;
  final double? videoTND;
  final String currency;

  PricingModel({this.inPersonTND, this.videoTND, required this.currency});

  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      inPersonTND: map['inPersonTND']?.toDouble(),
      videoTND: map['videoTND']?.toDouble(),
      currency: map['currency'] ?? 'TND',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inPersonTND': inPersonTND,
      'videoTND': videoTND,
      'currency': currency,
    };
  }
}

class PhotoModel {
  final String storagePath;

  PhotoModel({required this.storagePath});

  factory PhotoModel.fromMap(Map<String, dynamic> map) {
    return PhotoModel(storagePath: map['storagePath'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {'storagePath': storagePath};
  }
}

class VisibilityModel {
  final bool isPublic;

  VisibilityModel({required this.isPublic});

  factory VisibilityModel.fromMap(Map<String, dynamic> map) {
    return VisibilityModel(isPublic: map['isPublic'] ?? true);
  }

  Map<String, dynamic> toMap() {
    return {'isPublic': isPublic};
  }
}
