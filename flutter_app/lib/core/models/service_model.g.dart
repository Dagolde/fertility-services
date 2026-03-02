// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Service _$ServiceFromJson(Map<String, dynamic> json) => Service(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      serviceType: json['service_type'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ServiceToJson(Service instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'service_type': instance.serviceType,
      'description': instance.description,
      'price': instance.price,
      'duration_minutes': instance.durationMinutes,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
