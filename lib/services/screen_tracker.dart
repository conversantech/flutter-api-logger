class ScreenTracker {
  static final ScreenTracker _instance = ScreenTracker._internal();
  factory ScreenTracker() => _instance;
  ScreenTracker._internal();

  String? _currentScreen;

  String? get currentScreen => _currentScreen;

  void updateScreen(String? name) {
    _currentScreen = name;
  }
}
