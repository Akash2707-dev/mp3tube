import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000"; // Change if hosting elsewhere

  static Future<Map<String, dynamic>> searchVideos(String query, int page) async {
    final response = await http.get(Uri.parse('$baseUrl/search?query=$query&page=$page'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load results');
    }
  }
}
