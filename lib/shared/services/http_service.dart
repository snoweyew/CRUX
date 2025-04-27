import 'dart:convert';
import 'package:http/http.dart' as http;

class HttpService {
  final String baseUrl;

  HttpService({required this.baseUrl});

  Future<http.Response> post(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {
      ...defaultHeaders,
      ...?headers,
    };
    
    final body = jsonEncode(data);
    
    return await http.post(
      url,
      headers: mergedHeaders,
      body: body,
    );
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final defaultHeaders = {
      'Accept': 'application/json',
    };
    
    final mergedHeaders = {
      ...defaultHeaders,
      ...?headers,
    };
    
    return await http.get(url, headers: mergedHeaders);
  }
}
