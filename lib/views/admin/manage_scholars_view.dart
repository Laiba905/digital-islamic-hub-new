import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageScholarsPage extends StatelessWidget {
  const ManageScholarsPage({Key? key}) : super(key: key);

  // 📈 Dynamic Stream: Sirf approved scholars ki counting
  Stream<int> getScholarCount({String? statusValue}) {
    Query query = FirebaseFirestore.instance.collection('scholars').where('status', isEqualTo: 'approved');

    return query.snapshots().map((snapshot) {
      if (statusValue == 'blocked') {
        return snapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['accountStatus'] == 'blocked';
        }).length;
      } else if (statusValue == 'active') {
        return snapshot.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['accountStatus'] != 'blocked';
        }).length;
      } else {
        return snapshot.docs.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Approved Scholars"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: "Clear all approved scholars",
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Clear All Scholars"),
                  content: const Text("Are you sure you want to delete all approved scholars? This action cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete All", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  final querySnapshot = await FirebaseFirestore.instance
                      .collection('scholars')
                      .where('status', isEqualTo: 'approved')
                      .get();

                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in querySnapshot.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All approved scholars cleared successfully.")),
                    );
                  }
                } catch (e) {
                  debugPrint("Error clearing scholars: $e");
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Scholar Overview",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _counterCard(context, "Approved", getScholarCount(), colorScheme.primary, Icons.school_outlined),
                const SizedBox(width: 12),
                _counterCard(context, "Active", getScholarCount(statusValue: 'active'), Colors.green, Icons.check_circle_outline),
                const SizedBox(width: 12),
                _counterCard(context, "Blocked", getScholarCount(statusValue: 'blocked'), colorScheme.error, Icons.block_outlined),
              ],
            ),
            const SizedBox(height: 32),
            Text(
                "Approved Scholar List",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            _buildVerifiedScholarsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedScholarsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('scholars').where('status', isEqualTo: 'approved').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text(
                  "No approved scholars found.",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)
              ),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var scholar = docs[index].data() as Map<String, dynamic>;
            String docId = docs[index].id;

            bool isBlocked = scholar['accountStatus'] == 'blocked';
            String scholarEmail = scholar['email'] ?? 'No Email';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 1,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isBlocked
                      ? colorScheme.error.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.school,
                    color: isBlocked ? colorScheme.error : colorScheme.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  scholarEmail,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isBlocked ? Colors.grey : null,
                    decoration: isBlocked ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      tooltip: "Delete Scholar",
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('scholars')
                              .doc(docId)
                              .delete();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Scholar deleted successfully"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          debugPrint("Error deleting scholar: $e");
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 95,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('scholars').doc(docId).update({
                            'accountStatus': isBlocked ? 'active' : 'blocked',
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBlocked ? Colors.green.shade700 : colorScheme.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isBlocked ? "Unblock" : "Block",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _counterCard(BuildContext context, String title, Stream<int> stream, Color accentColor, IconData icon) {
    final theme = Theme.of(context);

    return Expanded(
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: accentColor, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.data?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}