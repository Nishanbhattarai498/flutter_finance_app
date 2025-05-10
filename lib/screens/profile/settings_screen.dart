import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            subtitle: const Text('Choose Light or Dark mode'),
            trailing: DropdownButton<ThemeMode>(
              value: ThemeMode.system,
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
              ],
              onChanged: (mode) {
                // TODO: Implement theme change
              },
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.settings),
            title: Text('Other Settings'),
            subtitle: Text('More settings coming soon.'),
          ),
        ],
      ),
    );
  }
}
