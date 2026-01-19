import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlDisplay extends StatelessWidget {
  final String url;

  const UrlDisplay({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL скопирован')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Копировать'),
            ),
          ],
        ),
      ),
    );
  }
}
