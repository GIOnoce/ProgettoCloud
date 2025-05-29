import 'package:flutter/material.dart';
import 'watch_next_screen.dart';

class HomeScreen extends StatelessWidget {
  final TextEditingController _idController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyTEDx Rewind'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Inserisci l\'ID del talk TEDx:'),
            TextField(
              controller: _idController,
              decoration: InputDecoration(hintText: 'Es: abc123'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_idController.text.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WatchNextScreen(talkId: _idController.text),
                    ),
                  );
                }
              },
              child: Text('Mostra suggerimenti'),
            ),
          ],
        ),
      ),
    );
  }
}
