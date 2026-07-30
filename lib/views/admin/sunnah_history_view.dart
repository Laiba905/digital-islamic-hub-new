import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================================
// 🚀 RESUABLE CODE H - (Yani yeh standalone page hai, ise kahin se bhi call kiya ja sakta hai)
// =========================================================================
// Maqsad: Admin ke bheje gaye saare purane aur naye deeds ka record dhoond kar display karna.

class SunnahHistoryView extends StatelessWidget {
  // 🌟 REUSABLE PARAMS: Yeh variables is screen ko reusable banate hain
  final String collectionName; // 📂 Jis collection se data uthana ho (e.g., 'daily_deeds')
  final String appBarTitle;    // 🏷️ Screen ka heading jo aap rakhna chahein
  final String emptyMessage;   // 📭 Agar data na mile to kya message dikhana hai

  const SunnahHistoryView({
    super.key,
    this.collectionName = 'daily_deeds', // Default value set kar di hai
    this.appBarTitle = 'All Published Deeds History',
    this.emptyMessage = 'History mein koi data nahi mila.',
  });

  // 📝 HELPER FUNCTION: Raw Firebase Timestamp ko readable Date & Time format mein tabdeel karne ke liye
  String _parseFirebaseTimestamp(dynamic firestoreTimestamp) {
    if (firestoreTimestamp == null) return 'N/A';

    // 🔥 FIX: '.dateTime' ki jagah '.toDate()' use kiya hai jo Timestamp ko standard DateTime mein badalta hai
    DateTime dateTime = (firestoreTimestamp as Timestamp).toDate();

    String year = dateTime.year.toString();
    String month = _getMonthName(dateTime.month);
    String day = dateTime.day.toString().padLeft(2, '0');

    // 12-Hour format (AM/PM) logic
    int hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    if (hour == 0) hour = 12;
    String minute = dateTime.minute.toString().padLeft(2, '0');
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';

    return "$day $month $year, $hour:$minute $amPm";
  }

  // Month number ko short English name mein convert karne ke liye helper
  String _getMonthName(int monthNum) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[monthNum - 1];
  }

  @override
  Widget build(BuildContext context) {
    // 🖥️ RESPONSIVE MEDIA QUERIES: Web, Android app, aur iOS ke size ke mutabik adjustment
    final screenWidth = MediaQuery.of(context).size.width;

    // 📱 Platform layout control: Agar bari screen (Web/Tablet) hai to padding zyada hogi, mobile par kam.
    final double horizontalPadding = screenWidth > 800 ? 40.0 : 16.0;
    final double verticalPadding = screenWidth > 800 ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: const Color(0xFF004D40),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 📱 iOS & Android Safe Area Guard: Notch aur bottom bars se UI ko safe rakhne ke liye
      body: SafeArea(
        child: Center(
          // 📐 WEB MAX WIDTH CONSTRAINT: Web browser par layout ko bohot phailne (stretch hone) se rokta hai
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
            child: StreamBuilder<QuerySnapshot>(
              // 🚀 REUSABLE STREAM: Jo collection name parameter mein aya, usi ka snapshot chalega
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // 🔄 Connection Waiting State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF004D40)),
                  );
                }

                // 📭 Empty Data Check
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(color: Colors.grey, fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                  );
                }

                // 📋 List View: Fully flexible for all platforms
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    // Parsing Time function trigger
                    String formattedDateTime = _parseFirebaseTimestamp(data['createdAt']);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        // 🟢 Points Badge
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE0F2F1),
                          child: Text(
                            "+${data['points'] ?? 10}",
                            style: const TextStyle(color: Color(0xFF004D40), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // 🟢 Title
                        title: Text(
                          data['title'] ?? 'No Title',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        // 🟢 Subtitle with Responsive wrapping text
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Published on: $formattedDateTime",
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  overflow: TextOverflow.ellipsis, // Mobile par text katne se bachata hai
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}