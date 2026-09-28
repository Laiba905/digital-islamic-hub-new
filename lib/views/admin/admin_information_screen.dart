import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminInformationScreen extends StatefulWidget {
  const AdminInformationScreen({super.key});

  @override
  State<AdminInformationScreen> createState() => _AdminInformationScreenState();
}

class _AdminInformationScreenState extends State<AdminInformationScreen> {
  final _feeController = TextEditingController();
  final _easyPaisaNumController = TextEditingController();
  final _easyPaisaNameController = TextEditingController();
  final _jazzCashNumController = TextEditingController();
  final _jazzCashNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingSettings();
  }

  void _loadExistingSettings() async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('payment_details')
          .get();

      if (doc.exists && doc.data() != null) {
        var data = doc.data()!;
        setState(() {
          _feeController.text = data['feeAmount']?.toString() ?? '';
          _easyPaisaNumController.text = data['easyPaisaNumber'] ?? '';
          _easyPaisaNameController.text = data['easyPaisaName'] ?? '';
          _jazzCashNumController.text = data['jazzCashNumber'] ?? '';
          _jazzCashNameController.text = data['jazzCashName'] ?? '';
        });
      }
    } catch (e) {
      // Handle error quietly
    }
  }

  void _saveSettings() async {
    if (_feeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the Question Processing Fee!"), backgroundColor: Colors.red),
      );
      return;
    }

    bool hasEasyPaisa = _easyPaisaNumController.text.isNotEmpty || _easyPaisaNameController.text.isNotEmpty;
    bool hasJazzCash = _jazzCashNumController.text.isNotEmpty || _jazzCashNameController.text.isNotEmpty;

    if (!hasEasyPaisa && !hasJazzCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill at least one payment method (EasyPaisa or JazzCash)!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('app_settings')
          .doc('payment_details')
          .set({
        'feeAmount': _feeController.text.trim(),
        'easyPaisaNumber': _easyPaisaNumController.text.trim(),
        'easyPaisaName': _easyPaisaNameController.text.trim(),
        'jazzCashNumber': _jazzCashNumController.text.trim(),
        'jazzCashName': _jazzCashNameController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Admin Information changed successfully! 🚀"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Information"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(screenWidth < 600 ? 16.0 : 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Fee Management",
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF004D40)
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Update fee and account details for user payments.",
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 13),
                    ),
                    const Divider(height: 40),

                    // Fee Section
                    const Text("Question Processing Fee (Rs.)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "e.g: 50",
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // EasyPaisa Section
                    Text("EasyPaisa Account", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? const Color(0xFF81C784) : Colors.green.shade700)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _easyPaisaNumController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "Mobile Number",
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _easyPaisaNameController,
                      decoration: const InputDecoration(
                        hintText: "Account Title / Owner Name",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // JazzCash Section
                    Text("JazzCash Account", 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jazzCashNumController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: "Mobile Number",
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _jazzCashNameController,
                      decoration: const InputDecoration(
                        hintText: "Account Title / Owner Name",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Save / Change Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSettings,
                        child: _isLoading
                            ? CircularProgressIndicator(color: isDark ? Colors.black : Colors.white)
                            : const Text("SAVE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feeController.dispose();
    _easyPaisaNumController.dispose();
    _easyPaisaNameController.dispose();
    _jazzCashNumController.dispose();
    _jazzCashNameController.dispose();
    super.dispose();
  }
}
