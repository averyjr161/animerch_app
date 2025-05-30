import 'package:animerch_app/screens/admin/admin_home_screen.dart';
import 'package:animerch_app/screens/user/user_app_first_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthStateHandler(),
    );
  }
}

/// Widget that listens to authentication state changes
/// and fetches user role to navigate accordingly.
class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  User? _currentUser;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
  }

  /// Listens to Firebase Auth state changes.
  /// On user login, fetches user role from Firestore.
  void _initializeAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _userRole = null;  // Reset user role on login/logout.
      });

      if (user != null) {
        _fetchUserRole(user.uid);
      }
    });
  }

  /// Fetches the user's role from Firestore 'users' collection.
  Future<void> _fetchUserRole(String uid) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection("users").doc(uid).get();
      if (!mounted) return;

      if (userDoc.exists && userDoc.data()?.containsKey('role') == true) {
        setState(() {
          _userRole = userDoc['role'] as String?;
        });
      } else {
        setState(() {
          _userRole = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userRole = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user not logged in, show login screen.
    if (_currentUser == null) {
      return const LoginScreen();
    }

    // While fetching role, show loading indicator.
    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Navigate based on user role.
    return _userRole == "Admin"
        ? const AdminHomeScreen()
        : const UserAppFirstScreen();
  }
}
