import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'Settings.dart'; // Import the settings page

class UserListScreen extends StatelessWidget {
  final User currentUser;
  final Function(Locale) setLocale; // Add setLocale parameter
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserListScreen(
      {required this.currentUser,
      required this.setLocale}); // Accept setLocale in constructor

  // Function to navigate to settings page
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          setLocale: setLocale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localization.chatWithUsers, // Localized string
          style: GoogleFonts.mukta(
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                _navigateToSettings(context), // Navigate to settings
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[100],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: currentUser.photoURL != null
                      ? NetworkImage(currentUser.photoURL!)
                      : null,
                  child: currentUser.photoURL == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.displayName ??
                            localization.unknownUser, // Localized string
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(currentUser.email ?? ''),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final user = doc.data() as Map<String, dynamic>;
                    if (user['email'] != currentUser.email) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user['photoURL'] != null
                              ? NetworkImage(user['photoURL'])
                              : null,
                          child: user['photoURL'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(user['name'] ??
                            localization.unknownUser), // Localized string
                        subtitle: Text(user['email']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUser: currentUser,
                                otherUserEmail: user['email'],
                                otherUserName: user['name'] ??
                                    localization
                                        .unknownUser, // Localized string
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
