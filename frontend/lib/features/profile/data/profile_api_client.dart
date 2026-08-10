import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tianrenlu/core/api_config.dart';
import 'package:tianrenlu/features/profile/domain/profile_models.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

typedef AccessTokenProvider = Future<String?> Function();

class ProfileApiClient {
  ProfileApiClient({
    http.Client? client,
    String? baseUrl,
    AccessTokenProvider? tokenProvider,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _tokenProvider = tokenProvider;

  final http.Client _client;
  final String _baseUrl;
  final AccessTokenProvider? _tokenProvider;

  Future<LifeProfile> generateProfile(BirthInput input) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles/generate');
    final http.Response response;
    final Map<String, String> headers = await _headers();
    try {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(input.toJson()),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法连接生命节律服务，请检查网络与服务地址。');
    }

    final Object? decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ProfileApiException('服务返回了无法识别的数据。');
    }
    return LifeProfile.fromJson(decoded);
  }

  Future<LifeProfile> saveProfile(
    BirthInput input, {
    required String name,
    bool isDefault = false,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles');
    final http.Response response;
    final Map<String, String> headers = await _headers();
    try {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(<String, Object>{
              ...input.toJson(),
              'name': name,
              'is_default': isDefault,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法保存生命档案，请检查网络后重试。');
    }
    return _profileFromResponse(response);
  }

  Future<LifeProfile> updateProfile(
    String profileId,
    BirthInput input, {
    required String name,
    required bool isDefault,
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles/$profileId');
    final http.Response response;
    try {
      response = await _client
          .put(
            uri,
            headers: await _headers(),
            body: jsonEncode(<String, Object>{
              ...input.toJson(),
              'name': name,
              'is_default': isDefault,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法更新生命档案，请检查网络后重试。');
    }
    return _profileFromResponse(response);
  }

  Future<List<LifeProfile>> listProfiles() async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles');
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法获取生命档案，请检查网络后重试。');
    }
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! List<dynamic>) {
      throw const ProfileApiException('服务返回了无法识别的档案列表。');
    }
    return decoded
        .map((dynamic item) =>
            LifeProfile.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> deleteProfile(String profileId) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles/$profileId');
    final http.Response response;
    try {
      response = await _client
          .delete(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法删除生命档案，请检查网络后重试。');
    }
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
  }

  Future<DailyAdvice> getDailyAdvice(
    BirthInput input,
    DateTime targetDate, {
    String? profileId,
  }) async {
    final Uri uri = Uri.parse(
      profileId == null
          ? '$_baseUrl/api/v1/advice/daily'
          : '$_baseUrl/api/v1/profiles/$profileId/advice/daily',
    );
    final Map<String, Object> payload = <String, Object>{
      if (profileId == null) ...input.toJson(),
      'target_date': _dateOnly(targetDate),
    };
    final http.Response response;
    final Map<String, String> headers = await _headers();
    try {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法获取每日建议，请检查网络后重试。');
    }

    final Object? decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ProfileApiException('服务返回了无法识别的数据。');
    }
    return DailyAdvice.fromJson(decoded);
  }

  Future<List<DailyAdvice>> listAdviceHistory() async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$_baseUrl/api/v1/advice/history'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法获取建议历史，请检查网络后重试。');
    }
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! List<dynamic>) {
      throw const ProfileApiException('服务返回了无法识别的建议历史。');
    }
    return decoded
        .map((dynamic item) =>
            DailyAdvice.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<DailyAdvice> submitAdviceFeedback(
    String adviceId, {
    required bool helpful,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse('$_baseUrl/api/v1/advice/$adviceId/feedback'),
            headers: await _headers(),
            body: jsonEncode(<String, bool>{'helpful': helpful}),
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法提交反馈，请稍后重试。');
    }
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    return DailyAdvice.fromJson(decoded as Map<String, dynamic>);
  }

  Future<int> getViewingStreak(DateTime throughDate) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/advice/stats').replace(
      queryParameters: <String, String>{'through_date': _dateOnly(throughDate)},
    );
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const ProfileApiException('无法获取连续查看统计。');
    }
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    return (decoded as Map<String, dynamic>)['viewing_streak'] as int;
  }

  Future<List<LocationCandidate>> searchLocations(String query) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/locations/search').replace(
      queryParameters: <String, String>{'q': query.trim()},
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 12));
    } on Exception {
      throw const ProfileApiException('无法搜索地点，请检查网络后重试。');
    }

    final Object? decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! List<dynamic>) {
      throw const ProfileApiException('地点服务返回了无法识别的数据。');
    }
    return decoded
        .map(
          (dynamic item) => LocationCandidate.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  String _dateOnly(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<Map<String, String>> _headers() async {
    final String? token = await _tokenProvider?.call();
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  LifeProfile _profileFromResponse(http.Response response) {
    final Object? decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(decoded));
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ProfileApiException('服务返回了无法识别的档案数据。');
    }
    return LifeProfile.fromJson(decoded);
  }

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  String _errorMessage(Object? body) {
    if (body is Map<String, dynamic> && body['detail'] is String) {
      return body['detail'] as String;
    }
    return '生成生命档案失败，请稍后重试。';
  }
}
