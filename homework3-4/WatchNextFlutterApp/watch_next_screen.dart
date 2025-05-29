import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WatchNextScreen extends StatelessWidget {
  final String talkId;

  const WatchNextScreen({required this.talkId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video suggeriti')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.fetchWatchNext(talkId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return Center(child: Text('Nessun suggerimento trovato.'));

          final talks = snapshot.data!;
          return ListView.builder(
            itemCount: talks.length,
            itemBuilder: (context, index) {
              final talk = talks[index];
              return ListTile(
                leading: Icon(Icons.play_circle_outline),
                title: Text(talk['title'] ?? 'Titolo non disponibile'),
                subtitle: Text((talk['tags'] as List<dynamic>).join(', ')),
              );
            },
          );
        },
      ),
    );
  }
}
