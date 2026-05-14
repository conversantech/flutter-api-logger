import 'dart:io';
import 'logging_http_client.dart';

class LoggingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    return LoggingHttpClient(client);
  }
}
