import 'dart:convert';
import 'package:http/http.dart' as http;

class FastApiOcrService {
  // Production Render URL and Local dev fallbacks
  final String _renderUrl = 'https://recipto.onrender.com';
  final String _emulateUrl = 'http://10.0.2.2:8000';
  final String _localUrl = 'http://localhost:8000';

  Future<String> uploadAndExtractText(String filePath) async {
    try {
      // 1. Try production Render server first
      final request = http.MultipartRequest('POST', Uri.parse('$_renderUrl/ocr'));
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['error'] != null) {
          throw Exception(json['error']);
        }
        return json['text'] ?? 'No text extracted.';
      } else {
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (renderError) {
      // 2. Fallback to Emulator / Local if Render is unreachable or timing out
      try {
        final request = http.MultipartRequest('POST', Uri.parse('$_emulateUrl/ocr'));
        request.files.add(await http.MultipartFile.fromPath('file', filePath));
        final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return json['text'] ?? 'No text extracted.';
        }
      } catch (_) {
        try {
          final request = http.MultipartRequest('POST', Uri.parse('$_localUrl/ocr'));
          request.files.add(await http.MultipartFile.fromPath('file', filePath));
          final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
          final response = await http.Response.fromStream(streamedResponse);
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            return json['text'] ?? 'No text extracted.';
          }
        } catch (_) {}
      }
      
      throw Exception('Failed to connect to FastAPI OCR server: $renderError');
    }
  }
}
