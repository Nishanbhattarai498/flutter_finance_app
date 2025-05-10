import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Your Privacy',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text(
                'Your profile details are private and cannot be seen by anyone else.'),
            SizedBox(height: 16),
            Text('We do not share your personal information with other users.'),
            SizedBox(height: 16),
            Text('You control what information is visible in your profile.'),
          ],
        ),
      ),
    );
  }
}
