import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mytedx/models/talk.dart';

class FavoritesService {
  // Fixed URLs - replaced * with _
  static const String _addFavoriteUrl = 'https://b8mn9s8fci.execute-api.us-east-1.amazonaws.com/default/add_favorites';
  static const String _removeFavoriteUrl = 'https://kjyem3njdk.execute-api.us-east-1.amazonaws.com/default/remove_favorites';
  static const String _getFavoritesUrl = 'https://n8h10wz5tf.execute-api.us-east-1.amazonaws.com/default/get_favorites';

  static Future<bool> addToFavorites(String talkId) async {
    try {
      print('🔄 Adding to favorites: $talkId');
      final response = await http.post(
        Uri.parse(_addFavoriteUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'talkId': talkId,
        }),
      );
      
      print('📤 Add favorites response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('❌ Error adding to favorites: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  static Future<bool> removeFromFavorites(String talkId) async {
    try {
      print('🔄 Removing from favorites: $talkId');
      final response = await http.delete(
        Uri.parse(_removeFavoriteUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'talkId': talkId,
        }),
      );
      
      print('📤 Remove favorites response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Error removing from favorites: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  static Future<List<Talk>> getFavorites() async {
    try {
      print('🔄 Getting favorites...');
      final response = await http.get(
        Uri.parse(_getFavoritesUrl),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      print('📤 Get favorites response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> favoritesData = data['favorites'] ?? [];
        return favoritesData.map((item) {
          final talkData = item['talk'] ?? item['talkData'] ?? item;
          return Talk.fromJSONSimplified(talkData);
        }).toList();
      } else {
        print('❌ Error getting favorites: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting favorites: $e');
      return [];
    }
  }

  static Future<bool> isFavorite(String talkId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((talk) => talk.slug == talkId);
    } catch (e) {
      print('❌ Error checking if favorite: $e');
      return false;
    }
  }
}