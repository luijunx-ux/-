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

  test('requests daily advice for the selected date', () async {
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/advice/daily');
      expect(request.headers['authorization'], 'Bearer user-token');
      final Map<String, dynamic> payload =
          jsonDecode(request.body) as Map<String, dynamic>;
      expect(payload['target_date'], '2026-08-09');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(<String, dynamic>{
            'target_date': '2026-08-09',
            'advice': <String>['保持规律作息。', '安排短暂离屏休息。'],
            'disclaimer': '仅供参考',
            'generation_mode': 'llm',
            'model': 'gpt-test',
            'knowledge_sources': <String>['daily_rhythm_guidelines.md'],
          }),
        ),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final ProfileApiClient client = ProfileApiClient(
      client: transport,
      baseUrl: 'https://example.test',
      tokenProvider: () async => 'user-token',
    );

    final DailyAdvice advice = await client.getDailyAdvice(
      input,
      DateTime(2026, 8, 9),
    );

    expect(advice.items, hasLength(2));
    expect(advice.targetDate, DateTime(2026, 8, 9));
    expect(advice.generationMode, 'llm');
    expect(advice.model, 'gpt-test');
  });

  test('searches locations and parses timezone', () async {
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.url.path, '/api/v1/locations/search');
      expect(request.url.queryParameters['q'], '上海');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'display_name': '上海市, 中国',
              'latitude': 31.2304,
              'longitude': 121.4737,
              'timezone': 'Asia/Shanghai',
            },
          ]),
        ),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });
    final ProfileApiClient client = ProfileApiClient(
      client: transport,
      baseUrl: 'https://example.test',
    );

    final List<LocationCandidate> results =
        await client.searchLocations(' 上海 ');

    expect(results.single.displayName, '上海市, 中国');
    expect(results.single.timezone, 'Asia/Shanghai');
  });

  test('saves, lists, and deletes owned profiles with bearer token', () async {
    int requestCount = 0;
    final Map<String, dynamic> stored = <String, dynamic>{
      'id': '5fa54cb8-6820-480b-a480-e6032e092b01',
      'name': '我的档案',
      'is_default': true,
      'profile': <String, dynamic>{
        'birth': <String, dynamic>{
          'occurred_at': '1990-08-15T10:30:00+08:00',
          'place_name': '上海市',
          'latitude': 31.2304,
          'longitude': 121.4737,
          'timezone': 'Asia/Shanghai',
        },
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
    };
    final MockClient transport = MockClient((http.Request request) async {
      requestCount++;
      expect(request.headers['authorization'], 'Bearer user-token');
      if (request.method == 'POST') {
        return http.Response.bytes(
          utf8.encode(jsonEncode(stored)),
          201,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }
      if (request.method == 'GET') {
        return http.Response.bytes(
          utf8.encode(jsonEncode(<Object>[stored])),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }
      if (request.method == 'PUT') {
        final Map<String, dynamic> payload =
            jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['name'], '更新后的档案');
        return http.Response.bytes(
          utf8.encode(jsonEncode(<String, dynamic>{
            ...stored,
            'name': '更新后的档案',
          })),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }
      expect(request.method, 'DELETE');
      return http.Response('', 204);
    });
    final ProfileApiClient client = ProfileApiClient(
      client: transport,
      baseUrl: 'https://example.test',
      tokenProvider: () async => 'user-token',
    );

    final LifeProfile saved = await client.saveProfile(
      input,
      name: '我的档案',
      isDefault: true,
    );
    final List<LifeProfile> listed = await client.listProfiles();
    final LifeProfile updated = await client.updateProfile(
      saved.id!,
      input,
      name: '更新后的档案',
      isDefault: true,
    );
    await client.deleteProfile(saved.id!);

    expect(saved.birthInput?.placeName, '上海市');
    expect(listed.single.id, saved.id);
    expect(updated.name, '更新后的档案');
    expect(saved.isDefault, isTrue);
    expect(requestCount, 4);
  });

  test('uses cached profile advice, feedback, history, and streak endpoints',
      () async {
    final Map<String, dynamic> adviceJson = <String, dynamic>{
      'id': '1e0c5c4d-05f1-4a38-8f72-02bd73655e08',
      'profile_id': '5fa54cb8-6820-480b-a480-e6032e092b01',
      'target_date': '2026-08-10',
      'advice': <String>['Keep a regular routine.'],
      'disclaimer': 'For reference only.',
      'generation_mode': 'llm',
      'model': 'gpt-test',
      'knowledge_sources': <String>[],
      'request_id': 'request-id',
      'input_tokens': 10,
      'output_tokens': 5,
      'cached': true,
      'helpful': null,
    };
    final MockClient transport = MockClient((http.Request request) async {
      expect(request.headers['authorization'], 'Bearer user-token');
      if (request.url.path.endsWith('/advice/daily')) {
        expect(request.url.path, contains('/profiles/'));
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload.keys, <String>['target_date']);
        return http.Response(jsonEncode(adviceJson), 200);
      }
      if (request.url.path.endsWith('/feedback')) {
        return http.Response(
          jsonEncode(<String, dynamic>{...adviceJson, 'helpful': true}),
          200,
        );
      }
      if (request.url.path.endsWith('/history')) {
        return http.Response(jsonEncode(<Object>[adviceJson]), 200);
      }
      expect(request.url.path, '/api/v1/advice/stats');
      return http.Response(jsonEncode(<String, int>{'viewing_streak': 3}), 200);
    });
    final ProfileApiClient client = ProfileApiClient(
      client: transport,
      baseUrl: 'https://example.test',
      tokenProvider: () async => 'user-token',
    );

    final DailyAdvice advice = await client.getDailyAdvice(
      input,
      DateTime(2026, 8, 10),
      profileId: '5fa54cb8-6820-480b-a480-e6032e092b01',
    );
    final DailyAdvice feedback = await client.submitAdviceFeedback(
      advice.id!,
      helpful: true,
    );
    final List<DailyAdvice> history = await client.listAdviceHistory();
    final int streak = await client.getViewingStreak(DateTime(2026, 8, 10));

    expect(advice.cached, isTrue);
    expect(feedback.helpful, isTrue);
    expect(history.single.id, advice.id);
    expect(streak, 3);
  });
}
