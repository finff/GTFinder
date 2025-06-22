import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:async/async.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      return adminDoc.exists && (adminDoc.data()?['isActive'] ?? false);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin details
  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) return null;

      return AdminModel.fromMap(adminDoc.data()!, adminDoc.id);
    } catch (e) {
      print('Error getting admin details: $e');
      return null;
    }
  }

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get all trainers
  Stream<List<UserModel>> getAllTrainers() {
    final stream1 = _firestore.collection('trainers').snapshots();
    final stream2 = _firestore.collection('trainer').snapshots();

    return StreamGroup.merge([stream1, stream2]).map((snapshot) {
      final trainers = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      print(
          '[AdminService.getAllTrainers] Fetched ${trainers.length} trainers from collection ${snapshot.metadata.isFromCache ? "cache" : "server"}.');
      return trainers;
    });
  }

  // Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'isActive': isActive});
  }

  // Update trainer verification status
  Future<void> updateTrainerVerification(String trainerId, bool isVerified) async {
    await _firestore
        .collection('trainers')
        .doc(trainerId)
        .update({'isVerified': isVerified});
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      // Try fetching both 'trainers' and 'trainer' collections to debug
      final trainersSnapshot = await _firestore.collection('trainers').get();
      final trainerSingularSnapshot = await _firestore.collection('trainer').get();
      
      final totalTrainers = trainersSnapshot.size + trainerSingularSnapshot.size;

      final activeBookingsSnapshot = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'active')
          .get();

      print(
          'Fetched counts - Users: ${usersSnapshot.size}, Trainers: $totalTrainers (trainers: ${trainersSnapshot.size}, trainer: ${trainerSingularSnapshot.size}), Bookings: ${activeBookingsSnapshot.size}'); // Debug log

      final analytics = {
        'totalUsers': usersSnapshot.size,
        'totalTrainers': totalTrainers,
        'activeBookings': activeBookingsSnapshot.size,
        'revenue': 0, // Add revenue calculation later
      };

      print('Returning analytics: $analytics'); // Debug log
      return analytics;
    } catch (e) {
      print('Error getting analytics: $e');
      return {
        'totalUsers': 0,
        'totalTrainers': 0,
        'activeBookings': 0,
        'revenue': 0,
      };
    }
  }

  // Create a new admin
  Future<void> createAdmin({
    required String email,
    required String password,
    required String name,
    required List<String> permissions,
  }) async {
    try {
      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create admin document
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'permissions': permissions,
        'isActive': true,
      });
    } catch (e) {
      print('Error creating admin: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  // Delete trainer
  Future<void> deleteTrainer(String trainerId) async {
    // Attempt to delete from both collections to handle naming inconsistencies.
    try {
      await _firestore.collection('trainers').doc(trainerId).delete();
    } catch (e) {
      print('Could not delete from "trainers" collection: $e');
    }
    try {
      await _firestore.collection('trainer').doc(trainerId).delete();
    } catch (e) {
      print('Could not delete from "trainer" collection: $e');
    }
  }

  // Get system settings
  Future<Map<String, dynamic>> getSystemSettings() async {
    final doc = await _firestore.collection('settings').doc('system').get();
    return doc.data() ?? {};
  }

  // Update system settings
  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    await _firestore.collection('settings').doc('system').update(settings);
  }

  // Get pending escrow payments
  Stream<List<Map<String, dynamic>>> getPendingEscrowPayments() {
    return _firestore
        .collection('admin_escrow_payments')
        .where('adminStatus', isEqualTo: 'pending_release')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Get all escrow payments
  Stream<List<Map<String, dynamic>>> getAllEscrowPayments() {
    return _firestore
        .collection('admin_escrow_payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  // Release payment to trainer
  Future<void> releasePaymentToTrainer(String paymentId) async {
    try {
      final batch = _firestore.batch();

      // Get the escrow payment data
      final escrowDoc = await _firestore
          .collection('admin_escrow_payments')
          .doc(paymentId)
          .get();

      if (!escrowDoc.exists) {
        throw 'Escrow payment not found';
      }

      final escrowData = escrowDoc.data()!;
      final trainerId = escrowData['trainerId'];
      final bookingId = escrowData['bookingId'];

      // Update admin escrow status
      batch.update(
        _firestore.collection('admin_escrow_payments').doc(paymentId),
        {
          'adminStatus': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
          'releasedBy': _auth.currentUser?.uid,
        },
      );

      // Update trainer's payment status
      batch.update(
        _firestore
            .collection('trainer')
            .doc(trainerId)
            .collection('payments')
            .doc(paymentId),
        {
          'status': 'completed',
          'escrowStatus': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update user's payment status
      batch.update(
        _firestore
            .collection('users')
            .doc(escrowData['userId'])
            .collection('payments')
            .doc(paymentId),
        {
          'status': 'completed',
          'escrowStatus': 'released',
          'releasedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update booking status
      final bookingUpdates = {
        'escrowStatus': 'released',
        'sessionStatus': 'completed',
        'paymentReleasedAt': FieldValue.serverTimestamp(),
      };

      // Update booking in all collections
      batch.update(
        _firestore.collection('bookings').doc(bookingId),
        bookingUpdates,
      );

      batch.update(
        _firestore
            .collection('users')
            .doc(escrowData['userId'])
            .collection('bookings')
            .doc(bookingId),
        bookingUpdates,
      );

      batch.update(
        _firestore
            .collection('trainer')
            .doc(trainerId)
            .collection('bookings')
            .doc(bookingId),
        bookingUpdates,
      );

      await batch.commit();

      // Create notification for trainer
      final notificationService = NotificationService();
      await notificationService.createPaymentReleasedNotification(
        trainerId: trainerId,
        userName: escrowData['userName'],
        amount: escrowData['amount'],
        bookingId: bookingId,
      );

    } catch (e) {
      print('Error releasing payment: $e');
      rethrow;
    }
  }

  // Update admin name
  Future<void> updateAdminName(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No authenticated user found';

      await _firestore.collection('admins').doc(user.uid).update({
        'name': newName,
      });
    } catch (e) {
      print('Error updating admin name: $e');
      rethrow;
    }
  }

  // Create a test trainer
  Future<void> createTestTrainer() async {
    try {
      // Create auth user for trainer
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'trainer@example.com',
        password: 'trainerpass123',
      );

      // Create trainer document
      await _firestore.collection('trainers').doc(userCredential.user!.uid).set({
        'email': 'trainer@example.com',
        'name': 'Test Trainer',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isVerified': false,
        'specialization': 'General Fitness',
        'experience': '5 years',
        'rating': 5.0,
      });

      print('Test trainer created successfully');
    } catch (e) {
      print('Error creating test trainer: $e');
      rethrow;
    }
  }

  // Send an announcement to a target audience
  Future<void> sendAnnouncement({
    required String title,
    required String message,
    required String audience, // 'everyone', 'users_only', 'trainers_only'
  }) async {
    final notificationService = NotificationService();
    // Use a Set to automatically handle duplicate IDs.
    Set<String> recipientIds = {};

    // Get user IDs based on the selected audience
    if (audience == 'everyone' || audience == 'users_only') {
      final usersSnapshot = await _firestore.collection('users').get();
      for (final doc in usersSnapshot.docs) {
        recipientIds.add(doc.id);
      }
    }

    if (audience == 'everyone' || audience == 'trainers_only') {
      final trainersSnapshot = await _firestore.collection('trainers').get();
      final trainerSingularSnapshot = await _firestore.collection('trainer').get();
      for (final doc in trainersSnapshot.docs) {
        recipientIds.add(doc.id);
      }
      for (final doc in trainerSingularSnapshot.docs) {
        recipientIds.add(doc.id);
      }
    }

    if (recipientIds.isEmpty) {
      print('No recipients found for the announcement.');
      return;
    }

    // Create a notification for each recipient
    for (String userId in recipientIds) {
      await notificationService.createNotification(
        userId: userId,
        title: title,
        body: message,
        type: NotificationType.announcement,
      );
    }

    print('Announcement sent to ${recipientIds.length} unique recipients.');
  }
} 