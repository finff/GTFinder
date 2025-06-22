import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './booking_schedule_page.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';

class TrainerFinderPage extends StatefulWidget {
  const TrainerFinderPage({super.key});

  @override
  State<TrainerFinderPage> createState() => _TrainerFinderPageState();
}

class _TrainerFinderPageState extends State<TrainerFinderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';

  double? _minFee;
  double? _maxFee;

  String? _selectedTimeSlot;
  DateTime? _selectedDate;

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
    '06:00 PM',
    '07:00 PM',
    '08:00 PM',
  ];

  void _showFeeFilterDialog() {
    final minController = TextEditingController(text: _minFee?.toString() ?? '');
    final maxController = TextEditingController(text: _maxFee?.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A2468),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF212E83),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by Session Fee',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Min Fee (RM)',
                  labelStyle: TextStyle(color: Colors.blue.shade100),
                  prefixIcon: const Icon(Icons.arrow_downward, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Max Fee (RM)',
                  labelStyle: TextStyle(color: Colors.blue.shade100),
                  prefixIcon: const Icon(Icons.arrow_upward, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.blue.shade100,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _minFee = null;
                        _maxFee = null;
                      });
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _minFee = double.tryParse(minController.text);
                        _maxFee = double.tryParse(maxController.text);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvailabilityFilterDialog() {
    DateTime? tempSelectedDate = _selectedDate;
    String? tempSelectedTimeSlot = _selectedTimeSlot;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A2468),
          title: const Text(
            'Filter by Availability',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date Selection
              const Text(
                'Select Date',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempSelectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.blue,
                            onPrimary: Colors.white,
                            surface: Color(0xFF1A2468),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() {
                      tempSelectedDate = date;
                      tempSelectedTimeSlot = null; // Reset time slot when date changes
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tempSelectedDate != null
                            ? DateFormat('MMM d, yyyy').format(tempSelectedDate!)
                            : 'Select Date',
                        style: TextStyle(
                          color: tempSelectedDate != null
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Time Slot Selection
              const Text(
                'Select Time',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: tempSelectedTimeSlot,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A2468),
                  underline: const SizedBox(),
                  hint: const Text(
                    'Select Time Slot',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: _getAvailableTimeSlotsForDate(tempSelectedDate).map((String slot) {
                    return DropdownMenuItem<String>(
                      value: slot,
                      child: Text(
                        slot,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() => tempSelectedTimeSlot = newValue);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  tempSelectedDate = null;
                  tempSelectedTimeSlot = null;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Update parent state with selected values
                this.setState(() {
                  _selectedDate = tempSelectedDate;
                  _selectedTimeSlot = tempSelectedTimeSlot;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bookTrainer(String trainerId, String trainerName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }

      final userName = userDoc.data()?['name'] ?? 'Unknown User';
      final bookingData = {
        'userId': user.uid,
        'userName': userName,
        'trainerId': trainerId,
        'trainerName': trainerName,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add booking to bookings collection
      await _firestore.collection('bookings').add(bookingData);

      // Create notification for the trainer
      final notificationService = NotificationService();
      await notificationService.createBookingRequestNotification(
        trainerId: trainerId,
        trainerName: trainerName,
        userId: user.uid,
        userName: userName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error booking trainer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Find Trainer',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time, color: Colors.white),
            onPressed: _showAvailabilityFilterDialog,
            tooltip: 'Filter by Availability',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            onPressed: _showFeeFilterDialog,
            tooltip: 'Filter by Session Fee',
          ),
        ],
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
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
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search trainers...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('trainer').snapshots(),
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

                    final trainers = snapshot.data?.docs ?? [];
                    if (_selectedDate != null && _selectedTimeSlot != null) {
                      // Pre-filter trainers using FutureBuilder with all filters
                      return FutureBuilder<List<QueryDocumentSnapshot>>(
                        future: () async {
                          List<QueryDocumentSnapshot> availableTrainers = [];
                          final user = _auth.currentUser;
                          String? userId = user?.uid;
                          for (final doc in trainers) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name = (data['name'] ?? '').toString().toLowerCase();
                            final specialization = (data['specialization'] ?? '').toString().toLowerCase();
                            final sessionFee = (data['sessionFee'] is num)
                                ? (data['sessionFee'] as num).toDouble()
                                : 50.0;
                            final matchesQuery = name.contains(_searchQuery) || specialization.contains(_searchQuery);
                            final matchesMin = _minFee == null || sessionFee >= _minFee!;
                            final matchesMax = _maxFee == null || sessionFee <= _maxFee!;
                            if (!(matchesQuery && matchesMin && matchesMax)) continue;

                            final trainerId = doc.id;
                            // Check the root bookings collection for user bookings at this slot
                            final userBookingSnapshot = await _firestore
                                .collection('bookings')
                                .where('userId', isEqualTo: userId)
                                .where('trainerId', isEqualTo: trainerId)
                                .where('timeSlot', isEqualTo: _selectedTimeSlot)
                                .where('status', whereIn: ['pending', 'confirmed'])
                                .get();
                            final userHasBooking = userBookingSnapshot.docs.any((doc) {
                              final bookingDate = (doc['bookingDate'] as Timestamp).toDate();
                              return bookingDate.year == _selectedDate!.year &&
                                     bookingDate.month == _selectedDate!.month &&
                                     bookingDate.day == _selectedDate!.day;
                            });
                            if (!userHasBooking) {
                              availableTrainers.add(doc);
                            }
                          }
                          return availableTrainers;
                        }(),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          }
                          final filteredTrainers = asyncSnapshot.data ?? [];
                          if (filteredTrainers.isEmpty) {
                            return Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'No trainers available'
                                    : 'No trainers found matching "$_searchQuery"',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(24),
                            itemCount: filteredTrainers.length,
                            itemBuilder: (context, index) {
                              final trainerDoc = filteredTrainers[index];
                              final trainerData = trainerDoc.data() as Map<String, dynamic>;
                              final trainerId = trainerDoc.id;
                              final trainerName = trainerData['name'] ?? 'Unknown';
                              final specialization = trainerData['specialization'] ?? 'Not specified';
                              final experience = trainerData['experience']?.toString() ?? '0';
                              final sessionFee = trainerData['sessionFee']?.toDouble() ?? 50.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildTrainerCard(trainerId, trainerName, specialization, experience, sessionFee, context),
                                  if (_selectedDate != null && _selectedTimeSlot != null)
                                    StreamBuilder<QuerySnapshot>(
                                      stream: _firestore
                                          .collection('trainer')
                                          .doc(trainerId)
                                          .collection('bookings')
                                          .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(
                                            DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).toUtc(),
                                          ))
                                          .where('bookingDate', isLessThan: Timestamp.fromDate(
                                            DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).toUtc().add(const Duration(days: 1)),
                                          ))
                                          .where('timeSlot', isEqualTo: _selectedTimeSlot)
                                          .snapshots(),
                                      builder: (context, bookingSnapshot) {
                                        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                                          return const SizedBox.shrink();
                                        }
                                        final docs = bookingSnapshot.data?.docs ?? [];
                                        if (docs.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [],
                                        );
                                      },
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    }

                    // Fallback to original ListView if no filter
                    return FutureBuilder<List<QueryDocumentSnapshot?>>(
                      future: Future.wait(
                        trainers.map((doc) async {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? '').toString().toLowerCase();
                          final specialization = (data['specialization'] ?? '').toString().toLowerCase();
                          final sessionFee = (data['sessionFee'] is num)
                              ? (data['sessionFee'] as num).toDouble()
                              : 50.0;
                          final matchesQuery = name.contains(_searchQuery) || specialization.contains(_searchQuery);
                          final matchesMin = _minFee == null || sessionFee >= _minFee!;
                          final matchesMax = _maxFee == null || sessionFee <= _maxFee!;

                          return matchesQuery && matchesMin && matchesMax ? doc : null;
                        }),
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        }

                        final filteredTrainers = snapshot.data?.where((doc) => doc != null).cast<QueryDocumentSnapshot>().toList() ?? [];

                        if (filteredTrainers.isEmpty) {
                          return Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No trainers available'
                                  : 'No trainers found matching "$_searchQuery"',
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: filteredTrainers.length,
                          itemBuilder: (context, index) {
                            final trainerDoc = filteredTrainers[index];
                            final trainerData = trainerDoc.data() as Map<String, dynamic>;
                            final trainerId = trainerDoc.id;
                            final trainerName = trainerData['name'] ?? 'Unknown';
                            final specialization = trainerData['specialization'] ?? 'Not specified';
                            final experience = trainerData['experience']?.toString() ?? '0';
                            final sessionFee = trainerData['sessionFee']?.toDouble() ?? 50.0;

                            // Add a StreamBuilder to show debug info for bookings
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTrainerCard(trainerId, trainerName, specialization, experience, sessionFee, context),
                                if (_selectedDate != null && _selectedTimeSlot != null)
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection('trainer')
                                        .doc(trainerId)
                                        .collection('bookings')
                                        .where('bookingDate', isGreaterThanOrEqualTo: Timestamp.fromDate(
                                          DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).toUtc(),
                                        ))
                                        .where('bookingDate', isLessThan: Timestamp.fromDate(
                                          DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day).toUtc().add(const Duration(days: 1)),
                                        ))
                                        .where('timeSlot', isEqualTo: _selectedTimeSlot)
                                        .snapshots(),
                                    builder: (context, bookingSnapshot) {
                                      if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                                        return const SizedBox.shrink();
                                      }
                                      final docs = bookingSnapshot.data?.docs ?? [];
                                      if (docs.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [],
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainerCard(String trainerId, String trainerName, String specialization, String experience, double sessionFee, BuildContext context) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
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
        title: Text(
          trainerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Specialization: $specialization',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Experience: $experience years',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Session Fee: RM${sessionFee.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () async {
            final trainerDoc = await _firestore
                .collection('trainer')
                .doc(trainerId)
                .get();
            final sessionFee = (trainerDoc.data()?['sessionFee'] ?? 50.0).toDouble();
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingSchedulePage(
                  trainerId: trainerId,
                  trainerName: trainerName,
                  specialization: specialization,
                  experience: int.parse(experience),
                  sessionFee: sessionFee,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getAvailableTimeSlotsForDate(DateTime? date) {
    if (date == null) {
      return _timeSlots;
    }

    final now = DateTime.now();
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    // If selected date is today, filter out past time slots
    final isToday = selectedDate.year == now.year && 
                   selectedDate.month == now.month && 
                   selectedDate.day == now.day;
    
    return _timeSlots.where((slot) {
      // If it's today, check if the time slot has passed
      if (isToday) {
        final slotTime = _parseTimeSlot(slot);
        final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
        
        // Add 30 minutes buffer to current time to prevent booking too close to current time
        final bufferTime = currentTime.add(const Duration(minutes: 30));
        
        return slotTime.isAfter(bufferTime);
      }
      
      // If it's a future date, all slots are available
      return true;
    }).toList();
  }
  
  DateTime _parseTimeSlot(String timeSlot) {
    // Parse time slots like "09:00 AM", "02:00 PM"
    final parts = timeSlot.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final period = parts[1];
    
    // Convert to 24-hour format
    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    
    return DateTime(_selectedDate?.year ?? DateTime.now().year, 
                   _selectedDate?.month ?? DateTime.now().month, 
                   _selectedDate?.day ?? DateTime.now().day, 
                   hour, minute);
  }
} 