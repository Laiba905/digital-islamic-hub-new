import 'package:flutter/material.dart';

class ProfileViewModel extends ChangeNotifier {
  String _adminName = "Administrator";
  String? _profileImageUrl;

  String get adminName => _adminName;
  String? get profileImageUrl => _profileImageUrl;

  void updateName(String newName) {
    _adminName = newName;
    notifyListeners();
  }

  void updateProfileImageUrl(String url) {
    _profileImageUrl = url;
    notifyListeners();
  }

  void logout(BuildContext context) {
    // Navigate back to Login (root route '/') and clear all previous history
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
