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
    );
  }

  final ZodiacInfo zodiac;
  final WuyunLiuqiInfo wuyunLiuqi;
  final String disclaimer;
}
