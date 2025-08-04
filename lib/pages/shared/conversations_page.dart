import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/conversation.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import 'chat_page.dart';
import '../../widgets/profile_image_widget.dart';
import 'package:intl/intl.dart';

class ConversationsPage extends StatefulWidget {
  final bool isTrainer;
  
  const ConversationsPage({
    super.key,
    this.isTrainer = false,
  });

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A2468),
        body: Center(
          child: Text(
            'Please log in to view your conversations',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A2468),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
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
          child: StreamBuilder<List<Conversation>>(
            stream: ChatService.getUserConversations(),
            builder: (context, snapshot) {
              print('📱 ConversationsPage - Connection state: ${snapshot.connectionState}');
              print('📱 ConversationsPage - Has error: ${snapshot.hasError}');
              print('📱 ConversationsPage - Error: ${snapshot.error}');
              print('📱 ConversationsPage - Has data: ${snapshot.hasData}');
              print('📱 ConversationsPage - Data length: ${snapshot.data?.length ?? 0}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                );
              }

              if (snapshot.hasError) {
                print('❌ ConversationsPage Error: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading conversations',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final conversations = snapshot.data ?? [];

              if (conversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isTrainer
                              ? 'Conversations will appear here when clients book your services'
                              : 'Conversations will appear here when you book a trainer and complete payment',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Debug button to test conversation creation
                        if (!widget.isTrainer)
                          ElevatedButton(
                            onPressed: _createTestConversation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.7),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('🧪 Create Test Conversation'),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _buildConversationTile(conversation);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    final isCurrentUserTrainer = conversation.isCurrentUserTrainer(_currentUserId!);
    final otherParticipantName = conversation.getOtherParticipantName(_currentUserId!);
    final otherParticipantId = conversation.getOtherParticipantId(_currentUserId!);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openChatPage(conversation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Profile Image
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection(isCurrentUserTrainer ? 'users' : 'trainer')
                    .doc(otherParticipantId)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    return ProfileImageDisplay(
                      imageUrl: userData?['profileImage'],
                      size: 56,
                    );
                  }
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    child: Icon(
                      isCurrentUserTrainer ? Icons.person : Icons.fitness_center,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              
              // Conversation Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherParticipantName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessage != null)
                          Text(
                            _formatTimestamp(conversation.lastMessage!.timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Role indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCurrentUserTrainer 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCurrentUserTrainer ? 'Client' : 'Trainer',
                        style: TextStyle(
                          color: isCurrentUserTrainer ? Colors.green : Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Last message
                    if (conversation.lastMessage != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getLastMessageText(conversation.lastMessage!),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat.Hm().format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      return DateFormat.E().format(timestamp);
    } else {
      // Older - show date
      return DateFormat.MMMd().format(timestamp);
    }
  }

  String _getLastMessageText(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.file:
        return '📎 File';
      case MessageType.system:
        return message.content;
      default:
        return message.content;
    }
  }

  void _openChatPage(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: conversation,
          isTrainer: widget.isTrainer,
        ),
      ),
    );
  }

  Future<void> _createTestConversation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating test conversation...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Create a test conversation with dummy trainer data
      final conversationId = await ChatService.createConversation(
        bookingId: 'test_booking_${DateTime.now().millisecondsSinceEpoch}',
        userId: user.uid,
        userName: 'Test User',
        trainerId: 'test_trainer_id',
        trainerName: 'Test Trainer',
      );

      print('✅ Test conversation created: $conversationId');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test conversation created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error creating test conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}