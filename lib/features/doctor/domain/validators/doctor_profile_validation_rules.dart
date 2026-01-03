import 'package:equatable/equatable.dart';

/// Validation result with field-specific errors
class ValidationResult extends Equatable {
  final bool isValid;
  final List<FieldError> errors;

  const ValidationResult({required this.isValid, required this.errors});

  @override
  List<Object?> get props => [isValid, errors];
}

/// Individual field validation error
class FieldError extends Equatable {
  final String fieldName;
  final String message;

  const FieldError({required this.fieldName, required this.message});

  @override
  List<Object?> get props => [fieldName, message];
}

/// Complete doctor profile validation rules
class DoctorProfileValidationRules {
  // Field length constraints
  static const int minFullNameLength = 2;
  static const int maxFullNameLength = 100;
  static const int minBioLength = 10;
  static const int maxBioLength = 500;

  // Contact constraints
  static const int minPhoneLength = 8;
  static const int maxPhoneLength = 20;

  // Clinic constraints
  static const int minAddressLength = 5;
  static const int maxAddressLength = 200;
  static const int minCityLength = 2;
  static const int maxCityLength = 50;

  // Pricing constraints
  static const double minPrice = 0.0;
  static const double maxPrice = 10000.0;

  // Geographic constraints
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  /// Validate complete doctor profile for completion
  /// Required fields MUST be present and valid
  static ValidationResult validateProfileCompletion({
    required String fullName,
    required String? specialtyId,
    required String? clinicCity,
    required String? clinicAddressLine,
    required bool inPersonMode,
    required bool videoMode,
    required double? inPersonPrice,
    required double? videoPrice,
    required String? phone,
    required String? email,
  }) {
    final errors = <FieldError>[];

    // Validate fullName (REQUIRED)
    if (fullName.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'fullName',
          message: 'Full name is required',
        ),
      );
    } else if (fullName.length < minFullNameLength) {
      errors.add(
        FieldError(
          fieldName: 'fullName',
          message: 'Full name must be at least $minFullNameLength characters',
        ),
      );
    } else if (fullName.length > maxFullNameLength) {
      errors.add(
        FieldError(
          fieldName: 'fullName',
          message: 'Full name cannot exceed $maxFullNameLength characters',
        ),
      );
    }

    // Validate specialtyId (REQUIRED)
    if (specialtyId == null || specialtyId.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'specialtyId',
          message: 'Specialty is required',
        ),
      );
    }

    // Validate clinic city (REQUIRED)
    if (clinicCity == null || clinicCity.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'clinic.city',
          message: 'Clinic city is required',
        ),
      );
    } else if (clinicCity.length < minCityLength) {
      errors.add(
        FieldError(
          fieldName: 'clinic.city',
          message: 'City name must be at least $minCityLength characters',
        ),
      );
    } else if (clinicCity.length > maxCityLength) {
      errors.add(
        FieldError(
          fieldName: 'clinic.city',
          message: 'City name cannot exceed $maxCityLength characters',
        ),
      );
    }

    // Validate clinic address (REQUIRED)
    if (clinicAddressLine == null || clinicAddressLine.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'clinic.addressLine',
          message: 'Clinic address is required',
        ),
      );
    } else if (clinicAddressLine.length < minAddressLength) {
      errors.add(
        FieldError(
          fieldName: 'clinic.addressLine',
          message: 'Address must be at least $minAddressLength characters',
        ),
      );
    } else if (clinicAddressLine.length > maxAddressLength) {
      errors.add(
        FieldError(
          fieldName: 'clinic.addressLine',
          message: 'Address cannot exceed $maxAddressLength characters',
        ),
      );
    }

    // Validate at least one consultation mode (REQUIRED)
    if (!inPersonMode && !videoMode) {
      errors.add(
        const FieldError(
          fieldName: 'consultationModes',
          message: 'Select at least one consultation mode (in-person or video)',
        ),
      );
    }

    // Validate pricing for enabled modes (REQUIRED)
    if (inPersonMode) {
      if (inPersonPrice == null || inPersonPrice <= minPrice) {
        errors.add(
          const FieldError(
            fieldName: 'pricing.inPersonTND',
            message: 'In-person price is required and must be greater than 0',
          ),
        );
      } else if (inPersonPrice > maxPrice) {
        errors.add(
          FieldError(
            fieldName: 'pricing.inPersonTND',
            message: 'Price cannot exceed $maxPrice TND',
          ),
        );
      }
    }

    if (videoMode) {
      if (videoPrice == null || videoPrice <= minPrice) {
        errors.add(
          const FieldError(
            fieldName: 'pricing.videoTND',
            message:
                'Video consultation price is required and must be greater than 0',
          ),
        );
      } else if (videoPrice > maxPrice) {
        errors.add(
          FieldError(
            fieldName: 'pricing.videoTND',
            message: 'Price cannot exceed $maxPrice TND',
          ),
        );
      }
    }

    // Validate phone (REQUIRED)
    if (phone == null || phone.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'contacts.phone',
          message: 'Phone number is required',
        ),
      );
    } else if (!isValidPhoneNumber(phone)) {
      errors.add(
        const FieldError(
          fieldName: 'contacts.phone',
          message: 'Phone number format is invalid (e.g., +216 21 123 456)',
        ),
      );
    }

    // Validate email (REQUIRED)
    if (email == null || email.isEmpty) {
      errors.add(
        const FieldError(
          fieldName: 'contacts.email',
          message: 'Email address is required',
        ),
      );
    } else if (!isValidEmail(email)) {
      errors.add(
        const FieldError(
          fieldName: 'contacts.email',
          message: 'Email format is invalid',
        ),
      );
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Validate phone number (E.164 format or lenient)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;

    // Remove common formatting characters
    final cleaned = phone.replaceAll(RegExp(r'[\s\-().]'), '');

    // Must start with + or be all digits of reasonable length
    if (!cleaned.startsWith('+') && !RegExp(r'^\d{8,20}$').hasMatch(cleaned)) {
      return false;
    }

    // E.164 format: +[1-9]\d{1,14}
    if (cleaned.startsWith('+')) {
      return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(cleaned);
    }

    return true;
  }

  /// Validate email (RFC 5322 simplified)
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&' +
          "'" +
          r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    return emailRegex.hasMatch(email);
  }

  /// Validate single field (for real-time validation)
  static String? validateField(String fieldName, String? value) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    switch (fieldName) {
      case 'fullName':
        if (value.length < minFullNameLength) {
          return 'Name must be at least $minFullNameLength characters';
        }
        if (value.length > maxFullNameLength) {
          return 'Name cannot exceed $maxFullNameLength characters';
        }
        return null;

      case 'bio':
        if (value.length < minBioLength) {
          return 'Bio must be at least $minBioLength characters';
        }
        if (value.length > maxBioLength) {
          return 'Bio cannot exceed $maxBioLength characters';
        }
        return null;

      case 'phone':
        if (!isValidPhoneNumber(value)) {
          return 'Invalid phone format (e.g., +216 21 123 456)';
        }
        return null;

      case 'email':
        if (!isValidEmail(value)) {
          return 'Invalid email format';
        }
        return null;

      case 'city':
        if (value.length < minCityLength) {
          return 'City must be at least $minCityLength characters';
        }
        if (value.length > maxCityLength) {
          return 'City cannot exceed $maxCityLength characters';
        }
        return null;

      case 'address':
        if (value.length < minAddressLength) {
          return 'Address must be at least $minAddressLength characters';
        }
        if (value.length > maxAddressLength) {
          return 'Address cannot exceed $maxAddressLength characters';
        }
        return null;

      default:
        return null;
    }
  }

  /// Validate price
  static bool isValidPrice(double? price) {
    if (price == null) return false;
    return price > minPrice && price <= maxPrice;
  }

  /// Validate coordinates
  static bool isValidLatitude(double? lat) {
    if (lat == null) return false;
    return lat >= minLatitude && lat <= maxLatitude;
  }

  static bool isValidLongitude(double? lng) {
    if (lng == null) return false;
    return lng >= minLongitude && lng <= maxLongitude;
  }

  /// Get user-friendly error message
  static String getErrorMessage(FieldError error) {
    return error.message;
  }
}
