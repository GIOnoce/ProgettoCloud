class SuggestedTalk {
  final String id;
  final String title;
  final String url;
  final String description;
  final String speakers;
  final double score;

  SuggestedTalk.fromJSON(Map<String, dynamic> jsonMap)
      : id = jsonMap['id'] ?? '',
        title = jsonMap['title'] ?? '',
        url = jsonMap['url'] ?? '',
        description = jsonMap['description'] ?? '',
        speakers = jsonMap['speakers'] ?? '',
        score = (jsonMap['score'] ?? 0).toDouble();
}