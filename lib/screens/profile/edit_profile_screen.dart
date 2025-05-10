import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                // TODO: Implement image picker for profile photo
              },
              child: const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Full Name'),
              // TODO: Connect to controller and save logic
            ),
            const SizedBox(height: 16),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Email', enabled: false),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Other Details'),
              // TODO: Add more fields as needed
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: Save profile changes
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
