import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/api_log_model.dart';
import '../models/api_session_model.dart';
import '../models/smtp_config.dart';
import 'api_database_service.dart';

class ApiLogService {
  static final ApiLogService _instance = ApiLogService._internal();
  factory ApiLogService() => _instance;
  ApiLogService._internal();

  static const String _prefKey = 'api_debugger_enabled';
  static const String _senderKey = 'api_debugger_last_sender';
  final List<ApiLogModel> _currentSessionLogs = [];
  bool _enabled = false;
  String? _currentSessionId;
  SmtpConfig? _smtpConfig;
  String? _lastSenderName;
  bool _initialized = false;

  final StreamController<List<ApiLogModel>> _logController =
      StreamController<List<ApiLogModel>>.broadcast();

  Stream<List<ApiLogModel>> get logStream => _logController.stream;

  bool get isEnabled => _enabled;
  String? get currentSessionId => _currentSessionId;
  SmtpConfig? get smtpConfig => _smtpConfig;
  String? get lastSenderName => _lastSenderName;
  bool get isInitialized => _initialized;

  void setSmtpConfig(SmtpConfig? config) => _smtpConfig = config;

  Future<void> setLastSenderName(String name) async {
    _lastSenderName = name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_senderKey, name);
    } catch (_) {}
  }

  /// Load persisted state and start a new session if enabled.
  Future<void> init() async {
    _initialized = true;
    // 1. Load enabled state
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefKey) ?? false;
      _lastSenderName = prefs.getString(_senderKey);
      debugPrint(
          'ApiDebugger: [INIT] Loaded persisted state: $_enabled, last sender: $_lastSenderName');
    } catch (e) {
      _enabled = true;
    }

    // 2. Start a new session only if enabled
    if (_enabled) {
      await _startNewSession();
    } else {
      _currentSessionLogs.clear();
      _logController.add([]);
    }
  }

  Future<void> _startNewSession() async {
    if (_currentSessionId != null) return;

    _currentSessionId = const Uuid().v4();
    final newSession = ApiSessionModel(
      id: _currentSessionId!,
      name: _currentSessionId!,
      startTime: DateTime.now(),
    );
    await ApiDatabaseService().insertSession(newSession);
    debugPrint('ApiDebugger: [SESSION] Started: $_currentSessionId');

    _currentSessionLogs.clear();
    _logController.add([]);
  }

  Future<void> enable() async {
    if (_enabled) return;
    _enabled = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
    } catch (_) {}

    await _startNewSession();
  }

  Future<void> disable() async {
    _enabled = false;
    _currentSessionId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, false);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    await ApiDatabaseService().clearAll();
    _currentSessionLogs.clear();
    _logController.add([]);
  }

  Future<void> addLog(ApiLogModel log) async {
    if (!_enabled) return;

    // Persist to database
    await ApiDatabaseService().insertLog(log);

    // If it belongs to current session, update memory list and stream
    if (log.sessionId == _currentSessionId) {
      _currentSessionLogs.insert(0, log);
      if (_currentSessionLogs.length > 200) {
        _currentSessionLogs.removeLast();
      }
      _logController.add(List.from(_currentSessionLogs));
    }
  }

  Future<List<ApiSessionModel>> getSessions() {
    return ApiDatabaseService().getSessions();
  }

  Future<List<ApiLogModel>> getLogsForSession(String sessionId) {
    if (sessionId == _currentSessionId) {
      return Future.value(List.from(_currentSessionLogs));
    }
    return ApiDatabaseService().getLogsForSession(sessionId);
  }

  Future<int> getLogCountForSession(String sessionId) {
    if (sessionId == _currentSessionId) {
      return Future.value(_currentSessionLogs.length);
    }
    return ApiDatabaseService().getLogCountForSession(sessionId);
  }

  List<ApiLogModel> getCurrentSessionLogs() {
    return List.from(_currentSessionLogs);
  }

  Future<void> updateSessionName(String sessionId, String newName) async {
    await ApiDatabaseService().updateSessionName(sessionId, newName);
    // Note: since the session list screen uses a FutureBuilder fetching from DB,
    // it will re-read the updated name when refreshed.
  }

  Future<void> clearSession(String sessionId) async {
    await ApiDatabaseService().clearSession(sessionId);
    if (sessionId == _currentSessionId) {
      _currentSessionLogs.clear();
      _logController.add([]);
    }
  }
}
