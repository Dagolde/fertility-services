import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_model.g.dart';

@JsonSerializable()
class Service {
  final int id;
  final String name;
  @JsonKey(name: 'service_type')
  final String serviceType;
  final String? description;
  final double? price;
  @JsonKey(name: 'duration_minutes')
  final int? durationMinutes;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.serviceType,
    this.description,
    this.price,
    this.durationMinutes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) => _$ServiceFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceToJson(this);

  String get formattedPrice {
    if (price == null) return 'Contact for pricing';
    return '₦${price!.toStringAsFixed(2)}';
  }

  String get formattedDuration {
    if (durationMinutes == null) return 'Varies';
    if (durationMinutes! < 60) {
      return '${durationMinutes} minutes';
    } else {
      final hours = durationMinutes! ~/ 60;
      final minutes = durationMinutes! % 60;
      if (minutes == 0) {
        return '${hours} hour${hours > 1 ? 's' : ''}';
      } else {
        return '${hours}h ${minutes}m';
      }
    }
  }

  String get serviceTypeLabel {
    switch (serviceType.toLowerCase()) {
      case 'sperm_donation':
        return 'Sperm Donation';
      case 'egg_donation':
        return 'Egg Donation';
      case 'surrogacy':
        return 'Surrogacy';
      case 'ivf':
        return 'IVF Treatment';
      case 'fertility_consultation':
        return 'Fertility Consultation';
      default:
        return serviceType.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData get serviceIcon {
    switch (serviceType.toLowerCase()) {
      case 'sperm_donation':
        return Icons.male;
      case 'egg_donation':
        return Icons.female;
      case 'surrogacy':
        return Icons.pregnant_woman;
      case 'ivf':
        return Icons.science;
      case 'fertility_consultation':
        return Icons.medical_services;
      default:
        return Icons.medical_services;
    }
  }

  Color get serviceColor {
    switch (serviceType.toLowerCase()) {
      case 'sperm_donation':
        return Colors.blue;
      case 'egg_donation':
        return Colors.pink;
      case 'surrogacy':
        return Colors.purple;
      case 'ivf':
        return Colors.green;
      case 'fertility_consultation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
