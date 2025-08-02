import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/screens/chat_message_screen.dart';
import 'package:educonnect/screens/chat_search%20screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  List<Map<String, dynamic>> chatsData = [];

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String userId = ref.watch(authProvider) as String;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Search for someone',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatSearchScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('participants', arrayContains: userId)
                    .orderBy('lastMessageTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No chats found.'));
                  }
                  chatsData = snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();
                  print(chatsData);
                  print(
                    '####################################################################',
                  );
                  return ListView.builder(
                    itemCount: chatsData.length,
                    itemBuilder: (context, index) {
                      final chat = chatsData[index];
                      final recieverId = chat['participants'].firstWhere(
                        (id) => id != userId,
                        orElse: () => '',
                      );
                      final recieverData = chat['users'][recieverId];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              recieverData['profileImage'] != 'default_avatar'
                              ? FileImage(File(recieverData['profileImage']))
                              : AssetImage('assets/images/default_avatar.png')
                                    as ImageProvider,
                        ),
                        title: Text(recieverData['name'] ?? 'Unknown User'),
                        subtitle: Text(
                          '${chat['lastSender'] == ref.read(authProvider) ? 'You:' : ''} ${chat['lastMessage']}',
                          style: TextStyle(
                            color: Theme.of(context).shadowColor.withAlpha(150),
                          ),
                        ),
                        onTap: () {
                          final chatId = snapshot.data!.docs[index].id;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatMessageScreen(
                                chatId: chatId,
                                receiver: recieverData,
                                receiverId: recieverId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
