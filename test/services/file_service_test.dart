import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:educonnect/services/file_service.dart';
import 'package:educonnect/core/core.dart';

import 'file_service_test.mocks.dart';

@GenerateMocks([SupabaseClient, SupabaseStorageClient, StorageFileApi, Logger])
void main() {
  group('FileService', () {
    late FileService fileService;
    late MockSupabaseClient mockSupabaseClient;
    late MockSupabaseStorageClient mockStorageClient;
    late MockStorageFileApi mockStorageFileApi;
    late MockLogger mockLogger;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockStorageClient = MockSupabaseStorageClient();
      mockStorageFileApi = MockStorageFileApi();
      mockLogger = MockLogger();

      when(mockSupabaseClient.storage).thenReturn(mockStorageClient);
      when(mockStorageClient.from('files')).thenReturn(mockStorageFileApi);

      fileService = FileService(
        supabase: mockSupabaseClient,
        logger: mockLogger,
      );
    });

    group('validateFile', () {
      test('should validate file successfully', () async {
        // Create a temporary test file
        final testFile = File('test_file.txt');
        await testFile.writeAsString('test content');

        final result = await fileService.validateFile(testFile);

        expect(result.isSuccess, true);

        // Clean up
        await testFile.delete();
      });

      test('should fail validation for non-existent file', () async {
        final testFile = File('non_existent_file.txt');

        final result = await fileService.validateFile(testFile);

        expect(result.isError, true);
        expect(result.errorMessage, 'File does not exist');
      });

      test('should fail validation for oversized file', () async {
        final testFile = File('large_test_file.txt');
        // Create a file larger than 1MB (default limit is 10MB, so we'll use a smaller limit)
        final largeContent = 'x' * (2 * 1024 * 1024); // 2MB
        await testFile.writeAsString(largeContent);

        final config = FileUploadConfig(maxSizeInMB: 1); // 1MB limit
        final result = await fileService.validateFile(testFile, config: config);

        expect(result.isError, true);
        expect(result.errorMessage, 'File size cannot exceed 1MB');

        // Clean up
        await testFile.delete();
      });

      test('should fail validation for invalid file extension', () async {
        final testFile = File('test_file.exe');
        await testFile.writeAsString('test content');

        const config = FileUploadConfig(
          allowedExtensions: ['.txt', '.pdf'],
        );
        final result = await fileService.validateFile(testFile, config: config);

        expect(result.isError, true);
        expect(result.errorMessage, 'Only .TXT, .PDF files are allowed');

        // Clean up
        await testFile.delete();
      });
    });

    group('uploadFile', () {
      test('should upload file successfully', () async {
        // Create a temporary test file
        final testFile = File('test_upload.txt');
        await testFile.writeAsString('test upload content');

        // Mock the upload response
        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'upload_success');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/files/test_upload.txt');

        final result = await fileService.uploadFile(
          testFile,
          userId: 'user123',
        );

        expect(result.isSuccess, true);
        expect(result.data!.name, 'test_upload.txt');
        expect(result.data!.url, 'https://example.com/files/test_upload.txt');
        expect(result.data!.uploadedBy, 'user123');

        verify(mockLogger.info('Uploading file: ${testFile.path}')).called(1);
        verify(mockLogger.info(argThat(contains('File uploaded successfully')))).called(1);

        // Clean up
        await testFile.delete();
      });

      test('should fail upload for invalid file', () async {
        final testFile = File('non_existent.txt');

        final result = await fileService.uploadFile(
          testFile,
          userId: 'user123',
        );

        expect(result.isError, true);
        expect(result.errorMessage, 'File does not exist');
      });

      test('should handle upload errors', () async {
        final testFile = File('test_error.txt');
        await testFile.writeAsString('test content');

        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenThrow(Exception('Upload failed'));

        final result = await fileService.uploadFile(
          testFile,
          userId: 'user123',
        );

        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to upload file'));

        verify(mockLogger.error(argThat(contains('Error uploading file')))).called(1);

        // Clean up
        await testFile.delete();
      });
    });

    group('uploadMultipleFiles', () {
      test('should upload multiple files successfully', () async {
        // Create test files
        final testFile1 = File('test1.txt');
        final testFile2 = File('test2.txt');
        await testFile1.writeAsString('content 1');
        await testFile2.writeAsString('content 2');

        // Mock successful uploads
        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((_) async => 'upload_success');

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/files/test.txt');

        final result = await fileService.uploadMultipleFiles(
          [testFile1, testFile2],
          userId: 'user123',
        );

        expect(result.isSuccess, true);
        expect(result.data!.length, 2);

        verify(mockLogger.info('Uploading 2 files')).called(1);
        verify(mockLogger.info('All 2 files uploaded successfully')).called(1);

        // Clean up
        await testFile1.delete();
        await testFile2.delete();
      });

      test('should handle partial upload failure', () async {
        final testFile1 = File('test1.txt');
        final testFile2 = File('test2.txt');
        await testFile1.writeAsString('content 1');
        await testFile2.writeAsString('content 2');

        // Mock first upload success, second upload failure
        when(mockStorageFileApi.uploadBinary(
          any,
          any,
          fileOptions: anyNamed('fileOptions'),
        )).thenAnswer((invocation) async {
          final path = invocation.positionalArguments[0] as String;
          if (path.contains('test1')) {
            return 'upload_success';
          } else {
            throw Exception('Upload failed');
          }
        });

        when(mockStorageFileApi.getPublicUrl(any))
            .thenReturn('https://example.com/files/test1.txt');

        // Mock cleanup call
        when(mockStorageFileApi.remove(any))
            .thenAnswer((_) async => []);

        final result = await fileService.uploadMultipleFiles(
          [testFile1, testFile2],
          userId: 'user123',
        );

        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to upload test2.txt'));

        // Clean up
        await testFile1.delete();
        await testFile2.delete();
      });
    });

    group('deleteFile', () {
      test('should delete file successfully', () async {
        when(mockStorageFileApi.remove(['test/file/path']))
            .thenAnswer((_) async => []);

        final result = await fileService.deleteFile('test/file/path');

        expect(result.isSuccess, true);
        verify(mockLogger.info('Deleting file: test/file/path')).called(1);
        verify(mockLogger.info('File deleted successfully: test/file/path')).called(1);
      });

      test('should handle delete errors', () async {
        when(mockStorageFileApi.remove(['test/file/path']))
            .thenThrow(Exception('Delete failed'));

        final result = await fileService.deleteFile('test/file/path');

        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to delete file'));
        verify(mockLogger.error(argThat(contains('Error deleting file')))).called(1);
      });
    });

    group('deleteMultipleFiles', () {
      test('should delete multiple files successfully', () async {
        final fileIds = ['file1', 'file2', 'file3'];
        when(mockStorageFileApi.remove(fileIds))
            .thenAnswer((_) async => []);

        final result = await fileService.deleteMultipleFiles(fileIds);

        expect(result.isSuccess, true);
        verify(mockLogger.info('Deleting 3 files')).called(1);
        verify(mockLogger.info('3 files deleted successfully')).called(1);
      });

      test('should handle multiple delete errors', () async {
        final fileIds = ['file1', 'file2'];
        when(mockStorageFileApi.remove(fileIds))
            .thenThrow(Exception('Delete failed'));

        final result = await fileService.deleteMultipleFiles(fileIds);

        expect(result.isError, true);
        expect(result.errorMessage, contains('Failed to delete files'));
      });
    });

    group('getFileInfo', () {
      test('should extract file info from URL', () async {
        const fileUrl = 'https://example.com/storage/v1/object/public/files/documents/test.pdf';

        final result = await fileService.getFileInfo(fileUrl);

        expect(result.isSuccess, true);
        expect(result.data!.name, 'test.pdf');
        expect(result.data!.url, fileUrl);
        expect(result.data!.mimeType, 'application/pdf');
      });

      test('should handle invalid URL format', () async {
        const invalidUrl = 'https://example.com/invalid';

        final result = await fileService.getFileInfo(invalidUrl);

        expect(result.isError, true);
        expect(result.errorMessage, 'Invalid file URL format');
      });
    });

    group('compressFile', () {
      test('should return original file for non-image types', () async {
        final testFile = File('test.txt');
        await testFile.writeAsString('test content');

        final result = await fileService.compressFile(testFile);

        expect(result.isSuccess, true);
        expect(result.data, testFile);

        verify(mockLogger.info('File type not supported for compression')).called(1);

        // Clean up
        await testFile.delete();
      });

      test('should handle compression for image files', () async {
        final testFile = File('test.jpg');
        await testFile.writeAsBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF])); // JPEG header

        final result = await fileService.compressFile(testFile);

        expect(result.isSuccess, true);
        verify(mockLogger.info('Image compression not implemented yet')).called(1);

        // Clean up
        await testFile.delete();
      });
    });

    group('FileUploadConfig', () {
      test('should have correct default configurations', () {
        expect(FileUploadConfig.image.maxSizeInMB, 5);
        expect(FileUploadConfig.image.allowedExtensions, contains('.jpg'));
        expect(FileUploadConfig.image.enableCompression, true);

        expect(FileUploadConfig.document.maxSizeInMB, 25);
        expect(FileUploadConfig.document.allowedExtensions, contains('.pdf'));

        expect(FileUploadConfig.pdf.maxSizeInMB, 50);
        expect(FileUploadConfig.pdf.allowedExtensions, ['.pdf']);

        expect(FileUploadConfig.video.maxSizeInMB, 100);
        expect(FileUploadConfig.video.allowedExtensions, contains('.mp4'));

        expect(FileUploadConfig.audio.maxSizeInMB, 25);
        expect(FileUploadConfig.audio.allowedExtensions, contains('.mp3'));
      });
    });

    group('FileInfo', () {
      test('should create FileInfo correctly', () {
        final fileInfo = FileInfo(
          id: 'test-id',
          name: 'test.jpg',
          url: 'https://example.com/test.jpg',
          mimeType: 'image/jpeg',
          sizeInBytes: 1024 * 1024, // 1MB
          uploadedAt: DateTime.now(),
          uploadedBy: 'user123',
        );

        expect(fileInfo.sizeInMB, 1.0);
        expect(fileInfo.extension, '.jpg');
        expect(fileInfo.isImage, true);
        expect(fileInfo.isDocument, false);
        expect(fileInfo.isVideo, false);
        expect(fileInfo.isAudio, false);
      });

      test('should serialize to and from JSON', () {
        final now = DateTime.now();
        final fileInfo = FileInfo(
          id: 'test-id',
          name: 'test.pdf',
          url: 'https://example.com/test.pdf',
          mimeType: 'application/pdf',
          sizeInBytes: 2048,
          uploadedAt: now,
          uploadedBy: 'user123',
          metadata: {'category': 'document'},
        );

        final json = fileInfo.toJson();
        final restored = FileInfo.fromJson(json);

        expect(restored.id, fileInfo.id);
        expect(restored.name, fileInfo.name);
        expect(restored.url, fileInfo.url);
        expect(restored.mimeType, fileInfo.mimeType);
        expect(restored.sizeInBytes, fileInfo.sizeInBytes);
        expect(restored.uploadedAt, fileInfo.uploadedAt);
        expect(restored.uploadedBy, fileInfo.uploadedBy);
        expect(restored.metadata, fileInfo.metadata);
      });

      test('should identify file types correctly', () {
        final imageFile = FileInfo(
          id: 'img',
          name: 'image.png',
          url: 'url',
          mimeType: 'image/png',
          sizeInBytes: 1024,
          uploadedAt: DateTime.now(),
          uploadedBy: 'user',
        );

        final docFile = FileInfo(
          id: 'doc',
          name: 'document.pdf',
          url: 'url',
          mimeType: 'application/pdf',
          sizeInBytes: 1024,
          uploadedAt: DateTime.now(),
          uploadedBy: 'user',
        );

        final videoFile = FileInfo(
          id: 'vid',
          name: 'video.mp4',
          url: 'url',
          mimeType: 'video/mp4',
          sizeInBytes: 1024,
          uploadedAt: DateTime.now(),
          uploadedBy: 'user',
        );

        final audioFile = FileInfo(
          id: 'aud',
          name: 'audio.mp3',
          url: 'url',
          mimeType: 'audio/mpeg',
          sizeInBytes: 1024,
          uploadedAt: DateTime.now(),
          uploadedBy: 'user',
        );

        expect(imageFile.isImage, true);
        expect(docFile.isDocument, true);
        expect(videoFile.isVideo, true);
        expect(audioFile.isAudio, true);
      });
    });
  });
}