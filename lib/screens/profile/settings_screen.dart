import 'package:flutter/material.dart';
import 'package:flutter_finance_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Settings Card
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // Light Mode Option
                  _buildThemeOption(
                    context,
                    Icons.light_mode,
                    'Light Mode',
                    'Light theme for bright environments',
                    ThemeMode.light,
                    themeProvider,
                  ),
                  const Divider(),
                  // Dark Mode Option
                  _buildThemeOption(
                    context,
                    Icons.dark_mode,
                    'Dark Mode',
                    'Dark theme for low light environments',
                    ThemeMode.dark,
                    themeProvider,
                  ),
                  const Divider(),
                  // System Default Option
                  _buildThemeOption(
                    context,
                    Icons.brightness_auto,
                    'System Default',
                    'Follow system theme settings',
                    ThemeMode.system,
                    themeProvider,
                  ),
                ],
              ),
            ),
          ),

          // Other Settings Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 8),
                      Text(
                        'Other Settings',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('More settings coming soon.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    ThemeMode mode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => themeProvider.setThemeMode(mode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryColor : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
