import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('How can we help you?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.question_answer_outlined),
            title: Text('Frequently Asked Questions'),
            subtitle:
                Text('Find answers to common questions about using the app.'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.support_agent_outlined),
            title: Text('Contact Support'),
            subtitle:
                Text('Email: support@financeapp.com\nPhone: +1 234 567 890'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Guide'),
            subtitle: Text('Learn how to use all features of the app.'),
          ),
        ],
      ),
    );
  }
}
