import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

// Define a model for friends with a name and the amount owed
class Friend {
  String name;
  double amountOwed; // Positive if they owe you, negative if you owe them
  Friend({required this.name, this.amountOwed = 0.0});
}

class Friends extends StatefulWidget {
  @override
  _FriendsListState createState() => _FriendsListState();
}

class _FriendsListState extends State<Friends> {
  List<Friend> _friends = []; // List of Friend objects

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.contacts.status;
    if (status.isDenied) {
      _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) {
      _showOpenAppSettingsDialog();
    }
  }

  void _showOpenAppSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission needed'),
        content: const Text('This app needs contact permission to function properly. Please open settings and grant permission.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open settings'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickContact() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      try {
        final Contact? contact = await ContactsService.openDeviceContactPicker();
        if (contact != null && contact.displayName != null) {
          setState(() {
            _friends.add(Friend(name: contact.displayName!)); // Add as a Friend object
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick contact: $e')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      _showOpenAppSettingsDialog();
    } else {
      await _requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickContact,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Placeholder for search functionality
            },
          ),
        ],
      ),
      body: _friends.isEmpty
          ? const Center(child: Text('No friends added.'))
          : ListView.separated(
              itemCount: _friends.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person), // Placeholder icon for friend images
                  ),
                  title: Text(friend.name),
                  subtitle: Text(
                    friend.amountOwed >= 0
                        ? 'Owes you: \$${friend.amountOwed.toStringAsFixed(2)}'
                        : 'You owe: \$${(-friend.amountOwed).toStringAsFixed(2)}',
                  ),
                  trailing: const Icon(Icons.more_vert),
                  onTap: () {
                    // Placeholder for future implementation of transactions view
                  },
                );
              },
            ),
    );
  }
}
