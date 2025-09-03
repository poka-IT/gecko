import 'dart:collection';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Service for collecting and storing application logs for manual Sentry reports
class LogCollectionService {
  static LogCollectionService? _instance;
  static LogCollectionService get instance => _instance ??= LogCollectionService._();

  LogCollectionService._();

  // Store logs in a circular buffer with maximum capacity
  static const int maxLogEntries = 2000;
  final Queue<LogEntry> _logBuffer = Queue<LogEntry>();

  /// Initialize the log collection service
  void initialize() {
    // Override debugPrint to capture debug logs
    if (kDebugMode) {
      debugPrint = _captureDebugPrint;
    }

    // Add an initial log entry to indicate service started
    // Note: The global logger is now automatically configured in globals.dart
    addLogEntry(LogEntry(level: Level.info, message: 'Log collection service initialized', time: DateTime.now()));

    if (kDebugMode) {
      debugPrint('Log collection service: Ready to capture all app logs via global logger');
    }
  }

  /// Custom debugPrint that captures logs and forwards to original
  void _captureDebugPrint(String? message, {int? wrapWidth}) {
    if (message != null) {
      addLogEntry(LogEntry(level: Level.debug, message: message, time: DateTime.now()));
    }

    // Call original debugPrint
    debugPrintSynchronously(message, wrapWidth: wrapWidth);
  }

  /// Add a log entry to the buffer
  void addLogEntry(LogEntry entry) {
    _logBuffer.add(entry);

    // Remove oldest entries if buffer exceeds maximum size
    while (_logBuffer.length > maxLogEntries) {
      _logBuffer.removeFirst();
    }
  }

  /// Get the last N log entries (default: all available, max 2000)
  List<LogEntry> getRecentLogs({int? count}) {
    final requestedCount = count ?? _logBuffer.length;
    final actualCount = requestedCount > _logBuffer.length ? _logBuffer.length : requestedCount;

    return _logBuffer.toList().reversed.take(actualCount).toList().reversed.toList();
  }

  /// Get logs as formatted string for Sentry
  String getLogsAsString({int? count}) {
    final logs = getRecentLogs(count: count);
    final buffer = StringBuffer();

    buffer.writeln('=== Application Logs (${logs.length} entries) ===');
    buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (final log in logs) {
      buffer.writeln(log.toString());
    }

    return buffer.toString();
  }

  /// Clear all stored logs
  void clearLogs() {
    _logBuffer.clear();
  }

  /// Get log statistics
  Map<String, dynamic> getLogStatistics() {
    final levelCounts = <Level, int>{};

    for (final entry in _logBuffer) {
      levelCounts[entry.level] = (levelCounts[entry.level] ?? 0) + 1;
    }

    return {
      'total_entries': _logBuffer.length,
      'level_counts': levelCounts.map((level, count) => MapEntry(level.name, count)),
      'oldest_entry': _logBuffer.isNotEmpty ? _logBuffer.first.time.toIso8601String() : null,
      'newest_entry': _logBuffer.isNotEmpty ? _logBuffer.last.time.toIso8601String() : null,
    };
  }

  /// Add a manual log entry (for use by other services)
  void logMessage(String message, {Level level = Level.info, String? error, StackTrace? stackTrace}) {
    addLogEntry(LogEntry(level: level, message: message, time: DateTime.now(), error: error, stackTrace: stackTrace));
  }

  /// Log an error with stack trace
  void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    addLogEntry(
      LogEntry(
        level: Level.error,
        message: message,
        time: DateTime.now(),
        error: error.toString(),
        stackTrace: stackTrace,
      ),
    );
  }

  /// Log a warning
  void logWarning(String message) {
    addLogEntry(LogEntry(level: Level.warning, message: message, time: DateTime.now()));
  }

  /// Log an info message
  void logInfo(String message) {
    addLogEntry(LogEntry(level: Level.info, message: message, time: DateTime.now()));
  }
}

/// Log entry model to store log information
class LogEntry {
  final Level level;
  final String message;
  final DateTime time;
  final String? error;
  final StackTrace? stackTrace;

  LogEntry({required this.level, required this.message, required this.time, this.error, this.stackTrace});

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${time.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write(message);

    if (error != null) {
      buffer.write(' | Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\nStackTrace: $stackTrace');
    }

    return buffer.toString();
  }
}

/// Custom logger output that captures logs for collection
class LogCollectionOutput extends LogOutput {
  final LogCollectionService _service;

  LogCollectionOutput(this._service);

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _service.addLogEntry(LogEntry(level: event.level, message: line, time: DateTime.now()));
    }
  }
}
