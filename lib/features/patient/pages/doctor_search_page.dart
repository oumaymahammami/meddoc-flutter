import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/doctor_search_datasource.dart';
import '../domain/entities/doctor.dart';
import '../domain/entities/specialty_entity.dart';
import '../domain/entities/search_filters.dart';
import 'package:go_router/go_router.dart';

final _datasourceProvider = Provider((ref) => DoctorSearchDatasource());

final _specialtiesProvider = FutureProvider<List<SpecialtyEntity>>((ref) {
  final datasource = ref.watch(_datasourceProvider);
  return datasource.getPopularSpecialties();
});

// All specialties for filter sheet
final _allSpecialtiesProvider = FutureProvider<List<SpecialtyEntity>>((ref) {
  final datasource = ref.watch(_datasourceProvider);
  return datasource.getSpecialties();
});

// Cities list (in real app, fetch from Firestore or API)
final _citiesProvider = Provider<List<String>>((ref) {
  return [
    'Casablanca',
    'Rabat',
    'Marrakech',
    'Fès',
    'Tanger',
    'Agadir',
    'Meknès',
    'Oujda',
    'Kenitra',
    'Tétouan',
    'Salé',
    'Mohammedia',
    'El Jadida',
  ]..sort();
});

/// ✅ Premium colors for modern medical UI
const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE2E8F0);

const _primary = Color(0xFF2D9CDB);
const _primaryDark = Color(0xFF1B6CA8);

const _text = Color(0xFF0F172A);
const _subText = Color(0xFF475569);
const _muted = Color(0xFF94A3B8);

final _cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 18,
    offset: const Offset(0, 8),
  ),
];

class DoctorSearchPage extends ConsumerStatefulWidget {
  const DoctorSearchPage({super.key});

  @override
  ConsumerState<DoctorSearchPage> createState() => _DoctorSearchPageState();
}

class _DoctorSearchPageState extends ConsumerState<DoctorSearchPage> {
  final _searchController = TextEditingController();
  SearchFilters _filters = const SearchFilters();
  Stream<List<Doctor>>? _resultsStream;

