import 'package:flutter_test/flutter_test.dart';
import 'package:educonnect/core/result.dart';

void main() {
  group('Result', () {
    test('should create successful result', () {
      final result = Result.success('test data');
      
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.data, 'test data');
      expect(result.errorMessage, null);
    });

    test('should create error result', () {
      final result = Result<String>.error('test error');
      
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.data, null);
      expect(result.errorMessage, 'test error');
    });

    test('should handle when method correctly', () {
      final successResult = Result.success(42);
      final errorResult = Result<int>.error('failed');
      
      final successValue = successResult.when(
        success: (data) => 'Success: $data',
        error: (message, exception) => 'Error: $message',
      );
      
      final errorValue = errorResult.when(
        success: (data) => 'Success: $data',
        error: (message, exception) => 'Error: $message',
      );
      
      expect(successValue, 'Success: 42');
      expect(errorValue, 'Error: failed');
    });

    test('should map success values correctly', () {
      final result = Result.success(5);
      final mapped = result.map((value) => value * 2);
      
      expect(mapped.isSuccess, true);
      expect(mapped.data, 10);
    });

    test('should preserve errors when mapping', () {
      final result = Result<int>.error('original error');
      final mapped = result.map((value) => value * 2);
      
      expect(mapped.isError, true);
      expect(mapped.errorMessage, 'original error');
    });

    test('should handle getOrElse correctly', () {
      final successResult = Result.success('success');
      final errorResult = Result<String>.error('error');
      
      expect(successResult.getOrElse('default'), 'success');
      expect(errorResult.getOrElse('default'), 'default');
    });

    test('should handle flatMap correctly', () {
      final result = Result.success(5);
      final flatMapped = result.flatMap((value) => 
        value > 0 ? Result.success(value * 2) : Result.error('negative'));
      
      expect(flatMapped.isSuccess, true);
      expect(flatMapped.data, 10);
    });

    test('should handle flatMap with error correctly', () {
      final result = Result.success(-5);
      final flatMapped = result.flatMap((value) => 
        value > 0 ? Result.success(value * 2) : Result.error('negative'));
      
      expect(flatMapped.isError, true);
      expect(flatMapped.errorMessage, 'negative');
    });
  });
}