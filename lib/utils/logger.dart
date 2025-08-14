import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Log {
  static void d(Object message) {
    if (kDebugMode) debugPrint('🟦 ${message.toString()}');
  }

  static void i(Object message) {
    debugPrint('ℹ️ ${message.toString()}');
  }

  static void w(Object message) {
    debugPrint('⚠️ ${message.toString()}');
  }

  static void e(Object message, [StackTrace? stackTrace]) {
    debugPrint('🟥 ${message.toString()}');
    if (kDebugMode && stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}


