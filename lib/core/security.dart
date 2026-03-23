import 'dart:io';
import 'package:flutter/services.dart';

/// 화면 캡처/녹화 방지
class ScreenSecurity {
  static const _channel = MethodChannel('show_me_bible/security');

  static Future<void> enableSecureMode() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('enableSecureMode');
      }
    } catch (_) {
      // 데스크탑/에뮬레이터 등 미지원 환경 무시
    }
  }

  static Future<void> disableSecureMode() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('disableSecureMode');
      }
    } catch (_) {}
  }
}
