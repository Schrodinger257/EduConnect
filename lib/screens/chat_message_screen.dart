import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/providers/profile_provider.dart';
import 'package:educonnect/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessageScreen extends ConsumerStatefulWidget {
  ChatMessageScreen({
    super.key,
    required this.chatId,
    required this.receiver,
    required this.receiverId,
  });
  final String chatId;
  final Map<String, dynamic> receiver;
  final String receiverId;

  @override
  ConsumerState<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends ConsumerState<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();

  String message = '';
  List<DocumentSnapshot> messagesDataList = [];

  @override
  void dispose() {
    // TODO: implement dispose
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage({required String userId}) {
    if (message.isEmpty) return;

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': message,
          'senderId': userId,
          'timestamp': Timestamp.now(),
          'userImage': ref
              .read(authProvider.notifier)
              .userData['profileImage'], // Assuming userImage is available
          'username': ref
              .read(authProvider.notifier)
              .userData['name'], // Assuming username is available
        });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    String myId = ref.read(authProvider) as String;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.receiver['name'] ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.docs.isNotEmpty) {
                    return Center(
                      child: Text(
                        'No chat found with ${widget.receiver['name'] ?? 'Unknown User'}.',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    );
                  }

                  final chatData = snapshot.data!.docs;
                  messagesDataList = chatData;

                  if (chatData.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hi to ${widget.receiver['name'] ?? 'Unknown User'}! 👋',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    );
                  }

                  // Build your chat messages list here
                  return ListView.builder(
                    reverse: true,
                    itemCount: chatData.length,
                    itemBuilder: (context, index) {
                      final currentMessage = chatData[index].data();
                      final nextMessage = (index + 1 < chatData.length)
                          ? chatData[index + 1].data()
                          : null;
                      final isMe = currentMessage['senderId'] == myId;
                      final currentMessageUsedId = currentMessage['senderId'];
                      final nextMessageUsedId = nextMessage != null
                          ? nextMessage['senderId']
                          : null;
                      final userIsSame =
                          currentMessageUsedId == nextMessageUsedId;

                      if (userIsSame) {
                        return MessageBubble.next(
                          message: currentMessage['text'],
                          isMe: isMe,
                          timestamp: currentMessage['timestamp'],
                        );
                      } else {
                        return MessageBubble.first(
                          userImage: currentMessage['userImage'],
                          username: currentMessage['username'],
                          message: currentMessage['text'],
                          isMe: isMe,
                          timestamp: currentMessage['timestamp'],
                        );
                      }
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              padding: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      autocorrect: false,
                      enableSuggestions: true,
                      textCapitalization: TextCapitalization.sentences,
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message here',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      // Handle send message action
                      if (_messageController.text.isEmpty) return;
                      message = _messageController.text.trim();
                      if (message.isNotEmpty) {
                        // Send the message
                        _messageController.clear();
                      }
                      if (messagesDataList.isEmpty) {
                        // Send the message
                        print(
                          '####################################################################',
                        );
                        print(messagesDataList);

                        final myId = ref.read(authProvider) as String;
                        await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(widget.chatId)
                            .set({
                              'participants': [widget.receiverId, myId],
                              'lastMessageTime': FieldValue.serverTimestamp(),
                              'lastMessage': '',
                              'lastSender': myId,
                              'users': {
                                widget.receiverId: {
                                  'name': widget.receiver['name'],
                                  'profileImage':
                                      widget.receiver['profileImage'],
                                },
                                myId: {
                                  'name': ref
                                      .read(profileProvider.notifier)
                                      .userData['name'],
                                  'profileImage': ref
                                      .read(profileProvider.notifier)
                                      .userData['profileImage'],
                                },
                              },
                            });
                      }
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .add({
                            'text': message,
                            'senderId': myId,
                            'timestamp': Timestamp.now(),
                            'userImage': ref
                                .read(profileProvider.notifier)
                                .userData['profileImage'],
                            'username': ref
                                .read(profileProvider.notifier)
                                .userData['name'],
                          });
                      Map<String, dynamic> sender = await FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(myId)
                          .get()
                          .then((doc) => doc.data() as Map<String, dynamic>);
                      FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .update({
                            'lastMessageTime': FieldValue.serverTimestamp(),
                            'lastMessage': message,
                            'lastSender': myId,
                          });
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
