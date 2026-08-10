class BirthInput {
  const BirthInput({
    required this.occurredAt,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  final DateTime occurredAt;
  final String placeName;
  final double latitude;
  final double longitude;
  final String timezone;

  factory BirthInput.fromJson(Map<String, dynamic> json) => BirthInput(
        occurredAt: DateTime.parse(json['occurred_at'] as String),
        placeName: json['place_name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String,
      );

  Map<String, Object> toJson() => <String, Object>{
        'occurred_at': _iso8601WithOffset(occurredAt),
        'place_name': placeName,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
      };

  static String _iso8601WithOffset(DateTime value) {
    final String base = value.toIso8601String();
    if (value.isUtc) {
      return base;
    }
    final Duration offset = value.timeZoneOffset;
    final String sign = offset.isNegative ? '-' : '+';
    final Duration absolute = offset.abs();
    final String hours = absolute.inHours.toString().padLeft(2, '0');
    final String minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    return '$base$sign$hours:$minutes';
  }
}

class ZodiacInfo {
  const ZodiacInfo({
    required this.sign,
    required this.element,
    required this.modality,
  });

  factory ZodiacInfo.fromJson(Map<String, dynamic> json) => ZodiacInfo(
        sign: json['sign'] as String,
        element: json['element'] as String,
        modality: json['modality'] as String,
      );

  final String sign;
  final String element;
  final String modality;
}

class WuyunLiuqiInfo {
  const WuyunLiuqiInfo({
    required this.heavenlyStem,
    required this.earthlyBranch,
    required this.middleMovement,
    required this.movementStrength,
    required this.governingQi,
    required this.respondingQi,
    required this.algorithmVersion,
    this.boundaryWarning,
  });

  factory WuyunLiuqiInfo.fromJson(Map<String, dynamic> json) => WuyunLiuqiInfo(
        heavenlyStem: json['heavenly_stem'] as String,
        earthlyBranch: json['earthly_branch'] as String,
        middleMovement: json['middle_movement'] as String,
        movementStrength: json['movement_strength'] as String,
        governingQi: json['governing_qi'] as String,
        respondingQi: json['responding_qi'] as String,
        algorithmVersion: json['algorithm_version'] as String,
        boundaryWarning: json['boundary_warning'] as String?,
      );

  final String heavenlyStem;
  final String earthlyBranch;
  final String middleMovement;
  final String movementStrength;
  final String governingQi;
  final String respondingQi;
  final String algorithmVersion;
  final String? boundaryWarning;
}

class LifeProfile {
  const LifeProfile({
    required this.zodiac,
    required this.wuyunLiuqi,
    required this.disclaimer,
    this.id,
    this.birthInput,
    this.name = '我的生命档案',
    this.isDefault = false,
  });

  factory LifeProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> profile =
        json['profile'] as Map<String, dynamic>;
    return LifeProfile(
      zodiac: ZodiacInfo.fromJson(profile['zodiac'] as Map<String, dynamic>),
      wuyunLiuqi: WuyunLiuqiInfo.fromJson(
        profile['wuyun_liuqi'] as Map<String, dynamic>,
      ),
      disclaimer: json['disclaimer'] as String,
      id: json['id'] as String?,
      birthInput: profile['birth'] == null
          ? null
          : BirthInput.fromJson(profile['birth'] as Map<String, dynamic>),
      name: json['name'] as String? ?? '我的生命档案',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  final ZodiacInfo zodiac;
  final WuyunLiuqiInfo wuyunLiuqi;
  final String disclaimer;
  final String? id;
  final BirthInput? birthInput;
  final String name;
  final bool isDefault;
}

class DailyAdvice {
  const DailyAdvice({
    required this.targetDate,
    required this.items,
    required this.disclaimer,
    required this.generationMode,
    required this.knowledgeSources,
    this.model,
    this.id,
    this.profileId,
    this.cached = false,
    this.helpful,
  });

  factory DailyAdvice.fromJson(Map<String, dynamic> json) => DailyAdvice(
        targetDate: DateTime.parse(json['target_date'] as String),
        items: (json['advice'] as List<dynamic>).cast<String>(),
        disclaimer: json['disclaimer'] as String,
        generationMode: json['generation_mode'] as String? ?? 'deterministic',
        model: json['model'] as String?,
        knowledgeSources:
            (json['knowledge_sources'] as List<dynamic>? ?? <dynamic>[])
                .cast<String>(),
        id: json['id'] as String?,
        profileId: json['profile_id'] as String?,
        cached: json['cached'] as bool? ?? false,
        helpful: json['helpful'] as bool?,
      );

  final DateTime targetDate;
  final List<String> items;
  final String disclaimer;
  final String generationMode;
  final String? model;
  final List<String> knowledgeSources;
  final String? id;
  final String? profileId;
  final bool cached;
  final bool? helpful;
}

class LocationCandidate {
  const LocationCandidate({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.timezone,
  });

  factory LocationCandidate.fromJson(Map<String, dynamic> json) =>
      LocationCandidate(
        displayName: json['display_name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timezone: json['timezone'] as String,
      );

  final String displayName;
  final double latitude;
  final double longitude;
  final String timezone;
}
