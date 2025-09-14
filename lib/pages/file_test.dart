import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestFilePage extends StatefulWidget {
  const TestFilePage({super.key});

  @override
  State<TestFilePage> createState() => _TestFilePageState();
}

class _TestFilePageState extends State<TestFilePage> {
  String testResult = "Tap button to test file loading";
  bool isLoading = false;

  Future<void> testFileLoading() async {
    setState(() {
      isLoading = true;
      testResult = "Testing file loading...";
    });

    try {
      // Test if file exists and can be loaded
      print('🔍 Attempting to load: assets/data/book_data.json');
      final String content = await rootBundle.loadString(
        'assets/data/book_data.json',
      );

      setState(() {
        testResult =
            """✅ SUCCESS! File loaded successfully!

File size: ${content.length} characters
First 500 characters:
${content.substring(0, content.length > 500 ? 500 : content.length)}...""";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        testResult =
            """❌ FAILED to load file!

Error: $e

Possible causes:
1. File not in assets/data/book_data.json
2. pubspec.yaml missing assets section
3. Need to run 'flutter clean' and 'flutter pub get'
4. File name is incorrect (case sensitive)""";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'JSON File Loading Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : testFileLoading,
              child: isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test File Loading'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    testResult,
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
    );
  }
}
