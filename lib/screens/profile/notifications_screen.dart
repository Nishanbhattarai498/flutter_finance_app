import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ListTile(
            leading: Icon(Icons.group_add_outlined),
            title: Text('Added to Group'),
            subtitle: Text('You have been added to a group by your friend.'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined),
            title: Text('Other Notifications'),
            subtitle:
                Text('You will see group and expense notifications here.'),
          ),
        ],
      ),
    );
  }
}
