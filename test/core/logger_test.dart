import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/core/logger.dart';

void main() {
  group('Logger', () {
    late Logger logger;

    setUp(() {
      logger = Logger();
      logger.clearLogs();
    });

    test('should log messages at different levels', () {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');
      logger.critical('Critical message');

      final logs = logger.getRecentLogs();
      expect(logs.length, 5);
      expect(logs[0].level, LogLevel.debug);
      expect(logs[1].level, LogLevel.info);
      expect(logs[2].level, LogLevel.warning);
      expect(logs[3].level, LogLevel.error);
      expect(logs[4].level, LogLevel.critical);
    });

    test('should filter logs by minimum level', () {
      logger.setMinLevel(LogLevel.warning);
      
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      final logs = logger.getRecentLogs();
      expect(logs.length, 2); // Only warning and error should be logged
      expect(logs[0].level, LogLevel.warning);
      expect(logs[1].level, LogLevel.error);
    });

    test('should get log statistics', () {
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');
      logger.error('Another error message');

      final stats = logger.getLogStats();
      expect(stats['DEBUG'], 1);
      expect(stats['INFO'], 1);
      expect(stats['WARNING'], 1);
      expect(stats['ERROR'], 2);
      expect(stats['CRITICAL'], 0);
    });

    test('should limit recent logs', () {
      for (int i = 0; i < 10; i++) {
        logger.info('Message $i');
      }

      final logs = logger.getRecentLogs(limit: 5);
      expect(logs.length, 5);
      expect(logs.last.message, 'Message 9');
    });

    test('should clear logs', () {
      logger.info('Test message');
      expect(logger.getRecentLogs().length, 1);

      logger.clearLogs();
      expect(logger.getRecentLogs().length, 0);
    });

    test('should export logs as string', () {
      logger.info('Test message');
      logger.error('Test error');

      final exported = logger.exportLogs();
      expect(exported.contains('EduConnect Log Export'), true);
      expect(exported.contains('Test message'), true);
      expect(exported.contains('Test error'), true);
    });
  });

  group('LogLevel', () {
    test('should have correct values', () {
      expect(LogLevel.debug.value, 0);
      expect(LogLevel.info.value, 1);
      expect(LogLevel.warning.value, 2);
      expect(LogLevel.error.value, 3);
      expect(LogLevel.critical.value, 4);
    });

    test('should have correct names', () {
      expect(LogLevel.debug.name, 'DEBUG');
      expect(LogLevel.info.name, 'INFO');
      expect(LogLevel.warning.name, 'WARNING');
      expect(LogLevel.error.name, 'ERROR');
      expect(LogLevel.critical.name, 'CRITICAL');
    });
  });

  group('LoggerMixin', () {
    test('should provide logging methods', () {
      final testClass = TestClassWithLogger();
      
      testClass.logInfo('Test info');
      testClass.logError('Test error');

      final logs = Logger().getRecentLogs();
      expect(logs.any((log) => log.message.contains('TestClassWithLogger: Test info')), true);
      expect(logs.any((log) => log.message.contains('TestClassWithLogger: Test error')), true);
    });
  });
}

class TestClassWithLogger with LoggerMixin {
  // Test class for LoggerMixin
}