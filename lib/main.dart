import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:admin/views/auth/login_view.dart';
import 'package:admin/views/admin/admin_dashboard_view.dart';
import 'package:admin/views/admin/profile_view.dart';
import 'package:admin/views/admin/user_management_hub_view.dart';
import 'package:admin/views/admin/manage_users_view.dart';
import 'package:admin/views/admin/user_analytics_view.dart';
import 'package:admin/views/admin/scholar_management_hub_view.dart';
import 'package:admin/views/admin/manage_scholars_view.dart';
import 'package:admin/views/admin/scholar_analytics_view.dart';
import 'package:admin/views/admin/sunnah_deeds_view.dart';
//import 'package:admin/views/admin/payment_management_view.dart';
import 'package:admin/views/admin/upload_books_view.dart';
import 'package:admin/view_models/theme_provider.dart';
import 'package:admin/view_models/profile_view_model.dart';
import 'firebase_options.dart';
import 'package:admin/views/admin/scholar_answer_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Admin Panel',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004D40)), useMaterial3: true),
          darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004D40), brightness: Brightness.dark), useMaterial3: true, brightness: Brightness.dark),
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginView(),
            '/dashboard': (context) => const AdminDashboardView(),
            '/profile': (context) => const ProfileView(),
            // User Flow
            '/user_hub': (context) => const UserManagementHubView(),
            '/manage_users': (context) => const ManageUsersView(),
            '/user_analytics': (context) => const UserAnalyticsView(),
            // Scholar Flow
            '/scholar_hub': (context) => const ScholarManagementHubView(),
            '/manage_scholars': (context) => const ManageScholarsPage(),
            '/scholar_analytics': (context) => const ScholarAnalyticsView(),
            // Others
            '/sunnah_deeds': (context) => const SunnahDeedsView(),
            //'/payments': (context) => const PaymentManagementView(),
            '/upload_books': (context) => UploadBooksView(), // 🟢 'const' yahan se hata diya gaya hai
            '/scholar_answer': (context) => const ScholarAnswerView(),
          },
        );
      },
    );
  }
}