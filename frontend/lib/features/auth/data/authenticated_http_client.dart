import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();
typedef TokenRefresher = Future<String?> Function();

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    required http.Client inner,
    required TokenProvider tokenProvider,
    required TokenRefresher tokenRefresher,
  })  : _inner = inner,
        _tokenProvider = tokenProvider,
        _tokenRefresher = tokenRefresher;

  final http.Client _inner;
  final TokenProvider _tokenProvider;
  final TokenRefresher _tokenRefresher;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.Request) {
      return _inner.send(request);
    }
    final http.StreamedResponse first = await _inner.send(
      await _clone(request, await _tokenProvider()),
    );
    if (first.statusCode != 401) return first;

    final String? refreshedToken = await _tokenRefresher();
    if (refreshedToken == null) return first;
    await first.stream.drain<void>();
    return _inner.send(await _clone(request, refreshedToken));
  }

  Future<http.Request> _clone(http.Request source, String? token) async {
    final http.Request clone = http.Request(source.method, source.url)
      ..encoding = source.encoding
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection
      ..headers.addAll(source.headers)
      ..bodyBytes = source.bodyBytes;
    if (token != null) clone.headers['Authorization'] = 'Bearer $token';
    return clone;
  }

  @override
  void close() => _inner.close();
}
