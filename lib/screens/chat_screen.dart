
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/screens/chat_search_screen.dart';
import 'package:educonnect/widgets/chat_screen_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

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
    final authState = ref.watch(authProvider);
    final userId = authState.userId;
    
    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access this screen'),
        ),
      );
    }
    
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
                      .map((doc) => doc.data())
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
                      return ChatScreenTile(
                        userId: userId,
                        chat: chat,
                        chatId: snapshot.data!.docs[index].id,
                        recieverId: recieverId,
                        key: ValueKey(snapshot.data!.docs[index].id),
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
