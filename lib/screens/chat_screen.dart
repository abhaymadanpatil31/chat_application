import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final User currentUser;
  final String otherUserEmail;
  final String otherUserName;

  const ChatScreen(
      {super.key,
      required this.currentUser,
      required this.otherUserEmail,
      required this.otherUserName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Function to send a message
  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      String chatRoomId =
          _getChatRoomId(widget.currentUser.email!, widget.otherUserEmail);

      _firestore
          .collection('chats')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'sender': widget.currentUser.email,
        'receiver': widget.otherUserEmail,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
      _scrollToBottom(); // Scroll to the bottom after sending a message
    }
  }

  // Helper function to create a unique chat room ID for User1 and User2
  String _getChatRoomId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
  }

  // Function to scroll to the bottom of the message list
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Function to determine whether to show "Today", "Yesterday", or the specific date
  String _getMessageDay(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date); // Example: Jan 1, 2024
    }
  }

  @override
  Widget build(BuildContext context) {
    String chatRoomId =
        _getChatRoomId(widget.currentUser.email!, widget.otherUserEmail);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(widget.otherUserName[0].toUpperCase()),
            ),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;
                List<Widget> messageWidgets = [];
                String lastMessageDay = '';

                for (var message in messages) {
                  final messageText = message['text'];
                  final Timestamp? messageTimestamp = message['timestamp'];

                  if (messageTimestamp != null) {
                    DateTime messageDateTime = messageTimestamp.toDate();
                    String messageDay = _getMessageDay(messageDateTime);

                    // Insert a date header if it's a different day than the previous message
                    if (messageDay != lastMessageDay) {
                      messageWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            messageDay,
                            style: GoogleFonts.mukta(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                      lastMessageDay = messageDay;
                    }

                    final messageSender = message['sender'];
                    final isMe = widget.currentUser.email == messageSender;
                    final formattedTime =
                        DateFormat('h:mm a').format(messageDateTime);

                    // Add the message widget
                    messageWidgets.add(
                      Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[100] : Colors.grey[300],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: isMe
                                  ? const Radius.circular(16)
                                  : Radius.zero,
                              bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                messageText,
                                style: GoogleFonts.mukta(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: GoogleFonts.mukta(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView(
                  controller: _scrollController,
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type a message',
                        hintStyle: GoogleFonts.mukta(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
