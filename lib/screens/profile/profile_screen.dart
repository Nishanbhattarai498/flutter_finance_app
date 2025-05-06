import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/auth_provider.dart';
import 'package:flutter_finance_app/screens/auth/login_screen.dart';
import 'package:flutter_finance_app/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userProfile?['full_name'] ?? 'User',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    authProvider.userId ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Profile options
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to edit profile screen
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to settings screen
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to notifications settings
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy & Security
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Privacy & Security'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to help center
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to about screen
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign out button
            CustomButton(
              text: 'Sign Out',
              variant: ButtonVariant.outlined,
              onPressed: () async {
                await authProvider.signOut();
                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
