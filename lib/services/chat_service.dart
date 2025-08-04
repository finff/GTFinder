import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'notification_service.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NotificationService _notificationService = NotificationService();

  /// Create a new conversation between user and trainer based on booking
  static Future<String> createConversation({
    required String bookingId,
    required String userId,
    required String userName,
    required String trainerId,
    required String trainerName,
  }) async {
    try {
      // Check if conversation already exists for this booking
      final existingConversation = await _firestore
          .collection('conversations')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation
      final conversationData = Conversation(
        id: '', // Will be set by Firestore
        userId: userId,
        userName: userName,
        trainerId: trainerId,
        trainerName: trainerName,
        bookingId: bookingId,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('conversations')
          .add(conversationData.toFirestore());

      // Send initial system message
      await sendMessage(
        conversationId: docRef.id,
        content: 'Chat started for your booking. You can now communicate with each other!',
        type: MessageType.system,
      );

      print('✅ Created conversation: ${docRef.id} for booking: $bookingId');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Send a message in a conversation
  static Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final trainerDoc = await _firestore.collection('trainer').doc(user.uid).get();
      
      String senderName = 'Unknown';
      String senderRole = 'user';
      
      if (userDoc.exists) {
        senderName = userDoc.data()?['name'] ?? 'User';
        senderRole = 'user';
      } else if (trainerDoc.exists) {
        senderName = trainerDoc.data()?['name'] ?? 'Trainer';
        senderRole = 'trainer';
      }

      // Create message
      final message = ChatMessage(
        id: '', // Will be set by Firestore
        conversationId: conversationId,
        senderId: user.uid,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        timestamp: DateTime.now(),
        type: type,
        metadata: metadata,
      );

      // Use a batch to update both message and conversation
      final batch = _firestore.batch();

      // Add message to messages subcollection
      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();
      
      batch.set(messageRef, message.copyWith(id: messageRef.id).toFirestore());

      // Update conversation with last message and timestamp
      final conversationRef = _firestore
          .collection('conversations')
          .doc(conversationId);
      
      batch.update(conversationRef, {
        'lastMessage': message.copyWith(id: messageRef.id).toFirestore(),
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });

      await batch.commit();

      // Send push notification to the other participant
      await _sendMessageNotification(conversationId, message);

      print('✅ Message sent in conversation: $conversationId');
    } catch (e) {
      print('❌ Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get real-time stream of messages for a conversation
  static Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  /// Get conversations for current user
  static Stream<List<Conversation>> getUserConversations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    print('🔍 Fetching conversations for user: ${user.uid}');
    
    // Try a simpler query first - get all active conversations
    return _firestore
        .collection('conversations')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      print('📊 Found ${snapshot.docs.length} active conversations in database');
      
      final conversations = snapshot.docs
          .map((doc) {
            try {
              return Conversation.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing conversation ${doc.id}: $e');
              return null;
            }
          })
          .where((conv) => conv != null)
          .cast<Conversation>()
          .where((conv) => conv.userId == user.uid || conv.trainerId == user.uid)
          .toList();
      
      print('✅ Filtered to ${conversations.length} conversations for current user');
      
      // Sort by lastUpdatedAt in memory since we removed orderBy from query
      conversations.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
      
      return conversations;
    }).handleError((error) {
      print('❌ Error in getUserConversations stream: $error');
      return <Conversation>[];
    });
  }

  /// Get conversations for a specific user (both as user and trainer)
  static Stream<List<Conversation>> getConversationsForUser(String userId) {
    return _firestore
        .collection('conversations')
        .where('isActive', isEqualTo: true)
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromFirestore(doc))
          .where((conv) => (conv.userId == userId || conv.trainerId == userId) && conv.isActive)
          .toList();
    });
  }

  /// Mark messages as read in a conversation
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get unread messages from other participants
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      // Batch update all unread messages
      final batch = _firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ Marked ${unreadMessages.docs.length} messages as read');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  /// Get unread message count for a conversation
  static Future<int> getUnreadMessageCount(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return unreadMessages.docs.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Get total unread message count for current user across all conversations
  static Future<int> getTotalUnreadMessageCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      // Get all active conversations for this user
      final conversations = await _firestore
          .collection('conversations')
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (final conv in conversations.docs) {
        final conversationData = Conversation.fromFirestore(conv);
        // Only count conversations where current user is involved
        if (conversationData.userId == user.uid || conversationData.trainerId == user.uid) {
          final unreadCount = await getUnreadMessageCount(conv.id);
          totalUnread += unreadCount;
        }
      }

      return totalUnread;
    } catch (e) {
      print('❌ Error getting total unread count: $e');
      return 0;
    }
  }

  /// Archive a conversation
  static Future<void> archiveConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'status': 'archived',
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Conversation archived: $conversationId');
    } catch (e) {
      print('❌ Error archiving conversation: $e');
      throw Exception('Failed to archive conversation: $e');
    }
  }

  /// Delete a conversation (soft delete - set to inactive)
  static Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .update({
        'isActive': false,
        'lastUpdatedAt': Timestamp.fromDate(DateTime.now()),
      });
      print('✅ Conversation deleted: $conversationId');
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Get a specific conversation by ID
  static Future<Conversation?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (doc.exists) {
        return Conversation.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting conversation: $e');
      return null;
    }
  }

  /// Find conversation by booking ID
  static Future<Conversation?> getConversationByBookingId(String bookingId) async {
    try {
      final query = await _firestore
          .collection('conversations')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return Conversation.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('❌ Error getting conversation by booking ID: $e');
      return null;
    }
  }

  /// Send push notification for new message
  static Future<void> _sendMessageNotification(
    String conversationId,
    ChatMessage message,
  ) async {
    try {
      // Get conversation details
      final conversation = await getConversation(conversationId);
      if (conversation == null) return;

      // Don't send notification for system messages
      if (message.type == MessageType.system) return;

      // Determine recipient
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final recipientId = conversation.getOtherParticipantId(currentUserId);
      final senderName = message.senderName;

      // Send notification
      await _notificationService.sendDirectMessage(
        recipientId: recipientId,
        title: 'New message from $senderName',
        body: message.content,
        data: {
          'type': 'chat_message',
          'conversationId': conversationId,
          'senderId': message.senderId,
        },
      );

      print('✅ Chat notification sent to: $recipientId');
    } catch (e) {
      print('❌ Error sending chat notification: $e');
    }
  }

  /// Check if user can chat with trainer (must have an active booking)
  static Future<bool> canUserChatWithTrainer(String userId, String trainerId) async {
    try {
      final bookings = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .where('trainerId', isEqualTo: trainerId)
          .where('status', whereIn: ['confirmed', 'completed'])
          .get();

      return bookings.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking chat permission: $e');
      return false;
    }
  }
}