import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/user_list_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import localization

class AuthWrapper extends StatelessWidget {
  final Function(Locale) setLocale;

  const AuthWrapper({super.key, required this.setLocale});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // If no user is logged in, show LoginScreen
            return LoginScreen(setLocale: setLocale); // Pass setLocale to LoginScreen
          } else {
            // If user is logged in, show UserListScreen
            return UserListScreen(
              currentUser: user,
              setLocale: setLocale, // Pass setLocale to UserListScreen
            );
          }
        }
        // While checking for the authentication state, show a loading spinner
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }
}
