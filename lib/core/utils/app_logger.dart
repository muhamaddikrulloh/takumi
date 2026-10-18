import 'package:flutter/foundation.dart';

void logDebug(String message, {Object? error, StackTrace? stackTrace}) {
  if (!kDebugMode) return;
  debugPrint(error == null ? message : '$message: $error');
  if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
}
