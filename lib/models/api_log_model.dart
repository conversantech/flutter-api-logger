import 'dart:convert';

class ApiLogModel {
  final String id;
  final String sessionId; // Added sessionId
  final String method;
  final String url;
  final Map<String, String>? requestHeaders;
  final dynamic requestBody;
  final Map<String, String>? responseHeaders;
  final dynamic responseBody;
  final int? statusCode;
  final DateTime timestamp;
  final Duration duration;
  final String? screenName;
  final bool isError;

  ApiLogModel({
    required this.id,
    required this.sessionId,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.responseHeaders,
    this.responseBody,
    this.statusCode,
    required this.timestamp,
    required this.duration,
    this.screenName,
    this.isError = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'method': method,
      'url': url,
      'requestHeaders': json.encode(requestHeaders),
      'requestBody':
          requestBody is String ? requestBody : json.encode(requestBody),
      'responseHeaders': json.encode(responseHeaders),
      'responseBody':
          responseBody is String ? responseBody : json.encode(responseBody),
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'screenName': screenName,
      'isError': isError ? 1 : 0,
    };
  }

  factory ApiLogModel.fromMap(Map<String, dynamic> map) {
    dynamic decodeBody(dynamic body) {
      if (body == null) return null;
      try {
        return json.decode(body as String);
      } catch (_) {
        return body;
      }
    }

    return ApiLogModel(
      id: map['id'],
      sessionId: map['sessionId'],
      method: map['method'],
      url: map['url'],
      requestHeaders: map['requestHeaders'] != null
          ? Map<String, String>.from(json.decode(map['requestHeaders']))
          : null,
      requestBody: decodeBody(map['requestBody']),
      responseHeaders: map['responseHeaders'] != null
          ? Map<String, String>.from(json.decode(map['responseHeaders']))
          : null,
      responseBody: decodeBody(map['responseBody']),
      statusCode: map['statusCode'],
      timestamp: DateTime.parse(map['timestamp']),
      duration: Duration(milliseconds: map['durationMs']),
      screenName: map['screenName'],
      isError: map['isError'] == 1,
    );
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;

    int hour = timestamp.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    final minuteStr = timestamp.minute.toString().padLeft(2, '0');

    return '$day-$month-$year $hourStr:$minuteStr $amPm';
  }

  String get formattedDuration {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    }
    return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';
  }

  String get formattedRequestHeaders => _formatMap(requestHeaders);
  String get formattedResponseHeaders => _formatMap(responseHeaders);

  String get formattedRequestBody => _formatBody(requestBody);
  String get formattedResponseBody => _formatBody(responseBody);

  String _formatMap(Map<String, String>? map) {
    if (map == null || map.isEmpty) return 'No headers';
    const JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(map);
  }

  String _formatBody(dynamic body) {
    if (body == null) return 'No body';
    if (body is String) {
      try {
        final decoded = json.decode(body);
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(decoded);
      } catch (_) {
        return body;
      }
    }
    if (body is Map || body is List) {
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(body);
    }
    return body.toString();
  }
}
