import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatapp/screens/chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:chatapp/screens/login_screen.dart';

class UserListScreen extends StatelessWidget {
  final User currentUser;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserListScreen({required this.currentUser});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (error) {
      log("Error during logout: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to log out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat With Users',
          style: GoogleFonts.mukta(
            fontSize: 25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _handleLogout(context),
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
                        currentUser.displayName ?? 'User',
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
                        title: Text(user['name'] ?? 'Unknown'),
                        subtitle: Text(user['email']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                currentUser: currentUser,
                                otherUserEmail: user['email'],
                                otherUserName: user['name'] ?? 'Unknown',
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
