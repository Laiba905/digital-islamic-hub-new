import 'package:flutter/services.dart';

class DndService {
  static const MethodChannel _channel = MethodChannel('dnd_channel');

  /// Checks if the notification policy access is granted (DND permission)
  static Future<bool> isNotificationPolicyAccessGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkDndPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Opens Native Android DND Permission Settings page
  static Future<void> openNotificationPolicySettings() async {
    try {
      await _channel.invokeMethod('openDndSettings');
    } on PlatformException catch (_) {}
  }

  static Future<bool> enableDnd() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableDND');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> disableDnd() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableDND');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Alias for compatibility
  static Future<void> openDndSettings() async {
    await openNotificationPolicySettings();
  }
}