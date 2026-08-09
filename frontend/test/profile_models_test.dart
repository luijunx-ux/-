import 'package:flutter_test/flutter_test.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

void main() {
  test('parses profile response', () {
    final LifeProfile profile = LifeProfile.fromJson(<String, dynamic>{
      'profile': <String, dynamic>{
        'zodiac': <String, dynamic>{
          'sign': '狮子座',
          'element': '火',
          'modality': '固定',
        },
        'wuyun_liuqi': <String, dynamic>{
          'heavenly_stem': '庚',
          'earthly_branch': '午',
          'middle_movement': '金运',
          'movement_strength': '太过',
          'governing_qi': '少阴君火',
          'responding_qi': '阳明燥金',
          'algorithm_version': 'calendar_year_v1',
          'boundary_warning': null,
        },
      },
      'disclaimer': '仅供参考',
    });

    expect(profile.zodiac.sign, '狮子座');
    expect(profile.wuyunLiuqi.middleMovement, '金运');
    expect(profile.disclaimer, '仅供参考');
  });
}
