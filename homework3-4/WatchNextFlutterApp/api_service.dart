import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://tuo-api-url.amazonaws.com/dev';

  static Future<List<Map<String, dynamic>>> fetchWatchNext(String talkId) async {
    final url = Uri.parse('$baseUrl/watchnext?id=$talkId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return List<Map<String, dynamic>>.from(decoded['watch_next'] ?? []);
    } else {
      throw Exception('Errore durante il recupero dei dati');
    }
  }
}
