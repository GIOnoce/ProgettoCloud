import 'package:mytedx/models/suggestedTalk.dart';
import 'package:mytedx/models/talk.dart';

class WatchNextResponse {
  final Talk talk;
  final List<SuggestedTalk> suggestions;

  WatchNextResponse({
    required this.talk,
    required this.suggestions,
  });

  factory WatchNextResponse.fromJSON(Map<String, dynamic> jsonMap) {
    return WatchNextResponse(
      talk: Talk.fromJSON(jsonMap['talk']),
      suggestions: (jsonMap['suggestions'] as List<dynamic>?)
              ?.map((json) => SuggestedTalk.fromJSON(json))
              .toList() ??
          [],
    );
  }
}