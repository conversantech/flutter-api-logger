import 'dart:async';
import 'dart:io';

class LoggingHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final HttpClientResponse _inner;
  final List<int> _bodyBytes = [];
  final Function(List<int> bytes) _onDone;

  LoggingHttpClientResponse(this._inner, this._onDone);

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // We only start listening to the inner stream when the client starts listening to us.
    // This prevents "hanging" and ensures proper stream lifecycle.
    return _inner.listen(
      (data) {
        _bodyBytes.addAll(data);
        if (onData != null) onData(data);
      },
      onError: (error) {
        if (onError != null) {
          if (onError is void Function(Object, StackTrace)) {
            onError(error, StackTrace.current);
          } else if (onError is void Function(Object)) {
            onError(error);
          }
        }
      },
      onDone: () {
        _onDone(_bodyBytes);
        if (onDone != null) onDone();
      },
      cancelOnError: cancelOnError,
    );
  }

  @override
  X509Certificate? get certificate => _inner.certificate;

  @override
  HttpClientResponseCompressionState get compressionState =>
      _inner.compressionState;

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  int get contentLength => _inner.contentLength;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<Socket> detachSocket() => _inner.detachSocket();

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  bool get isRedirect => _inner.isRedirect;

  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  String get reasonPhrase => _inner.reasonPhrase;

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      _inner.redirect(method, url, followLoops);

  @override
  List<RedirectInfo> get redirects => _inner.redirects;

  @override
  int get statusCode => _inner.statusCode;
}
