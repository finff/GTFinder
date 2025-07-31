import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_service.dart';

/// Service to handle automatic payment release after 24 hours
class AutomaticPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  
  Timer? _checkTimer;
  static const Duration _checkInterval = Duration(minutes: 5); // Check every 5 minutes for faster response
  static const Duration _sessionCompletionDelay = Duration(minutes: 5); // 5 minutes after session for buffer

  /// Start the automatic payment release monitoring
  void startMonitoring() {
    print('🔄 Starting automatic payment release monitoring...');
    _checkTimer = Timer.periodic(_checkInterval, (_) => _checkForCompletedSessions());
  }

  /// Stop the automatic payment release monitoring
  void stopMonitoring() {
    print('⏹️ Stopping automatic payment release monitoring...');
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Check for sessions that have been completed for 24+ hours and release payments
  Future<void> _checkForCompletedSessions() async {
    try {
      print('🔍 Checking for completed sessions eligible for payment release...');
      
      final now = DateTime.now();
      final cutoffTime = now.subtract(_sessionCompletionDelay);
      
      // Query for confirmed bookings that are older than 24 hours
      final completedSessionsQuery = await _firestore
          .collection('bookings')
          .where('status', isEqualTo: 'confirmed')
          .where('paymentStatus', isEqualTo: 'paid_held')
          .where('escrowStatus', isEqualTo: 'pending')
          .get();

      final sessionsToProcess = <QueryDocumentSnapshot>[];
      
      for (final doc in completedSessionsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final bookingDate = data['bookingDate'] as Timestamp?;
        final timeSlot = data['timeSlot'] as String?;
        
        if (bookingDate != null && timeSlot != null) {
          final sessionDateTime = _calculateSessionDateTime(bookingDate.toDate(), timeSlot);
          
          // Check if session has ended (5-minute buffer for completion)
          if (sessionDateTime.isBefore(cutoffTime)) {
            sessionsToProcess.add(doc);
          }
        }
      }

      print('📊 Found ${sessionsToProcess.length} sessions eligible for immediate payment release');

      // Process each session
      for (final sessionDoc in sessionsToProcess) {
        await _releasePaymentForSession(sessionDoc);
      }

    } catch (e) {
      print('❌ Error checking for completed sessions: $e');
    }
  }

  /// Extract PaymentIntent ID from client secret if needed
  String? _extractPaymentIntentId(String? value) {
    if (value == null) return null;
    
    // If it's already a PaymentIntent ID (starts with pi_ and doesn't contain _secret_)
    if (value.startsWith('pi_') && !value.contains('_secret_')) {
      return value;
    }
    
    // If it's a client secret, extract the PaymentIntent ID
    if (value.contains('_secret_')) {
      final parts = value.split('_secret_');
      if (parts.isNotEmpty) {
        return parts[0]; // Return the part before _secret_
      }
    }
    
    return null;
  }

  /// Calculate the actual session date and time from booking date and time slot
  DateTime _calculateSessionDateTime(DateTime bookingDate, String timeSlot) {
    // Parse time slot (e.g., "09:00 AM", "02:00 PM")
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
    
    return DateTime(bookingDate.year, bookingDate.month, bookingDate.day, hour, minute);
  }

  /// Release payment for a specific session
  Future<void> _releasePaymentForSession(QueryDocumentSnapshot sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final bookingId = sessionDoc.id;
      final rawPaymentIntentId = sessionData['paymentIntentId'] as String?;
      final trainerId = sessionData['trainerId'] as String?;
      final userId = sessionData['userId'] as String?;
      // Get amount and convert from cents to dollars if needed
      final rawAmount = sessionData['amount'];
      double amount = 0.0;
      
      if (rawAmount != null) {
        if (rawAmount is int) {
          // Amount is stored in cents, convert to dollars
          amount = rawAmount / 100.0;
        } else if (rawAmount is double) {
          // Amount is already in dollars
          amount = rawAmount;
        } else {
          // Try to convert to double
          amount = double.tryParse(rawAmount.toString()) ?? 0.0;
        }
      }
      
      print('💰 Amount debug: rawAmount=$rawAmount, convertedAmount=$amount');
      final trainerName = sessionData['trainerName'] as String?;
      final userName = sessionData['userName'] as String?;

      if (rawPaymentIntentId == null || trainerId == null || userId == null) {
        print('❌ Missing required data for payment release: bookingId=$bookingId');
        return;
      }

      // Extract proper PaymentIntent ID (handle case where client secret was stored)
      final paymentIntentId = _extractPaymentIntentId(rawPaymentIntentId);
      
      if (paymentIntentId == null) {
        print('❌ ERROR: Could not extract valid PaymentIntent ID');
        print('   Raw value: $rawPaymentIntentId');
        print('   This should be a PaymentIntent ID (starts with pi_) or client secret');
        return;
      }

      // Debug: Validate PaymentIntent ID format
      if (!paymentIntentId.startsWith('pi_')) {
        print('❌ ERROR: Invalid PaymentIntent ID format');
        print('   PaymentIntent ID should start with "pi_"');
        print('   Extracted value: $paymentIntentId');
        return;
      }

      print('✅ PaymentIntent ID validation passed: $paymentIntentId');
      if (rawPaymentIntentId != paymentIntentId) {
        print('⚠️  WARNING: Client secret was stored instead of PaymentIntent ID');
        print('   Raw value: $rawPaymentIntentId');
        print('   Extracted PaymentIntent ID: $paymentIntentId');
      }

      print('💰 Releasing payment for booking: $bookingId');

      // Step 1: Check PaymentIntent status before capture
      final statusResponse = await http.get(
        Uri.parse('https://gtfinder.onrender.com/payment-intent-status?paymentIntentId=$paymentIntentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (statusResponse.statusCode != 200) {
        print('❌ Failed to check PaymentIntent status: ${statusResponse.body}');
        return;
      }

      final statusData = jsonDecode(statusResponse.body);
      final paymentStatus = statusData['status'] as String?;

      if (paymentStatus == null) {
        print('❌ Invalid PaymentIntent status response');
        return;
      }

      print('📊 PaymentIntent status: $paymentStatus');

      // Check if payment can be captured
      if (paymentStatus != 'requires_capture') {
        if (paymentStatus == 'canceled') {
          print('❌ PaymentIntent is canceled and cannot be captured');
          // Update booking status to reflect the canceled payment
          await _updateBookingForCanceledPayment(bookingId, paymentIntentId, trainerId, userId);
          return;
        } else if (paymentStatus == 'succeeded') {
          print('✅ PaymentIntent already succeeded, updating records only');
          await _updatePaymentRecords(bookingId, paymentIntentId, trainerId, userId, amount);
          await _sendPaymentReleaseNotifications(
            trainerId: trainerId,
            userId: userId,
            trainerName: trainerName ?? 'Trainer',
            userName: userName ?? 'User',
            amount: amount,
            bookingId: bookingId,
          );
          return;
        } else {
          print('❌ PaymentIntent status "$paymentStatus" is not eligible for capture');
          return;
        }
      }

      // Step 2: Capture payment on Stripe
      final captureResponse = await http.post(
        Uri.parse('https://gtfinder.onrender.com/capture-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );

      if (captureResponse.statusCode != 200) {
        print('❌ Failed to capture payment: ${captureResponse.body}');
        return;
      }

      print('✅ Payment captured successfully on Stripe');

      // Step 2: Update Firestore records
      await _updatePaymentRecords(bookingId, paymentIntentId, trainerId, userId, amount);

      // Step 3: Send notifications
      await _sendPaymentReleaseNotifications(
        trainerId: trainerId,
        userId: userId,
        trainerName: trainerName ?? 'Trainer',
        userName: userName ?? 'User',
        amount: amount,
        bookingId: bookingId,
      );

      print('✅ Payment released successfully for booking: $bookingId');

    } catch (e) {
      print('❌ Error releasing payment for session: $e');
    }
  }

  /// Update all payment records in Firestore
  Future<void> _updatePaymentRecords(
    String bookingId,
    String paymentIntentId,
    String trainerId,
    String userId,
    double amount,
  ) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    // Update admin escrow payment
    final escrowQuery = await _firestore
        .collection('admin_escrow_payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (escrowQuery.docs.isNotEmpty) {
      batch.update(escrowQuery.docs.first.reference, {
        'adminStatus': 'released',
        'releasedAt': now,
        'releaseType': 'automatic',
        'releaseReason': 'session completion (5-minute buffer)',
      });
    }

    // Update user payment record
    final userPaymentQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (userPaymentQuery.docs.isNotEmpty) {
      batch.update(userPaymentQuery.docs.first.reference, {
        'status': 'released',
        'escrowStatus': 'released',
        'releasedAt': now,
        'releaseType': 'automatic',
      });
    }

    // Update trainer payment record
    final trainerPaymentQuery = await _firestore
        .collection('trainer')
        .doc(trainerId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (trainerPaymentQuery.docs.isNotEmpty) {
      batch.update(trainerPaymentQuery.docs.first.reference, {
        'status': 'released',
        'escrowStatus': 'released',
        'releasedAt': now,
        'releaseType': 'automatic',
      });
    }

    // Update booking records
    final bookingUpdates = {
      'paymentStatus': 'released',
      'escrowStatus': 'released',
      'sessionStatus': 'completed',
      'paymentReleasedAt': now,
      'releaseType': 'automatic',
    };

    // Update root booking
    batch.update(_firestore.collection('bookings').doc(bookingId), bookingUpdates);

    // Update user booking
    batch.update(
      _firestore.collection('users').doc(userId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Update trainer booking
    batch.update(
      _firestore.collection('trainer').doc(trainerId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Commit all updates
    await batch.commit();
    print('✅ Firestore records updated successfully');
  }

  /// Send notifications about payment release
  Future<void> _sendPaymentReleaseNotifications({
    required String trainerId,
    required String userId,
    required String trainerName,
    required String userName,
    required double amount,
    required String bookingId,
  }) async {
    try {
      print('💰 Notification debug: amount=$amount, trainerId=$trainerId, userId=$userId');
      print('💰 Notification debug: trainerName=$trainerName, userName=$userName');
      
      // Notify trainer about payment release
      await _notificationService.createPaymentReleasedNotification(
        trainerId: trainerId,
        userName: userName,
        amount: amount,
        bookingId: bookingId,
      );

      // Notify user about payment release
      await _notificationService.createPaymentReleasedToTrainerNotification(
        userId: userId,
        trainerName: trainerName,
        amount: amount,
        bookingId: bookingId,
      );

      print('✅ Payment release notifications sent with amount: $amount');
    } catch (e) {
      print('❌ Error sending payment release notifications: $e');
    }
  }

  /// Manually trigger payment release for a specific booking (for admin use)
  Future<void> manuallyReleasePayment(String bookingId) async {
    try {
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      
      if (!bookingDoc.exists) {
        throw Exception('Booking not found');
      }

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final status = bookingData['status'] as String?;
      final paymentStatus = bookingData['paymentStatus'] as String?;
      final escrowStatus = bookingData['escrowStatus'] as String?;

      if (status != 'confirmed' || paymentStatus != 'paid_held' || escrowStatus != 'pending') {
        throw Exception('Booking is not eligible for manual payment release');
      }

      // Create a mock QueryDocumentSnapshot for the existing method
      final mockQueryDoc = _MockQueryDocumentSnapshot(bookingDoc);
      await _releasePaymentForSessionManual(mockQueryDoc);
      
    } catch (e) {
      print('❌ Error in manual payment release: $e');
      rethrow;
    }
  }

  /// Release payment for session (manual admin release)
  Future<void> _releasePaymentForSessionManual(QueryDocumentSnapshot<Map<String, dynamic>> sessionDoc) async {
    try {
      final sessionData = sessionDoc.data() as Map<String, dynamic>;
      final bookingId = sessionDoc.id;
      final rawPaymentIntentId = sessionData['paymentIntentId'] as String?;
      final trainerId = sessionData['trainerId'] as String?;
      final userId = sessionData['userId'] as String?;
      // Get amount and convert from cents to dollars if needed
      final rawAmount = sessionData['amount'];
      double amount = 0.0;
      
      if (rawAmount != null) {
        if (rawAmount is int) {
          // Amount is stored in cents, convert to dollars
          amount = rawAmount / 100.0;
        } else if (rawAmount is double) {
          // Amount is already in dollars
          amount = rawAmount;
        } else {
          // Try to convert to double
          amount = double.tryParse(rawAmount.toString()) ?? 0.0;
        }
      }
      
      print('💰 Amount debug: rawAmount=$rawAmount, convertedAmount=$amount');
      final trainerName = sessionData['trainerName'] as String?;
      final userName = sessionData['userName'] as String?;

      if (rawPaymentIntentId == null || trainerId == null || userId == null) {
        print('❌ Missing required data for payment release: bookingId=$bookingId');
        return;
      }

      // Extract PaymentIntent ID from client secret if needed
      final paymentIntentId = _extractPaymentIntentId(rawPaymentIntentId);
      if (paymentIntentId == null) {
        print('❌ Invalid PaymentIntent ID format: $rawPaymentIntentId');
        return;
      }

      // Debug: Check if paymentIntentId looks like a client secret
      if (rawPaymentIntentId.contains('_secret_')) {
        print('⚠️  WARNING: Client secret was stored instead of PaymentIntent ID');
        print('   Raw value: $rawPaymentIntentId');
        print('   Extracted PaymentIntent ID: $paymentIntentId');
      }

      print('💰 Manually releasing payment for booking: $bookingId');

      // Step 1: Check PaymentIntent status before capture
      final statusResponse = await http.get(
        Uri.parse('https://gtfinder.onrender.com/payment-intent-status?paymentIntentId=$paymentIntentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (statusResponse.statusCode != 200) {
        print('❌ Failed to check PaymentIntent status: ${statusResponse.body}');
        return;
      }

      final statusData = jsonDecode(statusResponse.body);
      final paymentStatus = statusData['status'] as String?;

      if (paymentStatus == null) {
        print('❌ Invalid PaymentIntent status response');
        return;
      }

      print('📊 PaymentIntent status: $paymentStatus');

      // Check if payment can be captured
      if (paymentStatus != 'requires_capture') {
        if (paymentStatus == 'canceled') {
          print('❌ PaymentIntent is canceled and cannot be captured');
          // Update booking status to reflect the canceled payment
          await _updateBookingForCanceledPayment(bookingId, paymentIntentId, trainerId, userId);
          return;
        } else if (paymentStatus == 'succeeded') {
          print('✅ PaymentIntent already succeeded, updating records only');
          await _updatePaymentRecordsManual(bookingId, paymentIntentId, trainerId, userId, amount);
          await _sendPaymentReleaseNotifications(
            trainerId: trainerId,
            userId: userId,
            trainerName: trainerName ?? 'Trainer',
            userName: userName ?? 'User',
            amount: amount,
            bookingId: bookingId,
          );
          return;
        } else {
          print('❌ PaymentIntent status "$paymentStatus" is not eligible for capture');
          return;
        }
      }

      // Step 2: Capture payment on Stripe
      final captureResponse = await http.post(
        Uri.parse('https://gtfinder.onrender.com/capture-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'paymentIntentId': paymentIntentId}),
      );

      if (captureResponse.statusCode != 200) {
        print('❌ Failed to capture payment: ${captureResponse.body}');
        return;
      }

      print('✅ Payment captured successfully on Stripe');

      // Step 2: Update Firestore records with manual release type
      await _updatePaymentRecordsManual(bookingId, paymentIntentId, trainerId, userId, amount);

      // Step 3: Send notifications
      await _sendPaymentReleaseNotifications(
        trainerId: trainerId,
        userId: userId,
        trainerName: trainerName ?? 'Trainer',
        userName: userName ?? 'User',
        amount: amount,
        bookingId: bookingId,
      );

      print('✅ Payment manually released successfully for booking: $bookingId');

    } catch (e) {
      print('❌ Error manually releasing payment for session: $e');
    }
  }

  /// Update all payment records in Firestore (manual release)
  Future<void> _updatePaymentRecordsManual(
    String bookingId,
    String paymentIntentId,
    String trainerId,
    String userId,
    double amount,
  ) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    // Update admin escrow payment
    final escrowQuery = await _firestore
        .collection('admin_escrow_payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (escrowQuery.docs.isNotEmpty) {
      batch.update(escrowQuery.docs.first.reference, {
        'adminStatus': 'released',
        'releasedAt': now,
        'releaseType': 'manual',
        'releaseReason': 'admin manual release',
      });
    }

    // Update user payment record
    final userPaymentQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (userPaymentQuery.docs.isNotEmpty) {
      batch.update(userPaymentQuery.docs.first.reference, {
        'status': 'released',
        'escrowStatus': 'released',
        'releasedAt': now,
        'releaseType': 'manual',
      });
    }

    // Update trainer payment record
    final trainerPaymentQuery = await _firestore
        .collection('trainer')
        .doc(trainerId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (trainerPaymentQuery.docs.isNotEmpty) {
      batch.update(trainerPaymentQuery.docs.first.reference, {
        'status': 'released',
        'escrowStatus': 'released',
        'releasedAt': now,
        'releaseType': 'manual',
      });
    }

    // Update booking records
    final bookingUpdates = {
      'paymentStatus': 'released',
      'escrowStatus': 'released',
      'sessionStatus': 'completed',
      'paymentReleasedAt': now,
      'releaseType': 'manual',
    };

    // Update root booking
    batch.update(_firestore.collection('bookings').doc(bookingId), bookingUpdates);

    // Update user booking
    batch.update(
      _firestore.collection('users').doc(userId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Update trainer booking
    batch.update(
      _firestore.collection('trainer').doc(trainerId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Commit all updates
    await batch.commit();
    print('✅ Firestore records updated successfully for manual release');
  }

  /// Update booking records for canceled payments
  Future<void> _updateBookingForCanceledPayment(
    String bookingId,
    String paymentIntentId,
    String trainerId,
    String userId,
  ) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    // Update booking records to reflect canceled payment
    final bookingUpdates = {
      'paymentStatus': 'canceled',
      'escrowStatus': 'canceled',
      'sessionStatus': 'canceled',
      'paymentCanceledAt': now,
      'cancelReason': 'payment_intent_canceled',
    };

    // Update root booking
    batch.update(_firestore.collection('bookings').doc(bookingId), bookingUpdates);

    // Update user booking
    batch.update(
      _firestore.collection('users').doc(userId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Update trainer booking
    batch.update(
      _firestore.collection('trainer').doc(trainerId).collection('bookings').doc(bookingId),
      bookingUpdates,
    );

    // Update admin escrow payment
    final escrowQuery = await _firestore
        .collection('admin_escrow_payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (escrowQuery.docs.isNotEmpty) {
      batch.update(escrowQuery.docs.first.reference, {
        'adminStatus': 'canceled',
        'canceledAt': now,
        'cancelReason': 'payment_intent_canceled',
      });
    }

    // Update user payment record
    final userPaymentQuery = await _firestore
        .collection('users')
        .doc(userId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (userPaymentQuery.docs.isNotEmpty) {
      batch.update(userPaymentQuery.docs.first.reference, {
        'status': 'canceled',
        'escrowStatus': 'canceled',
        'canceledAt': now,
        'cancelReason': 'payment_intent_canceled',
      });
    }

    // Update trainer payment record
    final trainerPaymentQuery = await _firestore
        .collection('trainer')
        .doc(trainerId)
        .collection('payments')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .get();

    if (trainerPaymentQuery.docs.isNotEmpty) {
      batch.update(trainerPaymentQuery.docs.first.reference, {
        'status': 'canceled',
        'escrowStatus': 'canceled',
        'canceledAt': now,
        'cancelReason': 'payment_intent_canceled',
      });
    }

    // Commit all updates
    await batch.commit();
    print('✅ Booking records updated for canceled payment');
  }

  /// Get statistics about automatic payment releases
  Future<Map<String, dynamic>> getPaymentReleaseStats() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));
      final last7Days = now.subtract(const Duration(days: 7));

      // Get automatic releases in last 24 hours
      final recentReleases = await _firestore
          .collection('admin_escrow_payments')
          .where('releaseType', isEqualTo: 'automatic')
          .where('releasedAt', isGreaterThan: Timestamp.fromDate(last24Hours))
          .get();

      // Get automatic releases in last 7 days
      final weeklyReleases = await _firestore
          .collection('admin_escrow_payments')
          .where('releaseType', isEqualTo: 'automatic')
          .where('releasedAt', isGreaterThan: Timestamp.fromDate(last7Days))
          .get();

      // Calculate total amounts
      double total24Hours = 0;
      double total7Days = 0;

      for (final doc in recentReleases.docs) {
        final data = doc.data();
        total24Hours += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      for (final doc in weeklyReleases.docs) {
        final data = doc.data();
        total7Days += (data['amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'releases24Hours': recentReleases.docs.length,
        'totalAmount24Hours': total24Hours,
        'releases7Days': weeklyReleases.docs.length,
        'totalAmount7Days': total7Days,
      };
    } catch (e) {
      print('❌ Error getting payment release stats: $e');
      return {
        'releases24Hours': 0,
        'totalAmount24Hours': 0.0,
        'releases7Days': 0,
        'totalAmount7Days': 0.0,
      };
    }
  }
}

// Helper class to convert DocumentSnapshot to QueryDocumentSnapshot
class _MockQueryDocumentSnapshot implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final DocumentSnapshot<Map<String, dynamic>> _doc;
  
  _MockQueryDocumentSnapshot(this._doc);
  
  @override
  Map<String, dynamic> data() => _doc.data()!;
  
  @override
  String get id => _doc.id;
  
  @override
  SnapshotMetadata get metadata => _doc.metadata;
  
  @override
  DocumentReference<Map<String, dynamic>> get reference => _doc.reference;
  
  @override
  bool get exists => _doc.exists;
  
  @override
  dynamic operator [](Object field) => _doc[field];
  
  @override
  dynamic get(Object field) => _doc.get(field);
} 