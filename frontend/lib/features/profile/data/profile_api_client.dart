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

class ProfileApiClient {
  ProfileApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<LifeProfile> generateProfile(BirthInput input) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/profiles/generate');
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
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

  Future<DailyAdvice> getDailyAdvice(
    BirthInput input,
    DateTime targetDate,
  ) async {
    final Uri uri = Uri.parse('$_baseUrl/api/v1/advice/daily');
    final Map<String, Object> payload = <String, Object>{
      ...input.toJson(),
      'target_date': _dateOnly(targetDate),
    };
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const <String, String>{'Content-Type': 'application/json'},
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

  String _dateOnly(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _errorMessage(Object? body) {
    if (body is Map<String, dynamic> && body['detail'] is String) {
      return body['detail'] as String;
    }
    return '生成生命档案失败，请稍后重试。';
  }
}
