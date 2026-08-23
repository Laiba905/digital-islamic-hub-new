import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current logged-in user ki ID hasil karne ke liye getter
  String get uid => _auth.currentUser?.uid ?? "guest_user";

  // Bookmark Toggle Function (Save aur Delete dono isi se honge)
  Future<bool> toggleBookmark(String collection, int hadithNo) async {
    DocumentReference ref = _firestore.collection('users_bookmarks').doc(uid);
    // Unique identifier banaya hai (e.g., "Abu Dawud_45")
    String bookmarkId = "${collection}_$hadithNo";

    DocumentSnapshot doc = await ref.get();
    if (doc.exists) {
      List items = (doc.data() as Map)['hadith_bookmarks'] ?? [];
      if (items.contains(bookmarkId)) {
        // Agar pehle se mojud hai to remove (Delete) kar do
        await ref.update({'hadith_bookmarks': FieldValue.arrayRemove([bookmarkId])});
        return false; // Indicating removed
      }
    }
    // Agar mojud nahi hai to add (Save) kar do
    await ref.set({'hadith_bookmarks': FieldValue.arrayUnion([bookmarkId])}, SetOptions(merge: true));
    return true; // Indicating added
  }

  // Real-time updates ke liye stream getter
  Stream<DocumentSnapshot> getBookmarksStream() {
    return _firestore.collection('users_bookmarks').doc(uid).snapshots();
  }
}