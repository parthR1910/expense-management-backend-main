import 'package:flutter/material.dart';

class UserContactScreen extends StatelessWidget {
  final List<Map<String, String>> contacts = [
    {'name': 'Tapan Mehta', 'email': 'tapan@example.com', 'phone': '+91 90000 00001'},
    {'name': 'Parth Rathod', 'email': 'parth@example.com', 'phone': '+91 90000 00002'},
    {'name': 'Sakshi Devrani', 'email': 'sakshi@example.com', 'phone': '+91 90000 00003'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Center(
            child: Text('User Contact',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900])),
          ),
          const SizedBox(height: 8),
          Text('Quick contact list for support & team members.',
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = contacts[i];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.shade50,
                      child: Text(c['name']![0], style: TextStyle(color: Colors.purple)),
                    ),
                    title: Text(c['name']!),
                    subtitle: Text('${c['email']!}\n${c['phone']!}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.email_outlined),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Email ${c['email']} (demo)')));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
