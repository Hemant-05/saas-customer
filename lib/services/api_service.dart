import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CustomerApiService {
  static Future<Map<String, dynamic>> get(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      return _parse(response);
    } on SocketException {
      throw CustomerApiException('No internet connection', 0);
    } on CustomerApiException {
      rethrow;
    } catch (e) {
      throw CustomerApiException('Network error: $e', 0);
    }
  }

  static Future<Map<String, dynamic>> post(
      String url, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _parse(response);
    } on SocketException {
      throw CustomerApiException('No internet connection', 0);
    } on CustomerApiException {
      rethrow;
    } catch (e) {
      throw CustomerApiException('Network error: $e', 0);
    }
  }

  static Map<String, dynamic> _parse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        throw CustomerApiException(
            body['message'] ?? 'Server error', response.statusCode, data: body);
      }
    } on CustomerApiException {
      rethrow;
    } catch (_) {
      throw CustomerApiException(
          'Failed to parse response', response.statusCode);
    }
  }
}

class CustomerApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic data;
  CustomerApiException(this.message, this.statusCode, {this.data});
}
