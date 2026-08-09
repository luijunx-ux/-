import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tianrenlu/features/profile/data/profile_api_client.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

void main() {
  final BirthInput input = BirthInput(
    occurredAt: DateTime(1990, 8, 15, 10, 30),
    placeName: '上海市',
    latitude: 31.2304,
    longitude: 121.4737,
    timezone: 'Asia/Shanghai',
  );

  test('sends birth data and parses a successful profile', () async {
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/profiles/generate');
      final Map<String, dynamic> payload =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['timezone'], 'Asia/Shanghai');
      expect(payload['occurred_at'], isNotEmpty);
      return http.Response(
        jsonEncode(<String, dynamic>{
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
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });
    final ProfileApiClient client = ProfileApiClient(
      client: transport,
      baseUrl: 'https://example.test',
    );

    final LifeProfile profile = await client.generateProfile(input);

    expect(profile.zodiac.sign, '狮子座');
  });

  test('converts API failure into a user-facing exception', () async {
    final ProfileApiClient client = ProfileApiClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode(<String, String>{'detail': '输入无效'})),
          422,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        ),
      ),
      baseUrl: 'https://example.test',
    );

    expect(
      () => client.generateProfile(input),
      throwsA(
        isA<ProfileApiException>().having(
          (ProfileApiException error) => error.message,
          'message',
          '输入无效',
        ),
      ),
    );
  });
}
