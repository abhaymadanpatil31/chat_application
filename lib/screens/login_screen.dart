import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> _handleSignIn() async {
    log("Starting Google Sign-In process...");

    try {
      // Start sign-in process with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        log("Google Sign-In was canceled by the user.");
        return null; // The user canceled the sign-in process
      }
      log("Google Sign-In successful. User: ${googleUser.email}");

      // Get authentication object from the signed-in user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      log("Received Google Auth data: accessToken: ${googleAuth.accessToken}, idToken: ${googleAuth.idToken}");

      // Use Google auth credentials to sign in to Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      log("Firebase Auth Credential created successfully.");

      // Perform the sign-in with Firebase
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      log("Firebase sign-in successful. User: ${authResult.user?.email}");

      // Save the user to Firestore
      await _saveUserToFirestore(authResult.user!);

      return authResult.user;
    } catch (error) {
      log("Error during Google Sign-In: $error");
      return null;
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    await userRef.set({
      'name': user.displayName,
      'email': user.email,
      'uid': user.uid,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    log("User information updated in Firestore: ${user.email}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Welcome to ChatApp',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 50),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/Images/google_logo.png',
                            height: 24.0,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        log("Sign in button pressed.");
                        User? user = await _handleSignIn();
                        if (user == null) {
                          log("Google Sign-In failed or was canceled.");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Failed to sign in. Please try again.'),
                            ),
                          );
                        } else {
                          log("Sign-in successful. User: ${user.email}");
                          // No need to navigate here, AuthWrapper will handle it
                        }
                      },
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
}
