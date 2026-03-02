import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config/app_config.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box _hiveBox;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    _hiveBox = await Hive.openBox('app_data');
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure Storage Methods
  static Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  static Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  static Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  static Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // SharedPreferences Methods
  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  static List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  static Future<bool> clear() async {
    return await _prefs.clear();
  }

  // Hive Methods
  static Future<void> putHive(String key, dynamic value) async {
    await _hiveBox.put(key, value);
  }

  static T? getHive<T>(String key) {
    return _hiveBox.get(key);
  }

  static Future<void> deleteHive(String key) async {
    await _hiveBox.delete(key);
  }

  static Future<void> clearHive() async {
    await _hiveBox.clear();
  }

  // Convenience methods for app-specific data
  static Future<void> setUserToken(String token) async {
    await setSecureString(AppConfig.tokenKey, token);
  }

  static Future<String?> getUserToken() async {
    return await getSecureString(AppConfig.tokenKey);
  }

  static Future<void> clearUserToken() async {
    await deleteSecureString(AppConfig.tokenKey);
  }

  // Auth token methods (aliases for compatibility)
  static Future<void> storeAuthToken(String token) async {
    await setUserToken(token);
  }

  static Future<String?> getAuthToken() async {
    return await getUserToken();
  }

  static Future<void> clearAuthToken() async {
    await clearUserToken();
  }

  // Refresh token methods
  static Future<void> storeRefreshToken(String token) async {
    await setSecureString('refresh_token', token);
  }

  static Future<String?> getRefreshToken() async {
    return await getSecureString('refresh_token');
  }

  static Future<void> clearRefreshToken() async {
    await deleteSecureString('refresh_token');
  }

  // User credentials methods
  static Future<void> storeUserCredentials(String email, String password) async {
    await setSecureString('user_email', email);
    await setSecureString('user_password', password);
  }

  static Future<Map<String, String>?> getUserCredentials() async {
    final email = await getSecureString('user_email');
    final password = await getSecureString('user_password');
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  static Future<void> clearUserCredentials() async {
    await deleteSecureString('user_email');
    await deleteSecureString('user_password');
  }

  // Biometric methods
  static Future<void> clearBiometricKey() async {
    await deleteSecureString('biometric_key');
  }

  // Onboarding methods
  static bool isOnboardingCompleted() {
    return getBool('onboarding_completed') ?? false;
  }

  static Future<void> setOnboardingCompleted(bool completed) async {
    await setBool('onboarding_completed', completed);
  }

  // Clear all user data
  static Future<void> clearAllUserData() async {
    await clearSecureStorage();
    await clearHive();
    await clear();
  }

  static Future<void> setUserData(Map<String, dynamic> userData) async {
    await putHive(AppConfig.userKey, userData);
  }

  static Map<String, dynamic>? getUserData() {
    return getHive<Map<String, dynamic>>(AppConfig.userKey);
  }

  static Future<void> clearUserData() async {
    await deleteHive(AppConfig.userKey);
  }

  static Future<void> setAppSettings(Map<String, dynamic> settings) async {
    await putHive(AppConfig.settingsKey, settings);
  }

  static Map<String, dynamic>? getAppSettings() {
    return getHive<Map<String, dynamic>>(AppConfig.settingsKey);
  }

  static Future<void> clearAppSettings() async {
    await deleteHive(AppConfig.settingsKey);
  }

  // Theme and UI preferences
  static Future<void> setThemeMode(String themeMode) async {
    await setString('theme_mode', themeMode);
  }

  static String getThemeMode() {
    return getString('theme_mode') ?? 'system';
  }

  static Future<void> setLanguage(String languageCode) async {
    await setString('language', languageCode);
  }

  static String getLanguage() {
    return getString('language') ?? AppConfig.defaultLanguage;
  }

  // Notification preferences
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool('notifications_enabled', enabled);
  }

  static bool getNotificationsEnabled() {
    return getBool('notifications_enabled') ?? true;
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    await setBool('biometric_enabled', enabled);
  }

  static bool getBiometricEnabled() {
    return getBool('biometric_enabled') ?? false;
  }

  static bool isBiometricEnabled() {
    return getBiometricEnabled();
  }

  // Cache management
  static Future<void> setCacheData(String key, Map<String, dynamic> data) async {
    final cacheItem = {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await putHive('cache_$key', cacheItem);
  }

  static Map<String, dynamic>? getCacheData(String key, {Duration? maxAge}) {
    final cacheItem = getHive<Map<String, dynamic>>('cache_$key');
    if (cacheItem == null) return null;

    if (maxAge != null) {
      final timestamp = cacheItem['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > maxAge) {
        deleteHive('cache_$key');
        return null;
      }
    }

    return cacheItem['data'] as Map<String, dynamic>?;
  }

  static Future<void> clearCache() async {
    final keys = _hiveBox.keys.where((key) => key.toString().startsWith('cache_'));
    for (final key in keys) {
      await deleteHive(key.toString());
    }
  }

  // First time app launch
  static Future<void> setFirstLaunch(bool isFirst) async {
    await setBool('first_launch', isFirst);
  }

  static bool isFirstLaunch() {
    return getBool('first_launch') ?? true;
  }

  // App version tracking
  static Future<void> setAppVersion(String version) async {
    await setString('app_version', version);
  }

  static String? getAppVersion() {
    return getString('app_version');
  }
}
