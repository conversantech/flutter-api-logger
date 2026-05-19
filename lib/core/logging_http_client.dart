import 'dart:io';
import 'logging_http_request.dart';

class LoggingHttpClient implements HttpClient {
  final HttpClient _inner;

  LoggingHttpClient(this._inner);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) async {
    final request = await _inner.open(method, host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    final request = await _inner.openUrl(method, url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async {
    final request = await _inner.get(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    final request = await _inner.getUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) async {
    final request = await _inner.post(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    final request = await _inner.postUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) async {
    final request = await _inner.put(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) async {
    final request = await _inner.putUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) async {
    final request = await _inner.delete(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async {
    final request = await _inner.deleteUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) async {
    final request = await _inner.head(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) async {
    final request = await _inner.headUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async {
    final request = await _inner.patch(host, port, path);
    return LoggingHttpClientRequest(request);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) async {
    final request = await _inner.patchUrl(url);
    return LoggingHttpClientRequest(request);
  }

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )? f,
  ) =>
      _inner.connectionFactory = f;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  Duration get idleTimeout => _inner.idleTimeout;
  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;
  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  String? get userAgent => _inner.userAgent;
  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) =>
      _inner.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
        f,
  ) =>
      _inner.authenticateProxy = f;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) =>
      _inner.badCertificateCallback = callback;

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
