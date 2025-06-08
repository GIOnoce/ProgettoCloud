import 'package:http/http.dart' as http;
import 'package:mytedx/models/watchNextResponse.dart';
import 'dart:convert';
import 'models/talk.dart';

Future<List<Talk>> initEmptyList() async {
  Iterable list = json.decode("[]");
  var talks = list.map((model) => Talk.fromJSON(model)).toList();
  return talks;
}

// New function to get all talks using your get_all lambda
Future<List<Talk>> getAllTalks() async {
  var url = Uri.parse('https://vxjuseypj5.execute-api.us-east-1.amazonaws.com/default/get_all');
  
  try {
    print('🔄 Fetching talks from: $url');
    
    final http.Response response = await http.get(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    );

    print('📡 Response status: ${response.statusCode}');
    print('📄 Response body preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final Map<String, dynamic> responseData = json.decode(body);
      
      print('✅ Parsed response data keys: ${responseData.keys.toList()}');
      
      // Check if the response has the expected structure from your lambda
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> talksData = responseData['data'];
        print('📊 Found ${talksData.length} talks in response');
        
        if (talksData.isNotEmpty) {
          print('🔍 First talk sample: ${talksData.first}');
        }
        
        final talks = talksData.map((talkJson) => Talk.fromJSONSimplified(talkJson)).toList();
        print('✨ Successfully converted ${talks.length} talks');
        return talks;
      } else {
        print('❌ Invalid response structure');
        print('Response data: $responseData');
        throw Exception('Invalid response format: ${responseData['message'] ?? 'Unknown error'}');
      }
    } else {
      print('❌ HTTP Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load talks. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('💥 Error in getAllTalks: $e');
    // For debugging, let's also try to return some mock data temporarily
    if (e.toString().contains('YOUR_API_GATEWAY_URL')) {
      print('⚠️  API URL not configured - returning empty list');
      return [];
    }
    rethrow;
  }
}

Future<List<Talk>> getTalksByTag(String tag, int page) async {
  var url = Uri.parse('https://nddgkp6wm1.execute-api.us-east-1.amazonaws.com/default/Get_Talks_By_Tag');
  
  print('🏷️  Searching talks by tag: "$tag", page: $page');
  
  final http.Response response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, Object>{
      'tag': tag,
      'page': page,
      'doc_per_page': 6
    }),
  );
  
  print('📡 getTalksByTag response status: ${response.statusCode}');
  print('📄 getTalksByTag response preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}...');
  
  if (response.statusCode == 200) {
    final body = utf8.decode(response.bodyBytes);
    final List<dynamic> jsonList = json.decode(body);
    
    print('📊 Found ${jsonList.length} talks from tag search');
    if (jsonList.isNotEmpty) {
      print('🔍 First tag search result sample: ${jsonList.first}');
    }
    
    final talks = jsonList.map((json) => Talk.fromJSON(json)).toList();
    print('✨ Successfully converted ${talks.length} talks from tag search');
    
    return talks;
  } else {
    print('❌ getTalksByTag failed with status: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to load talks');
  }
}

Future<WatchNextResponse> getWatchNextById(String talkId) async {
  var url = Uri.parse('https://psx5gnagz8.execute-api.us-east-1.amazonaws.com/default/get_watch_next_by_id');
  
  print('🎬 Getting watch next data for talkId: "$talkId"');
  
  try {
    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object>{
        'talkId': talkId,
      }),
    );
    
    print('📡 getWatchNextById response status: ${response.statusCode}');
    print('📄 getWatchNextById response length: ${response.body.length}');
    
    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      
      // Let's see the raw response structure
      print('🔍 Raw response preview: ${body.substring(0, body.length > 500 ? 500 : body.length)}...');
      
      final Map<String, dynamic> jsonMap = json.decode(body);
      print('✅ Parsed JSON keys: ${jsonMap.keys.toList()}');
      
      // Check if we have the expected structure
      if (jsonMap.containsKey('talk')) {
        print('📋 Talk data keys: ${jsonMap['talk']?.keys?.toList() ?? 'null'}');
        
        // Debug the talk object specifically
        if (jsonMap['talk'] != null) {
          final talkData = jsonMap['talk'];
          print('🔍 Talk details:');
          print('  - title: ${talkData['title']}');
          print('  - slug: ${talkData['slug']}');
          print('  - _id: ${talkData['_id']}');
          print('  - id: ${talkData['id']}');
          print('  - speakers: ${talkData['speakers']}');
          print('  - description: ${talkData['description']}');
        }
      }
      
      if (jsonMap.containsKey('suggestions')) {
        print('📋 Suggestions count: ${jsonMap['suggestions']?.length ?? 0}');
      }
      
      final watchNext = WatchNextResponse.fromJSON(jsonMap);
      print('✨ Successfully created WatchNextResponse');
      return watchNext;
    } else {
      print('❌ getWatchNextById failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load watch next data. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('💥 Error in getWatchNextById: $e');
    print('Error type: ${e.runtimeType}');
    rethrow;
  }
}

Future<void> updatePercentage(String talkId, String feedback) async {
  var url = Uri.parse('https://finvvtwuj1.execute-api.us-east-1.amazonaws.com/default/update_percentage');
  
  print('👍 Sending feedback: $feedback for talkId: $talkId');
  
  final http.Response response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, Object>{
      'talkId': talkId,
      'feedback': feedback,
      'userId': 'anonymous',
    }),
  );
  
  print('📡 updatePercentage response status: ${response.statusCode}');
  
  if (response.statusCode != 200) {
    print('❌ updatePercentage failed: ${response.body}');
    throw Exception('Failed to update feedback');
  }
}