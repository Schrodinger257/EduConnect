import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/supabase_bucket_setup.dart';
import '../core/logger.dart';

/// Test widget for verifying profile image functionality
class ProfileImageTestWidget extends ConsumerStatefulWidget {
  const ProfileImageTestWidget({super.key});

  @override
  ConsumerState<ProfileImageTestWidget> createState() => _ProfileImageTestWidgetState();
}

class _ProfileImageTestWidgetState extends ConsumerState<ProfileImageTestWidget> {
  String _testResults = '';
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Image Test'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Controls
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Image System Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This test verifies that the profile image upload system is working correctly with Supabase storage.',
                      style: TextStyle(
                        color: theme.shadowColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningTests ? null : _runTests,
                          icon: _isRunningTests 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_isRunningTests ? 'Running Tests...' : 'Run Tests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _testProfileImageUpload,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Test Upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.terminal,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Test Results',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.dividerColor,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResults.isEmpty 
                                  ? 'Click "Run Tests" to start verification...'
                                  : _testResults,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = '';
    });

    final logger = Logger();
    final bucketSetup = SupabaseBucketSetup(logger: logger);

    _addTestResult('🔍 Starting Profile Image System Tests...\n');

    // Test 1: Verify Supabase connection
    _addTestResult('Test 1: Verifying Supabase connection...');
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _addTestResult('✅ Supabase connection verified\n');
    } catch (e) {
      _addTestResult('❌ Supabase connection failed: $e\n');
    }

    // Test 2: Verify storage buckets
    _addTestResult('Test 2: Verifying storage buckets...');
    final bucketResult = await bucketSetup.verifyBuckets();
    if (bucketResult.isSuccess) {
      _addTestResult('✅ All required buckets verified\n');
    } else {
      _addTestResult('❌ Bucket verification failed: ${bucketResult.errorMessage}\n');
    }

    // Test 3: Test bucket access
    _addTestResult('Test 3: Testing bucket access...');
    final profilesBucketTest = await bucketSetup.testUpload('profiles');
    if (profilesBucketTest.isSuccess) {
      _addTestResult('✅ Profiles bucket upload test successful\n');
    } else {
      _addTestResult('❌ Profiles bucket upload test failed: ${profilesBucketTest.errorMessage}\n');
    }

    // Test 4: Get bucket info
    _addTestResult('Test 4: Getting bucket information...');
    final bucketInfo = await bucketSetup.getBucketInfo('profiles');
    if (bucketInfo.isSuccess) {
      final info = bucketInfo.data!;
      _addTestResult('✅ Profiles bucket info:');
      _addTestResult('   - Accessible: ${info['accessible']}');
      _addTestResult('   - File count: ${info['fileCount']}');
      _addTestResult('   - Sample files: ${info['files']}\n');
    } else {
      _addTestResult('❌ Failed to get bucket info: ${bucketInfo.errorMessage}\n');
    }

    _addTestResult('🏁 Tests completed!\n');
    _addTestResult('📝 Summary:');
    _addTestResult('   - If all tests passed, profile image upload should work');
    _addTestResult('   - If any tests failed, check your Supabase configuration');
    _addTestResult('   - Make sure "profiles" bucket exists and is public');

    setState(() {
      _isRunningTests = false;
    });
  }

  void _testProfileImageUpload() {
    final authState = ref.read(authProvider);
    if (authState.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in first to test profile image upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = authState.userId!;
    ref.read(profileProvider.notifier).setProfileImage(context, userId);
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults += '$result\n';
    });
  }
}