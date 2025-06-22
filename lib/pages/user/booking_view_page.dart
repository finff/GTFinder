import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';
import 'package:intl/intl.dart';

class BookingViewPage extends StatelessWidget {
  const BookingViewPage({super.key});

  Future<double> _getSessionFee(String trainerId) async {
    try {
      final trainerDoc = await FirebaseFirestore.instance
          .collection('trainer')
          .doc(trainerId)
          .get();
      if (trainerDoc.exists) {
        return (trainerDoc.data()?['sessionFee'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (e) {
      print('Error getting session fee: $e');
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                        'No bookings found',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  // Group bookings by trainer
                  final Map<String, List<QueryDocumentSnapshot>> groupedBookings = {};
                  for (var booking in bookings) {
                    final trainerName = booking['trainerName'] as String? ?? 'Unknown Trainer';
                    if (groupedBookings.containsKey(trainerName)) {
                      groupedBookings[trainerName]!.add(booking);
                    } else {
                      groupedBookings[trainerName] = [booking];
                    }
                  }

                  final trainerNames = groupedBookings.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: trainerNames.length,
                    itemBuilder: (context, index) {
                      final trainerName = trainerNames[index];
                      final trainerBookings = groupedBookings[trainerName]!;

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
                        child: ExpansionTile(
                          title: Text(
                            trainerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${trainerBookings.length} booking${trainerBookings.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          collapsedBackgroundColor: Colors.transparent,
                          children: trainerBookings.map((bookingDoc) {
                            final booking = bookingDoc.data() as Map<String, dynamic>;
                            final status = booking['status'] ?? 'pending';
                            final paymentStatus = booking['paymentStatus'];
                            final sharingConfirmed = booking['calorieSharingConfirmed'] == true;

                            Color statusColor;
                            if (status == 'confirmed' && (paymentStatus == 'paid' || paymentStatus == 'paid_held')) {
                              statusColor = Colors.green;
                            } else if (status == 'pending') {
                              statusColor = Colors.orange;
                            } else {
                              statusColor = Colors.red;
                            }

                            return Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.calendar_today,
                                            color: statusColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking['formattedDateTime'] ?? 'No schedule',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildInfoRow(
                                      'Payment Status',
                                      (paymentStatus ?? 'UNPAID').toUpperCase(),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          sharingConfirmed
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: sharingConfirmed
                                              ? Colors.green
                                              : Colors.red,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            sharingConfirmed
                                                ? 'Calorie data is shared'
                                                : 'Calorie data is not shared',
                                            style: TextStyle(
                                              color: sharingConfirmed
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Show "Pay Now" button if the booking is not yet paid.
                                    // This handles both new bookings ('unpaid') and older bookings (null).
                                    if (paymentStatus != 'paid' && paymentStatus != 'paid_held') ...[
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            // Fetch the session fee before navigating
                                            final sessionFee = await _getSessionFee(booking['trainerId']);
                                            if (sessionFee > 0 && context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => PaymentPage(
                                                    bookingId: booking['bookingId'],
                                                    trainerId: booking['trainerId'],
                                                    trainerName: booking['trainerName'],
                                                    bookingDateTime: booking['formattedDateTime'],
                                                    amount: sessionFee,
                                                    specialization: '', // These are not essential for retry
                                                    experience: 0,
                                                  ),
                                                ),
                                              );
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Could not retrieve session fee. Please try again.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Pay Now',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 