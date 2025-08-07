import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../core/logger.dart';
import '../core/result.dart';

/// Utility class for setting up and verifying Supabase storage buckets
class SupabaseBucketSetup {
  final SupabaseClient _supabase;
  final Logger _logger;

  SupabaseBucketSetup({
    SupabaseClient? supabase,
    Logger? logger,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _logger = logger ?? Logger();

  /// Verifies that required buckets exist and are properly configured
  Future<Result<void>> verifyBuckets() async {
    try {
      _logger.info('Verifying Supabase storage buckets...');

      final requiredBuckets = [
        'profiles',  // For profile images
        'files',     // For general file uploads
      ];

      for (final bucketName in requiredBuckets) {
        final result = await _verifyBucket(bucketName);
        if (result.isError) {
          return result;
        }
      }

      _logger.info('All required buckets verified successfully');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error verifying buckets: $e');
      return Result.error('Failed to verify buckets: ${e.toString()}');
    }
  }

  /// Verifies a specific bucket exists and is accessible
  Future<Result<void>> _verifyBucket(String bucketName) async {
    try {
      _logger.info('Verifying bucket: $bucketName');

      // Try to list files in the bucket (this will fail if bucket doesn't exist)
      await _supabase.storage.from(bucketName).list();
      
      _logger.info('Bucket $bucketName verified successfully');
      return Result.success(null);
    } catch (e) {
      _logger.error('Bucket $bucketName verification failed: $e');
      
      // Check if it's a "bucket not found" error
      if (e.toString().contains('Bucket not found') || 
          e.toString().contains('relation "storage.buckets" does not exist')) {
        return Result.error(
          'Bucket "$bucketName" does not exist. Please create it in your Supabase dashboard.\n'
          'Go to Storage > Create bucket > Name: "$bucketName" > Public: true'
        );
      }
      
      return Result.error('Failed to verify bucket $bucketName: ${e.toString()}');
    }
  }

  /// Creates the required buckets (if you have admin permissions)
  Future<Result<void>> createRequiredBuckets() async {
    try {
      _logger.info('Creating required Supabase storage buckets...');

      final bucketsToCreate = [
        {
          'name': 'profiles',
          'public': true,
          'allowedMimeTypes': ['image/jpeg', 'image/png', 'image/jpg'],
          'fileSizeLimit': 5 * 1024 * 1024, // 5MB
        },
        {
          'name': 'files',
          'public': true,
          'allowedMimeTypes': null, // Allow all file types
          'fileSizeLimit': 100 * 1024 * 1024, // 100MB
        },
      ];

      for (final bucketConfig in bucketsToCreate) {
        final result = await _createBucket(bucketConfig);
        if (result.isError) {
          _logger.warning('Failed to create bucket ${bucketConfig['name']}: ${result.errorMessage}');
          // Continue with other buckets even if one fails
        }
      }

      _logger.info('Bucket creation process completed');
      return Result.success(null);
    } catch (e) {
      _logger.error('Error creating buckets: $e');
      return Result.error('Failed to create buckets: ${e.toString()}');
    }
  }

  /// Creates a specific bucket with configuration
  Future<Result<void>> _createBucket(Map<String, dynamic> config) async {
    try {
      final bucketName = config['name'] as String;
      final isPublic = config['public'] as bool;
      
      _logger.info('Creating bucket: $bucketName');

      // Note: Bucket creation via client SDK might not be available
      // This is typically done through the Supabase dashboard or admin API
      await _supabase.storage.createBucket(
        bucketName,
        BucketOptions(
          public: isPublic,
          allowedMimeTypes: config['allowedMimeTypes'] as List<String>?,
          fileSizeLimit: (config['fileSizeLimit'] as int?)?.toString(),
        ),
      );

      _logger.info('Bucket $bucketName created successfully');
      return Result.success(null);
    } catch (e) {
      _logger.error('Failed to create bucket ${config['name']}: $e');
      return Result.error('Failed to create bucket: ${e.toString()}');
    }
  }

  /// Gets bucket information
  Future<Result<Map<String, dynamic>>> getBucketInfo(String bucketName) async {
    try {
      _logger.info('Getting info for bucket: $bucketName');

      // List files to verify access
      final files = await _supabase.storage.from(bucketName).list();
      
      final info = {
        'name': bucketName,
        'accessible': true,
        'fileCount': files.length,
        'files': files.take(5).map((f) => f.name).toList(), // First 5 files
      };

      _logger.info('Bucket $bucketName info retrieved successfully');
      return Result.success(info);
    } catch (e) {
      _logger.error('Failed to get bucket info for $bucketName: $e');
      return Result.error('Failed to get bucket info: ${e.toString()}');
    }
  }

  /// Tests file upload to a bucket
  Future<Result<String>> testUpload(String bucketName) async {
    try {
      _logger.info('Testing upload to bucket: $bucketName');

      // Create a small test file
      final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final testContent = 'Test file for bucket verification';
      
      // Upload test file
      await _supabase.storage
          .from(bucketName)
          .uploadBinary(
            testFileName,
            Uint8List.fromList(utf8.encode(testContent)),
            fileOptions: const FileOptions(
              contentType: 'text/plain',
              upsert: true,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(bucketName)
          .getPublicUrl(testFileName);

      // Clean up test file
      await _supabase.storage
          .from(bucketName)
          .remove([testFileName]);

      _logger.info('Upload test successful for bucket: $bucketName');
      return Result.success(publicUrl);
    } catch (e) {
      _logger.error('Upload test failed for bucket $bucketName: $e');
      return Result.error('Upload test failed: ${e.toString()}');
    }
  }
}