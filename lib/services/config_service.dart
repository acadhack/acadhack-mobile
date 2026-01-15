import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String keyApiKey = 'gemini_api_key';
  static const String keyModelName = 'model_name';
  static const String keyStealthMode = 'stealth_mode';
  static const String keyDarkMode = 'dark_mode_enabled';

  final SharedPreferences _prefs;

  ConfigService(this._prefs);

  // === Getters ===
  String? get apiKey => _prefs.getString(keyApiKey);
  String get modelName =>
      _prefs.getString(keyModelName) ?? 'gemini-3-flash-preview';
  bool get isStealthMode => _prefs.getBool(keyStealthMode) ?? false;
  bool get isDarkMode => _prefs.getBool(keyDarkMode) ?? true;

  // New Features
  double get rateLimit =>
      _prefs.getDouble('rate_limit') ??
      12.0; // Seconds (5 req/min on free tier)

  // Guess Mode
  bool get isGuessMode => _prefs.getBool('guess_mode') ?? false;
  String get guessOption =>
      _prefs.getString('guess_option') ?? 'A'; // A, B, C, D, RANDOM

  // Delays (Stealth)
  double get minDelay => _prefs.getDouble('min_delay') ?? 3.0; // Seconds
  double get maxDelay => _prefs.getDouble('max_delay') ?? 10.0; // Seconds

  // === Setters ===
  Future<void> setApiKey(String value) async =>
      await _prefs.setString(keyApiKey, value);
  Future<void> setModelName(String value) async =>
      await _prefs.setString(keyModelName, value);
  Future<void> setStealthMode(bool value) async =>
      await _prefs.setBool(keyStealthMode, value);
  Future<void> setDarkMode(bool value) async =>
      await _prefs.setBool(keyDarkMode, value);

  Future<void> setRateLimit(double value) async =>
      await _prefs.setDouble('rate_limit', value);

  Future<void> setGuessMode(bool value) async =>
      await _prefs.setBool('guess_mode', value);
  Future<void> setGuessOption(String value) async =>
      await _prefs.setString('guess_option', value);

  Future<void> setMinDelay(double value) async =>
      await _prefs.setDouble('min_delay', value);
  Future<void> setMaxDelay(double value) async =>
      await _prefs.setDouble('max_delay', value);

  // === Factory ===
  static Future<ConfigService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return ConfigService(prefs);
  }
}
