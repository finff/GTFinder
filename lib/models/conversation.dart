import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';

class Conversation {
  final String id;
  final String userId;
  final String userName;
  final String trainerId;
  final String trainerName;
  final String bookingId; // Link to the booking that created this conversation
  final ChatMessage? lastMessage;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final int unreadCount; // Unread messages count for current user
  final bool isActive; // Whether the conversation is active
  final ConversationStatus status;

  Conversation({
    required this.id,
    required this.userId,
    required this.userName,
    required this.trainerId,
    required this.trainerName,
    required this.bookingId,
    this.lastMessage,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.unreadCount = 0,
    this.isActive = true,
    this.status = ConversationStatus.active,
  });

  factory Conversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    ChatMessage? lastMessage;
    if (data['lastMessage'] != null) {
      final messageData = data['lastMessage'] as Map<String, dynamic>;
      lastMessage = ChatMessage(
        id: messageData['id'] ?? '',
        conversationId: doc.id,
        senderId: messageData['senderId'] ?? '',
        senderName: messageData['senderName'] ?? '',
        senderRole: messageData['senderRole'] ?? 'user',
        content: messageData['content'] ?? '',
        timestamp: (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isRead: messageData['isRead'] ?? false,
        type: MessageType.values.firstWhere(
          (e) => e.toString() == 'MessageType.${messageData['type'] ?? 'text'}',
          orElse: () => MessageType.text,
        ),
      );
    }

    return Conversation(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      trainerId: data['trainerId'] ?? '',
      trainerName: data['trainerName'] ?? '',
      bookingId: data['bookingId'] ?? '',
      lastMessage: lastMessage,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      status: ConversationStatus.values.firstWhere(
        (e) => e.toString() == 'ConversationStatus.${data['status'] ?? 'active'}',
        orElse: () => ConversationStatus.active,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic>? lastMessageData;
    if (lastMessage != null) {
      lastMessageData = {
        'id': lastMessage!.id,
        'senderId': lastMessage!.senderId,
        'senderName': lastMessage!.senderName,
        'senderRole': lastMessage!.senderRole,
        'content': lastMessage!.content,
        'timestamp': Timestamp.fromDate(lastMessage!.timestamp),
        'isRead': lastMessage!.isRead,
        'type': lastMessage!.type.toString().split('.').last,
      };
    }

    return {
      'userId': userId,
      'userName': userName,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'bookingId': bookingId,
      'lastMessage': lastMessageData,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'status': status.toString().split('.').last,
    };
  }

  Conversation copyWith({
    String? id,
    String? userId,
    String? userName,
    String? trainerId,
    String? trainerName,
    String? bookingId,
    ChatMessage? lastMessage,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    int? unreadCount,
    bool? isActive,
    ConversationStatus? status,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      bookingId: bookingId ?? this.bookingId,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }

  /// Get the other participant's name based on current user role
  String getOtherParticipantName(String currentUserId) {
    return currentUserId == userId ? trainerName : userName;
  }

  /// Get the other participant's ID based on current user role
  String getOtherParticipantId(String currentUserId) {
    return currentUserId == userId ? trainerId : userId;
  }

  /// Check if current user is the trainer in this conversation
  bool isCurrentUserTrainer(String currentUserId) {
    return currentUserId == trainerId;
  }
}

enum ConversationStatus {
  active,      // Normal active conversation
  archived,    // Archived by user
  blocked,     // Blocked conversation
  completed,   // Booking completed, conversation can continue but marked as completed
}