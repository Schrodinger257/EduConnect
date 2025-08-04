import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Log levels for categorizing log messages
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARNING'),
  error(3, 'ERROR'),
  critical(4, 'CRITICAL');

  const LogLevel(this.value, this.name);
  
  final int value;
  final String name;
}

/// Comprehensive logging system for debugging and monitoring
class Logger {
  static final Logger _instance = Logger._internal();
  factory Logger() => _instance;
  Logger._internal();

  /// Current minimum log level to display
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  
  /// Whether to include timestamps in log messages
  bool _includeTimestamp = true;
  
  /// Whether to include stack traces for errors
  bool _includeStackTrace = true;
  
  /// Maximum number of log entries to keep in memory
  static const int _maxLogEntries = 1000;
  
  /// In-memory log storage for debugging
  final List<LogEntry> _logEntries = [];

  /// Sets the minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Configures logging options
  void configure({
    LogLevel? minLevel,
    bool? includeTimestamp,
    bool? includeStackTrace,
  }) {
    if (minLevel != null) _minLevel = minLevel;
    if (includeTimestamp != null) _includeTimestamp = includeTimestamp;
    if (includeStackTrace != null) _includeStackTrace = includeStackTrace;
  }

  /// Logs a debug message
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  /// Logs an info message
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  /// Logs a warning message
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  /// Logs an error message
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  /// Logs a critical error message
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, error: error, stackTrace: stackTrace);
  }

  /// Logs API requests for debugging
  void apiRequest(String method, String url, {Map<String, dynamic>? data}) {
    debug('API Request: $method $url${data != null ? '\nData: $data' : ''}');
  }

  /// Logs API responses for debugging
  void apiResponse(String method, String url, int statusCode, {dynamic data}) {
    final level = statusCode >= 400 ? LogLevel.error : LogLevel.debug;
    _log(level, 'API Response: $method $url - Status: $statusCode${data != null ? '\nData: $data' : ''}');
  }

  /// Logs user actions for analytics
  void userAction(String action, {Map<String, dynamic>? properties}) {
    info('User Action: $action${properties != null ? '\nProperties: $properties' : ''}');
  }

  /// Logs navigation events
  void navigation(String from, String to, {Map<String, dynamic>? arguments}) {
    debug('Navigation: $from -> $to${arguments != null ? '\nArguments: $arguments' : ''}');
  }

  /// Logs performance metrics
  void performance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    info('Performance: $operation took ${duration.inMilliseconds}ms${metrics != null ? '\nMetrics: $metrics' : ''}');
  }

  /// Core logging method
  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.value < _minLevel.value) return;

    final timestamp = DateTime.now();
    final formattedMessage = _formatMessage(level, message, timestamp);
    
    // Create log entry
    final logEntry = LogEntry(
      level: level,
      message: message,
      timestamp: timestamp,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Add to in-memory storage
    _addLogEntry(logEntry);
    
    // Output to console/developer log
    _outputLog(level, formattedMessage, error, stackTrace);
  }

  /// Formats the log message
  String _formatMessage(LogLevel level, String message, DateTime timestamp) {
    final buffer = StringBuffer();
    
    if (_includeTimestamp) {
      buffer.write('[${_formatTimestamp(timestamp)}] ');
    }
    
    buffer.write('[${level.name}] ');
    buffer.write(message);
    
    return buffer.toString();
  }

  /// Formats timestamp for log messages
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}.'
           '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Outputs log to appropriate destination
  void _outputLog(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // Use developer.log for better debugging in Flutter
    developer.log(
      message,
      name: 'EduConnect',
      level: level.value * 300, // Convert to developer log levels
      error: error,
      stackTrace: _includeStackTrace ? stackTrace : null,
    );

    // In debug mode, also print to console for immediate visibility
    if (kDebugMode) {
      print(message);
      if (error != null) {
        print('Error: $error');
      }
      if (_includeStackTrace && stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Adds log entry to in-memory storage
  void _addLogEntry(LogEntry entry) {
    _logEntries.add(entry);
    
    // Remove old entries if we exceed the limit
    if (_logEntries.length > _maxLogEntries) {
      _logEntries.removeAt(0);
    }
  }

  /// Gets recent log entries
  List<LogEntry> getRecentLogs({int? limit, LogLevel? minLevel}) {
    var logs = _logEntries.toList();
    
    if (minLevel != null) {
      logs = logs.where((log) => log.level.value >= minLevel.value).toList();
    }
    
    if (limit != null && logs.length > limit) {
      logs = logs.sublist(logs.length - limit);
    }
    
    return logs;
  }

  /// Clears all log entries
  void clearLogs() {
    _logEntries.clear();
  }

  /// Gets log statistics
  Map<String, int> getLogStats() {
    final stats = <String, int>{};
    
    for (final level in LogLevel.values) {
      stats[level.name] = _logEntries.where((log) => log.level == level).length;
    }
    
    return stats;
  }

  /// Exports logs as a formatted string
  String exportLogs({LogLevel? minLevel, int? limit}) {
    final logs = getRecentLogs(minLevel: minLevel, limit: limit);
    final buffer = StringBuffer();
    
    buffer.writeln('EduConnect Log Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('${'=' * 50}');
    
    for (final log in logs) {
      buffer.writeln(_formatMessage(log.level, log.message, log.timestamp));
      if (log.error != null) {
        buffer.writeln('Error: ${log.error}');
      }
      if (log.stackTrace != null && _includeStackTrace) {
        buffer.writeln('Stack trace:\n${log.stackTrace}');
      }
      buffer.writeln('-' * 30);
    }
    
    return buffer.toString();
  }
}

/// Represents a single log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'LogEntry(level: ${level.name}, message: $message, timestamp: $timestamp)';
  }
}

/// Extension methods for easier logging
extension LoggerExtension on Object {
  /// Logs this object as debug information
  void logDebug([String? message]) {
    Logger().debug(message ?? toString());
  }

  /// Logs this object as info
  void logInfo([String? message]) {
    Logger().info(message ?? toString());
  }

  /// Logs this object as a warning
  void logWarning([String? message]) {
    Logger().warning(message ?? toString());
  }

  /// Logs this object as an error
  void logError([String? message]) {
    Logger().error(message ?? toString(), error: this);
  }
}

/// Mixin for classes that need logging capabilities
mixin LoggerMixin {
  Logger get logger => Logger();
  
  void logDebug(String message, {Object? error, StackTrace? stackTrace}) {
    logger.debug('${runtimeType}: $message', error: error, stackTrace: stackTrace);
  }
  
  void logInfo(String message, {Object? error, StackTrace? stackTrace}) {
    logger.info('${runtimeType}: $message', error: error, stackTrace: stackTrace);
  }
  
  void logWarning(String message, {Object? error, StackTrace? stackTrace}) {
    logger.warning('${runtimeType}: $message', error: error, stackTrace: stackTrace);
  }
  
  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    logger.error('${runtimeType}: $message', error: error, stackTrace: stackTrace);
  }
  
  void logUserAction(String action, {Map<String, dynamic>? properties}) {
    logger.userAction('${runtimeType}: $action', properties: properties);
  }
  
  void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    logger.performance('${runtimeType}: $operation', duration, metrics: metrics);
  }
}