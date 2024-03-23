import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Log out the user
            await FirebaseAuth.instance.signOut();
            // Navigate back to the login screen
            Navigator.pushReplacementNamed(context, '/');
          },
          child: Text('Logout'),
        ),
      ),
    );
  }
}
