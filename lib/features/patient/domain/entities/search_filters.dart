import 'package:equatable/equatable.dart';

enum ConsultationMode { inPerson, video, homeVisit }

enum SortBy { relevance, distance, rating, availability, price }

class SearchFilters extends Equatable {
  final String? searchQuery;
  final String? specialtyId;
  final String? city;
  final double? maxDistance; // in kilometers
  final double? userLatitude;
  final double? userLongitude;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final Set<ConsultationMode> consultationModes;
  final bool onlyAcceptingNewPatients;
  final bool onlyVerified;
  final double? minRating;
  final double? maxPrice;
  final List<String> languages;
  final SortBy sortBy;

  const SearchFilters({
    this.searchQuery,
    this.specialtyId,
    this.city,
    this.maxDistance,
    this.userLatitude,
    this.userLongitude,
    this.availableFrom,
    this.availableTo,
    this.consultationModes = const {},
    this.onlyAcceptingNewPatients = false,
    this.onlyVerified = false,
    this.minRating,
    this.maxPrice,
    this.languages = const [],
    this.sortBy = SortBy.relevance,
  });

  bool get hasLocationFilter =>
      city != null ||
      (maxDistance != null && userLatitude != null && userLongitude != null);

  bool get hasAnyFilter =>
      searchQuery != null ||
      specialtyId != null ||
      hasLocationFilter ||
      availableFrom != null ||
      consultationModes.isNotEmpty ||
      onlyAcceptingNewPatients ||
      onlyVerified ||
      minRating != null ||
      maxPrice != null ||
      languages.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (specialtyId != null) count++;
    if (hasLocationFilter) count++;
    if (availableFrom != null) count++;
    if (consultationModes.isNotEmpty) count++;
    if (onlyAcceptingNewPatients) count++;
    if (onlyVerified) count++;
    if (minRating != null) count++;
    if (maxPrice != null) count++;
    if (languages.isNotEmpty) count++;
    return count;
  }

  SearchFilters copyWith({
    String? searchQuery,
    String? specialtyId,
    String? city,
    double? maxDistance,
    double? userLatitude,
    double? userLongitude,
    DateTime? availableFrom,
    DateTime? availableTo,
    Set<ConsultationMode>? consultationModes,
    bool? onlyAcceptingNewPatients,
    bool? onlyVerified,
    double? minRating,
    double? maxPrice,
    List<String>? languages,
    SortBy? sortBy,
  }) {
    return SearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      specialtyId: specialtyId ?? this.specialtyId,
      city: city ?? this.city,
      maxDistance: maxDistance ?? this.maxDistance,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      consultationModes: consultationModes ?? this.consultationModes,
      onlyAcceptingNewPatients:
          onlyAcceptingNewPatients ?? this.onlyAcceptingNewPatients,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      languages: languages ?? this.languages,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  SearchFilters clearFilter(String filterKey) {
    switch (filterKey) {
      case 'specialty':
        return copyWith(specialtyId: '');
      case 'location':
        return copyWith(
          city: '',
          maxDistance: 0,
          userLatitude: 0,
          userLongitude: 0,
        );
      case 'date':
        return copyWith(
          availableFrom: DateTime(1900),
          availableTo: DateTime(1900),
        );
      case 'mode':
        return copyWith(consultationModes: {});
      case 'newPatients':
        return copyWith(onlyAcceptingNewPatients: false);
      case 'verified':
        return copyWith(onlyVerified: false);
      case 'rating':
        return copyWith(minRating: 0);
      case 'price':
        return copyWith(maxPrice: 0);
      case 'language':
        return copyWith(languages: []);
      default:
        return this;
    }
  }

  SearchFilters clearAll() {
    return const SearchFilters();
  }

  @override
  List<Object?> get props => [
    searchQuery,
    specialtyId,
    city,
    maxDistance,
    userLatitude,
    userLongitude,
    availableFrom,
    availableTo,
    consultationModes,
    onlyAcceptingNewPatients,
    onlyVerified,
    minRating,
    maxPrice,
    languages,
    sortBy,
  ];
}
