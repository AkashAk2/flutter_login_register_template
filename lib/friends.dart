import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Friend {
  String id;
  String name;
  String phone;
  double amountOwed; // Positive if they owe you, negative if you owe them
  Friend({required this.id, required this.name, required this.phone, this.amountOwed = 0.0});
}

class Friends extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<Friends> {
  List<Friend> _friends = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _friendsRef = FirebaseDatabase.instance.ref('friends');

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.contacts.status;
    if (status.isDenied) {
      await Permission.contacts.request();
    }
  }

  void _loadFriends() {
    _friendsRef.child(_auth.currentUser!.uid).onValue.listen((event) {
      final data = Map<String, dynamic>.from(event.snapshot.value as Map? ?? {});
      final List<Friend> loadedFriends = data.entries.map((entry) => Friend(
        id: entry.key,
        name: entry.value['name'],
        phone: entry.value['phone'],
        amountOwed: entry.value['amountOwed'].toDouble(),
      )).toList();

      setState(() => _friends = loadedFriends);
    });
  }

  String _normalizePhoneNumber(String phone) {
  // Remove all spaces, hyphens, and parentheses
  String normalized = phone.replaceAll(RegExp(r'[\s-()]'), '');
  // Check if the number includes a country code, add it if missing
  // This example assumes +61 for Australia if not present
  if (!normalized.startsWith('+')) {
    // Assume it's an Australian number missing the country code
    normalized = '+61' + normalized;
  }
  return normalized;
}

Future<void> _pickContact() async {
  final PermissionStatus permissionStatus = await Permission.contacts.status;
  if (permissionStatus.isGranted) {
    try {
      final Contact? contact = await ContactsService.openDeviceContactPicker();
      if (contact != null) {
        String phoneNumber = contact.phones!.isNotEmpty ? contact.phones!.first.value! : 'No Phone';
        phoneNumber = _normalizePhoneNumber(phoneNumber);

        final Friend newFriend = Friend(
          id: '', // Firebase will generate this
          name: contact.displayName ?? 'No Name',
          phone: phoneNumber,
          amountOwed: 0.0,
        );

        // Save to Firebase
        _saveFriend(newFriend);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick contact: $e')));
    }
  } else {
    await Permission.contacts.request();
  }
}

Future<void> _saveFriend(Friend friend) async {
  friend.phone = _normalizePhoneNumber(friend.phone); // Normalize before saving

  final newFriendRef = _friendsRef.child(_auth.currentUser!.uid).push();
  await newFriendRef.set({
    'name': friend.name,
    'phone': friend.phone,
    'amountOwed': friend.amountOwed,
  });
  setState(() => friend.id = newFriendRef.key!);
  _friends.add(friend);
}


  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Friends'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _pickContact,
          ),
        ],
      ),
      body: _friends.isEmpty
          ? Center(child: Text('No friends added.'))
          : ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friend = _friends[index];
                return ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text(friend.name),
                  subtitle: Text('Owes: \$${friend.amountOwed.toStringAsFixed(2)}'),
                  onTap: () {
                    // Navigate to a detailed view or edit page
                  },
                );
              },
            ),
    );
  }
}
