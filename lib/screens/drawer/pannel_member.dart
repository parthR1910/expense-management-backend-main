import 'package:flutter/material.dart';

class TeamLeadScreen extends StatelessWidget {
  const TeamLeadScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> members = const [
    {
      'name': 'Tapan Mehta',
      'role': 'Frontend Developer',
      'image': 'assets/images/tapan.jpg'
    },
    {
      'name': 'Parth Rathod',
      'role': 'Backend Developer',
      'image': 'assets/images/parth.jpeg'
    },
    {
      'name': 'Shakshi Devrani',
      'role': 'Team Lead',
      'image': 'assets/images/sakshi.jpg'
    },
    {
      'name': 'Vaibhav Makwana',
      'role': 'Frontend Developer',
      'image': 'assets/images/vaibhav.jpeg'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Center(
              child: Text(
                'Panel Members',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Core team who manage the panel and features.',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 18),

            // row of 4 members
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: members.map((m) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            m['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m['role']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // photo takes remaining height
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                m['image']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
