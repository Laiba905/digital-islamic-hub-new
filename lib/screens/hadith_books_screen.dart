import 'package:flutter/material.dart';
import 'hadith_chapters_screen.dart';

class HadithBooksScreen extends StatelessWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Map<String, dynamic>> books = [
      {"collection": "Abu Dawud", "display_name": "Sunan Abu Dawud"},
      {"collection": "Tirmidhi", "display_name": "Jami at-Tirmidhi"}
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFFF4F7F4),
      appBar: AppBar(
        title: const Text("Hadith Books", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF001F1A) : const Color(0xFF006400),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Card(
            color: isDark ? Colors.white.withAlpha(10) : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.menu_book, color: Colors.white),
              ),
              title: Text(
                book['display_name']!,
                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: const Text("View Chapters"),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HadithChaptersScreen(
                      collectionName: book['collection']!,
                      displayName: book['display_name']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}