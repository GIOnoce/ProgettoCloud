import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mytedx/models/talk.dart';
import 'package:mytedx/models/watchNextResponse.dart';
import 'dart:convert';

import 'package:mytedx/talk_repository.dart';

class TalkDetailPage extends StatefulWidget {
  final String talkId;
  final Talk? initialTalk;

  const TalkDetailPage({
    super.key,
    required this.talkId,
    this.initialTalk,
  });

  @override
  State<TalkDetailPage> createState() => _TalkDetailPageState();
}

class _TalkDetailPageState extends State<TalkDetailPage> {
  late Future<WatchNextResponse> _watchNextData;
  bool _hasLiked = false;
  bool _hasDisliked = false;

  @override
  void initState() {
    super.initState();
    print('🔍 TalkDetailPage initialized with talkId: ${widget.talkId}');
    
    // If we have initialTalk, print its details for debugging
    if (widget.initialTalk != null) {
      print('📋 Initial talk data:');
      print('  - Title: ${widget.initialTalk!.title}');
      print('  - Slug: ${widget.initialTalk!.slug}');
      print('  - Speaker: ${widget.initialTalk!.mainSpeaker}');
      print('  - Details: ${widget.initialTalk!.details}');
    }
    
    _watchNextData = getWatchNextById(widget.talkId);
  }

  Future<void> _sendFeedback(String feedback) async {
    try {
      await updatePercentage(widget.talkId, feedback);
      setState(() {
        if (feedback == 'positive') {
          _hasLiked = true;
          _hasDisliked = false;
        } else {
          _hasDisliked = true;
          _hasLiked = false;
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedback == 'positive' ? 'Thanks for the positive feedback!' : 'Thanks for the feedback!'),
            backgroundColor: feedback == 'positive' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Error sending feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send feedback'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talk Details'),
      ),
      body: FutureBuilder<WatchNextResponse>(
        future: _watchNextData,
        builder: (context, snapshot) {
          // Add detailed error logging
          if (snapshot.hasError) {
            print('❌ FutureBuilder error: ${snapshot.error}');
            print('❌ Error type: ${snapshot.error.runtimeType}');
            
            // Show more detailed error information
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading talk details",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Talk ID: ${widget.talkId}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}",
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _watchNextData = getWatchNextById(widget.talkId);
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Loading talk details...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            final data = snapshot.data!;
            final talk = data.talk;
            final suggestions = data.suggestions;

            print('✅ Successfully loaded talk data:');
            print('  - Title: ${talk.title}');
            print('  - Speaker: ${talk.mainSpeaker}');
            print('  - Suggestions count: ${suggestions.length}');

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Talk Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            talk.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            talk.mainSpeaker,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            talk.details.isNotEmpty ? talk.details : 'No description available',
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          if (talk.keyPhrases.isNotEmpty) ...[
                            const Text(
                              'Key Topics:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: talk.keyPhrases
                                  .map((phrase) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          phrase,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 20),
                          // Feedback Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _hasLiked ? null : () => _sendFeedback('positive'),
                                icon: Icon(_hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
                                label: const Text('Like'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasLiked ? Colors.green : Colors.grey.shade300,
                                  foregroundColor: _hasLiked ? Colors.white : Colors.black,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _hasDisliked ? null : () => _sendFeedback('negative'),
                                icon: Icon(_hasDisliked ? Icons.thumb_down : Icons.thumb_down_outlined),
                                label: const Text('Dislike'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasDisliked ? Colors.orange : Colors.grey.shade300,
                                  foregroundColor: _hasDisliked ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Watch Next Section
                  if (suggestions.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.play_arrow, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'Watch Next',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${suggestions.length} suggestions',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = suggestions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TalkDetailPage(
                                    talkId: suggestion.id,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: Colors.red.shade700,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          suggestion.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          suggestion.speakers,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Score: ${(suggestion.score * 100).toInt()}%',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Colors.grey.shade400,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'No suggestions available for this talk',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}