  @override
  void initState() {
    super.initState();
    _resultsStream = _searchStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _updateFilters(_filters.copyWith(searchQuery: query));
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialFilters: _filters,
        onFiltersApplied: (filters) {
          _updateFilters(filters);
          Navigator.pop(context);
        },
      ),
    );
  }

  Stream<List<Doctor>> _searchStream() {
    final datasource = ref.read(_datasourceProvider);
    return datasource.searchDoctorsStream(_filters);
  }

  void _updateFilters(SearchFilters newFilters) {
    setState(() {
      _filters = newFilters;
      _resultsStream = _searchStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final specialtiesAsync = ref.watch(_specialtiesProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSearchAppBar(_filters),

          if (_filters.hasAnyFilter) _buildFilterChips(_filters),

          if (!_filters.hasAnyFilter && _filters.searchQuery == null)
            _buildPopularSpecialtiesSection(specialtiesAsync),

          _buildSearchResults(_filters),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  /// ✅ Modern gradient appbar + premium search field
  Widget _buildSearchAppBar(SearchFilters filters) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: _surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trouver un praticien",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Recherchez par spécialité, ville ou nom",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildSearchBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _performSearch,
        onChanged: _performSearch,
        style: const TextStyle(fontWeight: FontWeight.w700, color: _text),
        decoration: InputDecoration(
          hintText: "Spécialité, nom, symptôme...",
          hintStyle: const TextStyle(
            color: _muted,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(Icons.search, color: _primary),
          suffixIcon: IconButton(
            icon: Badge(
              isLabelVisible: _filters.activeFilterCount > 0,
              label: Text('${_filters.activeFilterCount}'),
              child: const Icon(Icons.tune_rounded, color: _primary),
            ),
            onPressed: _showFilterSheet,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  /// ✅ Premium filter chips bar
  Widget _buildFilterChips(SearchFilters filters) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (filters.specialtyId != null)
              _modernChip(
                "Spécialité",
                () => _updateFilters(filters.clearFilter('specialty')),
              ),

            if (filters.city != null)
              _modernChip(
                "Localisation",
                () => _updateFilters(filters.clearFilter('location')),
              ),

            if (filters.consultationModes.isNotEmpty)
              _modernChip(
                filters.consultationModes.contains(ConsultationMode.video)
                    ? "Visio"
                    : "Cabinet",
                () => _updateFilters(filters.clearFilter('mode')),
              ),

            if (filters.availableFrom != null)
              _modernChip(
                "Date",
                () => _updateFilters(filters.clearFilter('date')),
              ),

            if (filters.onlyVerified)
              _modernChip(
                "Vérifié",
                () => _updateFilters(filters.copyWith(onlyVerified: false)),
              ),

            _modernChip(
              "Tout effacer",
              () => _updateFilters(filters.clearAll()),
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _modernChip(
    String label,
    VoidCallback onDeleted, {
    bool isDanger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDanger
            ? Colors.red.withOpacity(0.10)
            : _primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDanger
              ? Colors.red.withOpacity(0.2)
              : _primary.withOpacity(0.18),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDanger ? Colors.red : _primaryDark,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 16,
              color: isDanger ? Colors.red : _primary,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Popular specialties grid modern cards
  Widget _buildPopularSpecialtiesSection(
    AsyncValue<List<SpecialtyEntity>> specialtiesAsync,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Spécialités populaires",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _text,
              ),
            ),
            const SizedBox(height: 14),
            specialtiesAsync.when(
              data: (specialties) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: specialties.length,
                itemBuilder: (context, index) {
                  final specialty = specialties[index];
                  return _buildSpecialtyCard(specialty);
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: _primary),
              ),
              error: (e, _) => Text("Erreur: $e"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard(SpecialtyEntity specialty) {
    return InkWell(
      onTap: () {
        _updateFilters(_filters.copyWith(specialtyId: specialty.id));
      },
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: _specialtyColors(specialty)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForSpecialty(specialty.icon),
                size: 38,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                specialty.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Search results list premium doctor cards
  Widget _buildSearchResults(SearchFilters filters) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Doctor>>(
        stream: _resultsStream,
        builder: (context, snapshot) {
          // Show loading only on first load
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: CircularProgressIndicator(color: _primary),
              ),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(child: Text('Erreur: ${snapshot.error}')),
            );
          }

          final doctors = snapshot.data ?? [];
          if (doctors.isEmpty) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Aucun praticien trouvé",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Essayez de modifier vos filtres",
                      style: TextStyle(color: _subText),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                ...doctors.map(
                  (doctor) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildDoctorCard(doctor, filters),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Call doctor's phone number
  static Future<void> _callPhone(
    BuildContext context,
    String phoneNumber,
  ) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le composeur téléphonique'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Widget _buildDoctorCard(Doctor doctor, SearchFilters filters) {
    final distance =
        filters.userLatitude != null && filters.userLongitude != null
        ? doctor.calculateDistance(
            filters.userLatitude!,
            filters.userLongitude!,
          )
        : null;

    final cityLine = [
      if (doctor.location.city.isNotEmpty) doctor.location.city,
      if (doctor.location.address.isNotEmpty) doctor.location.address,
    ].join(' • ');

    final priceLine = [
      'Cabinet: ${doctor.pricing.inPersonFee.toStringAsFixed(0)}€',
      'Visio: ${doctor.pricing.videoFee.toStringAsFixed(0)}€',
    ].join('   •   ');

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => context.push('/patient/doctor/${doctor.id}'),
      child: Ink(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border),
          boxShadow: _cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Avatar
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                  ),
                  image: doctor.profile.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(doctor.profile.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: doctor.profile.photoUrl == null
                    ? Center(
                        child: Text(
                          _initials(doctor),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              /// Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doctor.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _text,
                            ),
                          ),
                        ),
                        if (doctor.phone.isNotEmpty)
                          GestureDetector(
                            onTap: () => _callPhone(context, doctor.phone),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone,
                                color: _primary,
                                size: 16,
                              ),
                            ),
                          ),
                        if (doctor.phone.isNotEmpty) const SizedBox(width: 6),
                        if (doctor.searchMetadata.isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            color: _primary,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialty.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _subText,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (cityLine.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cityLine,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: _subText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${doctor.ratings.average.toStringAsFixed(1)} (${doctor.ratings.count})",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.pin_drop_outlined,
                            size: 16,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${distance.toStringAsFixed(1)} km",
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: _subText,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      priceLine,
                      style: const TextStyle(
                        fontSize: 12.3,
                        fontWeight: FontWeight.w900,
                        color: _primaryDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...doctor.consultationModes.availableModes.map(
                          (mode) => _miniBadge(
                            mode,
                            _primary.withOpacity(0.10),
                            _primaryDark,
                          ),
                        ),
                        _miniBadge(
                          doctor.availability.nextAvailableText,
                          Colors.purple.withOpacity(0.08),
                          Colors.purple.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.14)),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }

  /// Icons
  IconData _getIconForSpecialty(String icon) {
    switch (icon.toLowerCase()) {
      case 'cardiology':
        return Icons.favorite_rounded;
      case 'dental':
        return Icons.medical_services_rounded;
      case 'eye':
        return Icons.visibility_rounded;
      case 'pediatrics':
        return Icons.child_friendly_rounded;
      case 'dermatology':
        return Icons.face_retouching_natural;
      default:
        return Icons.local_hospital_rounded;
    }
  }

  String _initials(Doctor doctor) {
    final first = (doctor.firstName.isNotEmpty ? doctor.firstName[0] : '');
    final last = (doctor.lastName.isNotEmpty ? doctor.lastName[0] : '');
    final combo = '$first$last';
    return combo.isNotEmpty ? combo.toUpperCase() : '?';
  }

  List<Color> _specialtyColors(SpecialtyEntity specialty) {
    final raw = specialty.gradient;
    if (raw.length >= 2) {
      return raw
          .map((c) => Color(int.parse(c.replaceFirst('#', '0xFF'))))
          .toList();
    }
    if (raw.isNotEmpty) {
      final color = Color(int.parse(raw.first.replaceFirst('#', '0xFF')));
      return [color, color];
    }
    return const [_primary, _primaryDark];
  }
}

// =======================================================================
// FILTER SHEET — same logic but will modernize UI next if you want
// =======================================================================

class _FilterBottomSheet extends ConsumerStatefulWidget {
  final SearchFilters initialFilters;
  final Function(SearchFilters) onFiltersApplied;

  const _FilterBottomSheet({
    required this.initialFilters,
    required this.onFiltersApplied,
  });

  @override
  ConsumerState<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<_FilterBottomSheet> {
  late SearchFilters _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = widget.initialFilters;
  }

  void _applyFilters() {
    widget.onFiltersApplied(_localFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 42,
            height: 5,
            decoration: BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  "Filtres",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _text,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _localFilters = const SearchFilters());
                  },
                  child: const Text("Réinitialiser"),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSpecialtyFilter(),
                const SizedBox(height: 18),
                _buildCityFilter(),
                const SizedBox(height: 18),
                _buildConsultationModeFilter(),
                const SizedBox(height: 18),
                _buildDistanceFilter(),
                const SizedBox(height: 18),
                _buildDateFilter(),
                const SizedBox(height: 18),
                _buildToggleFilters(),
                const SizedBox(height: 18),
                _buildSortOptions(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Appliquer les filtres",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    final specialtiesAsync = ref.watch(_allSpecialtiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Spécialité",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        specialtiesAsync.when(
          data: (specialties) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _localFilters.specialtyId,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  hint: const Text('Toutes les spécialités'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Toutes les spécialités'),
                    ),
                    ...specialties.map((specialty) {
                      return DropdownMenuItem<String?>(
                        value: specialty.id,
                        child: Text(specialty.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      if (value == null) {
                        _localFilters = _localFilters.clearFilter('specialty');
                      } else {
                        _localFilters = _localFilters.copyWith(
                          specialtyId: value,
                        );
                      }
                    });
                  },
                ),
              ),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Erreur de chargement'),
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    final cities = ref.watch(_citiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ville",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _localFilters.city,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              hint: const Text('Toutes les villes'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Toutes les villes'),
                ),
                ...cities.map((city) {
                  return DropdownMenuItem<String?>(
                    value: city,
                    child: Text(city),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _localFilters = _localFilters.clearFilter('location');
                  } else {
                    _localFilters = _localFilters.copyWith(city: value);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsultationModeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mode de consultation",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            FilterChip(
              label: const Text("Cabinet"),
              selected: _localFilters.consultationModes.contains(
                ConsultationMode.inPerson,
              ),
              onSelected: (selected) {
                setState(() {
                  final modes = Set<ConsultationMode>.from(
                    _localFilters.consultationModes,
                  );
                  selected
                      ? modes.add(ConsultationMode.inPerson)
                      : modes.remove(ConsultationMode.inPerson);
                  _localFilters = _localFilters.copyWith(
                    consultationModes: modes,
                  );
                });
              },
            ),
            FilterChip(
              label: const Text("Visio"),
              selected: _localFilters.consultationModes.contains(
                ConsultationMode.video,
              ),
              onSelected: (selected) {
                setState(() {
                  final modes = Set<ConsultationMode>.from(
                    _localFilters.consultationModes,
                  );
                  selected
                      ? modes.add(ConsultationMode.video)
                      : modes.remove(ConsultationMode.video);
                  _localFilters = _localFilters.copyWith(
                    consultationModes: modes,
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Distance maximale",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        Slider(
          value: _localFilters.maxDistance ?? 50,
          min: 1,
          max: 100,
          divisions: 20,
          label: '${(_localFilters.maxDistance ?? 50).round()} km',
          onChanged: (value) {
            setState(
              () => _localFilters = _localFilters.copyWith(maxDistance: value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Disponibilité",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            FilterChip(
              label: const Text("Aujourd'hui"),
              selected: _localFilters.availableFrom != null,
              onSelected: (selected) {
                setState(() {
                  _localFilters = _localFilters.copyWith(
                    availableFrom: selected ? DateTime.now() : DateTime(1900),
                    availableTo: selected
                        ? DateTime.now().add(const Duration(days: 1))
                        : DateTime(1900),
                  );
                });
              },
            ),
            FilterChip(
              label: const Text("Cette semaine"),
              selected: false,
              onSelected: (selected) {
                setState(() {
                  _localFilters = _localFilters.copyWith(
                    availableFrom: DateTime.now(),
                    availableTo: DateTime.now().add(const Duration(days: 7)),
                  );
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleFilters() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text("Accepte nouveaux patients"),
          value: _localFilters.onlyAcceptingNewPatients,
          onChanged: (value) {
            setState(
              () => _localFilters = _localFilters.copyWith(
                onlyAcceptingNewPatients: value,
              ),
            );
          },
        ),
        SwitchListTile(
          title: const Text("Profil vérifié uniquement"),
          value: _localFilters.onlyVerified,
          onChanged: (value) {
            setState(
              () => _localFilters = _localFilters.copyWith(onlyVerified: value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trier par",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text("Pertinence"),
              selected: _localFilters.sortBy == SortBy.relevance,
              onSelected: (selected) {
                if (selected)
                  setState(
                    () => _localFilters = _localFilters.copyWith(
                      sortBy: SortBy.relevance,
                    ),
                  );
              },
            ),
            ChoiceChip(
              label: const Text("Distance"),
              selected: _localFilters.sortBy == SortBy.distance,
              onSelected: (selected) {
                if (selected)
                  setState(
                    () => _localFilters = _localFilters.copyWith(
                      sortBy: SortBy.distance,
                    ),
                  );
              },
            ),
            ChoiceChip(
              label: const Text("Note"),
              selected: _localFilters.sortBy == SortBy.rating,
              onSelected: (selected) {
                if (selected)
                  setState(
                    () => _localFilters = _localFilters.copyWith(
                      sortBy: SortBy.rating,
                    ),
                  );
              },
            ),
            ChoiceChip(
              label: const Text("Disponibilité"),
              selected: _localFilters.sortBy == SortBy.availability,
              onSelected: (selected) {
                if (selected)
                  setState(
                    () => _localFilters = _localFilters.copyWith(
                      sortBy: SortBy.availability,
                    ),
                  );
              },
            ),
            ChoiceChip(
              label: const Text("Prix"),
              selected: _localFilters.sortBy == SortBy.price,
              onSelected: (selected) {
                if (selected)
                  setState(
                    () => _localFilters = _localFilters.copyWith(
                      sortBy: SortBy.price,
                    ),
                  );
              },
            ),
          ],
        ),
      ],
    );
  }
}
