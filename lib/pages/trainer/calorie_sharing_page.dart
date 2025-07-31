import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/profile_image_widget.dart';

class TrainerCalorieSharingPage extends StatelessWidget {
  const TrainerCalorieSharingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final trainerUid = FirebaseAuth.instance.currentUser?.uid;
    if (trainerUid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in as trainer')),
      );
    }
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('trainerId', isEqualTo: trainerUid)
                .where('calorieSharingConfirmed', isEqualTo: true) // Only show explicitly consented bookings
                .where('status', whereIn: ['pending', 'confirmed'])
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
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              
              // Filter out expired sharing agreements
              final now = DateTime.now();
              final activeBookings = snapshot.data?.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final expiryTimestamp = data['calorieSharingExpiry'] as Timestamp?;
                if (expiryTimestamp == null) return false;
                
                final expiryDate = expiryTimestamp.toDate();
                return expiryDate.isAfter(now);
              }).toList() ?? [];
              
              if (activeBookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.privacy_tip,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No active calorie sharing agreements.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Users must explicitly consent to share their calorie data with you, and sharing expires after 24 hours.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Group bookings by user
              final Map<String, List<QueryDocumentSnapshot>> userBookings = {};
              for (var booking in activeBookings) {
                final userId = booking['userId'] as String;
                if (!userBookings.containsKey(userId)) {
                  userBookings[userId] = [];
                }
                userBookings[userId]!.add(booking);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: userBookings.length,
                itemBuilder: (context, index) {
                  final userId = userBookings.keys.elementAt(index);
                  final userBookingsList = userBookings[userId]!;
                  final firstBooking = userBookingsList.first.data() as Map<String, dynamic>;
                  final userName = firstBooking['name'] ?? 'User';

                  return UserCalorieCard(
                    userId: userId,
                    userName: userName,
                    bookings: userBookingsList,
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

class UserCalorieCard extends StatefulWidget {
  final String userId;
  final String userName;
  final List<QueryDocumentSnapshot> bookings;

  const UserCalorieCard({
    super.key,
    required this.userId,
    required this.userName,
    required this.bookings,
  });

  @override
  State<UserCalorieCard> createState() => _UserCalorieCardState();
}

class _UserCalorieCardState extends State<UserCalorieCard> {
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
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                        return ProfileImageDisplay(
                          imageUrl: userData?['profileImage'],
                          size: 48,
                        );
                      }
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.userName,
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
                  CalorieDataAndGoalWidget(userId: widget.userId, bookings: widget.bookings),
                  const SizedBox(height: 16),
                  ...widget.bookings.map((booking) {
                    final data = booking.data() as Map<String, dynamic>;
                    final schedule = data['formattedDateTime'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Session: $schedule',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
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

class CalorieDataAndGoalWidget extends StatelessWidget {
  final String userId;
  final List<QueryDocumentSnapshot> bookings; // Add bookings parameter
  
  const CalorieDataAndGoalWidget({
    required this.userId, 
    required this.bookings, // Add bookings parameter
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Check if any booking has active sharing
    final now = DateTime.now();
    bool hasActiveSharing = false;
    
    for (var booking in bookings) {
      final data = booking.data() as Map<String, dynamic>;
      final isSharingConfirmed = data['calorieSharingConfirmed'] == true;
      final expiryTimestamp = data['calorieSharingExpiry'] as Timestamp?;
      
      if (isSharingConfirmed && expiryTimestamp != null) {
        final expiryDate = expiryTimestamp.toDate();
        if (expiryDate.isAfter(now)) {
          hasActiveSharing = true;
          break;
        }
      }
    }
    
    // If no active sharing, show message instead of calorie data
    if (!hasActiveSharing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.privacy_tip,
              color: Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Calorie sharing is currently disabled or expired',
                style: TextStyle(
                  color: Colors.orange.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show calorie data only when sharing is active
    final today = DateTime.now();
    final todayDoc = DateTime(today.year, today.month, today.day).toIso8601String();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('daily_calories')
          .doc(todayDoc)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading calories', style: TextStyle(color: Colors.red));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading calories...', style: TextStyle(color: Colors.white70));
        }
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final calories = data?['calories'] ?? 0;
        final goal = data?['goal'];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Consent Given',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Today's Calories: $calories kcal",
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            // User's Daily Calorie Goal
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasError) {
                  return const Text('Error loading goal', style: TextStyle(color: Colors.red));
                }
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading goal...', style: TextStyle(color: Colors.white70));
                }
                final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
                final dailyGoal = userData?['dailyCalorieGoal'];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Calorie Goal: ${dailyGoal ?? 'Not set'} kcal",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (goal != null && goal != dailyGoal) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Today's Target: $goal kcal",
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Progress indicator
                    if (dailyGoal != null && calories > 0) ...[
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (calories / dailyGoal).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: calories >= dailyGoal ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((calories / dailyGoal) * 100).clamp(0.0, 100.0).toStringAsFixed(1)}% of daily goal',
                        style: TextStyle(
                          color: calories >= dailyGoal ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
} 