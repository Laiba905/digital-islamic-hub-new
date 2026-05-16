import 'package:flutter/material.dart';
import 'hadith_chapters_screen.dart'; // Nayi screen ki import

class HadithBooksScreen extends StatelessWidget {
  const HadithBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Soft theme gradients for professional look
      backgroundColor: isDark ? const Color(0xFF002921) : const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text(
            "Hadith Books",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF004D40),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            _buildBookCard(
                context,
                displayName: "Sunan Abu Dawud",
                dbCollectionName: "Abu Dawud",
                icon: Icons.menu_book_rounded,
                color: Colors.teal,
                isDark: isDark
            ),
            const SizedBox(height: 16),
            _buildBookCard(
                context,
                displayName: "Jami at-Tirmidhi",
                dbCollectionName: "Tirmidhi",
                icon: Icons.auto_stories_rounded,
                color: Colors.orange,
                isDark: isDark
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard(
      BuildContext context, {
        required String displayName,
        required String dbCollectionName,
        required IconData icon,
        required Color color,
        required bool isDark
      }) {
    return GestureDetector(
      onTap: () {
        // Ab yeh direct list par nahi jayega, balke pehle Chapters screen khulegi
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HadithChaptersScreen(
              collectionName: dbCollectionName,
              displayName: displayName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withAlpha(15) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? Colors.white10 : Colors.green.shade50
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 12,
                  offset: const Offset(0, 4)
              )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withAlpha(35),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1B5E20)
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      "Tap to view chapters & sections",
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontSize: 12
                      )
                  ),
                ],
              ),
            ),
            Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.grey
            ),
          ],
        ),
      ),
    );
  }
}