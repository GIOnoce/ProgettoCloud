class Talk {
  final String title;
  final String slug;
  final String details;
  final String mainSpeaker;
  final String url;
  final List<String> keyPhrases;

  Talk({
    required this.title,
    required this.slug,
    required this.details,
    required this.mainSpeaker,
    required this.url,
    required this.keyPhrases,
  });

  // Original constructor for detailed talk data (used by getTalksByTag)
  Talk.fromJSON(Map<String, dynamic> jsonMap)
      : title = jsonMap['title'] ?? '',
        details = jsonMap['description'] ?? '',
        slug = jsonMap['slug'] ?? jsonMap['_id'] ?? jsonMap['id'] ?? '', // Try multiple ID fields
        mainSpeaker = jsonMap['speakers'] ?? '',
        url = jsonMap['url'] ?? '',
        keyPhrases = (jsonMap['comprehend_analysis']?['KeyPhrases'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

  // New constructor for simplified data from get_all lambda
  Talk.fromJSONSimplified(Map<String, dynamic> jsonMap)
      : title = jsonMap['title'] ?? 'Untitled Talk',
        details = jsonMap['description'] ?? '', // get_all might not return description
        slug = (jsonMap['_id'] ?? jsonMap['id'] ?? jsonMap['slug'] ?? '').toString(), // Try multiple ID fields
        mainSpeaker = jsonMap['speakers'] ?? 'Unknown Speaker',
        url = jsonMap['url'] ?? '',
        keyPhrases = _extractKeyPhrases(jsonMap); // Handle different key phrase formats

  // Helper method to extract key phrases from different response formats
  static List<String> _extractKeyPhrases(Map<String, dynamic> jsonMap) {
    // Try different possible locations for key phrases
    if (jsonMap['keyPhrases'] != null) {
      return (jsonMap['keyPhrases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }
    if (jsonMap['comprehend_analysis']?['KeyPhrases'] != null) {
      return (jsonMap['comprehend_analysis']['KeyPhrases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }
    // Return empty list if no key phrases found
    return [];
  }

  // Convert to JSON for serialization if needed
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'description': details,
      'speakers': mainSpeaker,
      'url': url,
      'comprehend_analysis': {
        'KeyPhrases': keyPhrases,
      },
    };
  }
}