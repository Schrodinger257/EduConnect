import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/screens/chat_message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ChatScreenTile extends ConsumerWidget {
  final String userId;
  final Map<String, dynamic> chat;
  final String chatId;
  final String recieverId;

  const ChatScreenTile({
    super.key,
    required this.userId,
    required this.chat,
    required this.chatId,
    required this.recieverId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(recieverId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          );
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text('User not found');
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: userData['profileImage'] != 'default_avatar'
                ? NetworkImage(userData['profileImage'])
                : AssetImage('assets/images/default_avatar.png')
                      as ImageProvider,
          ),
          title: Text(
            userData['name'],
            style: TextStyle(
              color: Theme.of(context).shadowColor.withAlpha(150),
            ),
          ),
          subtitle: Text(
            '${chat['lastSender'] == ref.read(authProvider) ? 'You:' : ''} ${chat['lastMessage']}',
            style: TextStyle(
              color: Theme.of(context).shadowColor.withAlpha(150),
            ),
          ),
          trailing: Text(
            (chat['lastMessageTime'] != '' || chat['lastMessageTime'] != null)
                ? '${DateFormat.yMd().add_jm().format(DateTime.fromMillisecondsSinceEpoch(chat['lastMessageTime'].millisecondsSinceEpoch).toLocal())}'
                : '',
          ),
          onTap: () {
            // Navigate to chat screen with the selected user
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatMessageScreen(
                  chatId: chatId,
                  receiver: userData,
                  receiverId: recieverId,
                  key: ValueKey(chatId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
