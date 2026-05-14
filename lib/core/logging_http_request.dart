import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/api_log_model.dart';
import '../services/api_log_service.dart';
import '../services/screen_tracker.dart';
import 'logging_http_response.dart';

class LoggingHttpClientRequest implements HttpClientRequest {
  final HttpClientRequest _inner;
  final List<int> _bodyBytes = [];
  final DateTime _startTime = DateTime.now();

  LoggingHttpClientRequest(this._inner);

  @override
  void add(List<int> data) {
    if (ApiLogService().isEnabled) {
      _bodyBytes.addAll(data);
    }
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) async {
    if (!ApiLogService().isEnabled) {
      return _inner.addStream(stream);
    }

    final controller = StreamController<List<int>>(sync: true);
    final future = _inner.addStream(controller.stream);

    await for (final data in stream) {
      _bodyBytes.addAll(data);
      controller.add(data);
    }

    await controller.close();
    return future;
  }

  @override
  Future<HttpClientResponse> close() async {
    final response = await _inner.close();

    if (!ApiLogService().isEnabled) return response;

    final sessionId = ApiLogService().currentSessionId ?? 'unknown';
    final logId = const Uuid().v4();
    final url = uri.toString();
    final method = this.method;
    final requestHeaders = <String, String>{};
    headers.forEach((name, values) {
      requestHeaders[name] = values.join(', ');
    });

    final screenName = ScreenTracker().currentScreen;
    final requestBody = _decodeBody(_bodyBytes, headers.contentType);

    return LoggingHttpClientResponse(response, (responseBodyBytes) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime);

      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      final responseBody = _decodeBody(
        responseBodyBytes,
        response.headers.contentType,
      );

      final log = ApiLogModel(
        id: logId,
        sessionId: sessionId,
        method: method,
        url: url,
        requestHeaders: requestHeaders,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        statusCode: response.statusCode,
        timestamp: _startTime,
        duration: duration,
        screenName: screenName,
        isError: response.statusCode >= 400,
      );

      ApiLogService().addLog(log);
    });
  }

  dynamic _decodeBody(List<int> bytes, ContentType? contentType) {
    if (bytes.isEmpty) return null;
    try {
      final bodyString = utf8.decode(bytes);
      if (contentType?.subType == 'json' ||
          bodyString.startsWith('{') ||
          bodyString.startsWith('[')) {
        try {
          return json.decode(bodyString);
        } catch (_) {
          return bodyString;
        }
      }
      return bodyString;
    } catch (_) {
      return 'Binary Data (${bytes.length} bytes)';
    }
  }

  @override
  HttpConnectionInfo? get connectionInfo => _inner.connectionInfo;

  @override
  List<Cookie> get cookies => _inner.cookies;

  @override
  Future<HttpClientResponse> get done => _inner.done;

  @override
  set encoding(Encoding value) => _inner.encoding = value;
  @override
  Encoding get encoding => _inner.encoding;

  @override
  set followRedirects(bool value) => _inner.followRedirects = value;
  @override
  bool get followRedirects => _inner.followRedirects;

  @override
  HttpHeaders get headers => _inner.headers;

  @override
  set maxRedirects(int value) => _inner.maxRedirects = value;
  @override
  int get maxRedirects => _inner.maxRedirects;

  @override
  String get method => _inner.method;

  @override
  set persistentConnection(bool value) => _inner.persistentConnection = value;
  @override
  bool get persistentConnection => _inner.persistentConnection;

  @override
  Uri get uri => _inner.uri;

  @override
  void write(Object? object) {
    if (ApiLogService().isEnabled) {
      final string = object.toString();
      _bodyBytes.addAll(utf8.encode(string));
    }
    _inner.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    if (ApiLogService().isEnabled) {
      for (var obj in objects) {
        write(obj);
        if (separator.isNotEmpty) write(separator);
      }
    } else {
      _inner.writeAll(objects, separator);
    }
  }

  @override
  void writeCharCode(int charCode) {
    if (ApiLogService().isEnabled) {
      _bodyBytes.add(charCode);
    }
    _inner.writeCharCode(charCode);
  }

  @override
  void writeln([Object? object = ""]) {
    if (ApiLogService().isEnabled) {
      write(object);
      write("\n");
    } else {
      _inner.writeln(object);
    }
  }

  @override
  set contentLength(int value) => _inner.contentLength = value;
  @override
  int get contentLength => _inner.contentLength;

  @override
  set bufferOutput(bool value) => _inner.bufferOutput = value;
  @override
  bool get bufferOutput => _inner.bufferOutput;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) =>
      _inner.abort(exception, stackTrace);

  @override
  Future flush() => _inner.flush();
}
