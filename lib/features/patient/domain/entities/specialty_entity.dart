import 'package:equatable/equatable.dart';

class SpecialtyEntity extends Equatable {
  final String id;
  final String name;
  final String? nameEn;
  final String? nameAr;
  final String category;
  final String description;
  final String icon;
  final String color;
  final List<String> gradient;
  final List<String> keywords;
  final List<String> commonConditions;
  final SpecialtyStatistics statistics;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SpecialtyEntity({
    required this.id,
    required this.name,
    this.nameEn,
    this.nameAr,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.keywords,
    required this.commonConditions,
    required this.statistics,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    nameEn,
    nameAr,
    category,
    description,
    icon,
    color,
    gradient,
    keywords,
    commonConditions,
    statistics,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
}

class SpecialtyStatistics extends Equatable {
  final int doctorCount;
  final int averageWaitTime;
  final int popularityRank;

  const SpecialtyStatistics({
    required this.doctorCount,
    required this.averageWaitTime,
    required this.popularityRank,
  });

  @override
  List<Object?> get props => [doctorCount, averageWaitTime, popularityRank];
}
