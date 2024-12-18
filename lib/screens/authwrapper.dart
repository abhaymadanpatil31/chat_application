import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/user_list_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localization file

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          } else {
            return UserListScreen(currentUser: user);
          }
        }
        return Scaffold(
          appBar: AppBar(
            title:
                Text(AppLocalizations.of(context)!.loading), // Localized title
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.green),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!
                      .pleaseWait, // Localized loading text
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
