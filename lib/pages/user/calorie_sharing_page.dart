import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalorieSharingPage extends StatelessWidget {
  const CalorieSharingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Calorie Sharing',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF212E83),
              const Color(0xFF1A2468),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(
                  child: Text(
                    'Please log in to view your bookings',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userSnapshot.data!.uid)
                    .collection('bookings')
                    .where('status', whereIn: ['pending', 'confirmed'])
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  final bookings = snapshot.data?.docs ?? [];

                  if (bookings.isEmpty) {
                    return const Center(
                      child: Text(
                        'No active bookings found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // Group bookings by trainer
                  final Map<String, List<QueryDocumentSnapshot>> trainerBookings = {};
                  for (var booking in bookings) {
                    final trainerId = booking['trainerId'] as String;
                    if (!trainerBookings.containsKey(trainerId)) {
                      trainerBookings[trainerId] = [];
                    }
                    trainerBookings[trainerId]!.add(booking);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: trainerBookings.length,
                    itemBuilder: (context, index) {
                      final trainerId = trainerBookings.keys.elementAt(index);
                      final trainerBookingsList = trainerBookings[trainerId]!;
                      final firstBooking = trainerBookingsList.first.data() as Map<String, dynamic>;
                      final trainerName = firstBooking['trainerName'] ?? 'Unknown Trainer';

                      return TrainerCalorieCard(
                        trainerId: trainerId,
                        trainerName: trainerName,
                        bookings: trainerBookingsList,
                        userId: userSnapshot.data!.uid,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class TrainerCalorieCard extends StatefulWidget {
  final String trainerId;
  final String trainerName;
  final List<QueryDocumentSnapshot> bookings;
  final String userId;

  const TrainerCalorieCard({
    super.key,
    required this.trainerId,
    required this.trainerName,
    required this.bookings,
    required this.userId,
  });

  @override
  State<TrainerCalorieCard> createState() => _TrainerCalorieCardState();
}

class _TrainerCalorieCardState extends State<TrainerCalorieCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.trainerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  ...widget.bookings.map((booking) {
                    final data = booking.data() as Map<String, dynamic>;
                    final bookingId = booking.id;
                    final schedule = data['formattedDateTime'] ?? '';
                    final sharingConfirmed = data['calorieSharingConfirmed'] == true;
                    final expiryTimestamp = data['calorieSharingExpiry'] as Timestamp?;
                    final isExpired = expiryTimestamp != null && expiryTimestamp.toDate().isBefore(DateTime.now());
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session: $schedule',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              sharingConfirmed ? Icons.check_circle : Icons.cancel,
                              color: sharingConfirmed ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              sharingConfirmed ? 'Calories shared with trainer' : 'Not shared with trainer',
                              style: TextStyle(
                                color: sharingConfirmed ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text(
                            'Enable Calorie Sharing',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: sharingConfirmed,
                          onChanged: isExpired
                              ? null // Disable the switch if expired
                              : (bool value) {
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(widget.userId)
                                      .collection('bookings')
                                      .doc(bookingId)
                                      .update({'calorieSharingConfirmed': value});
                                },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          tileColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        if (isExpired)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'The time to change this setting has expired.',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 