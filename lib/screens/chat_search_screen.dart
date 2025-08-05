
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/providers/auth_provider.dart';
import 'package:educonnect/screens/chat_message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatSearchScreen extends ConsumerStatefulWidget {
  const ChatSearchScreen({super.key});

  @override
  ConsumerState<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends ConsumerState<ChatSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  List<DocumentSnapshot> searchResult = [];
  bool isSearching = false;

  @override
  void dispose() {
    // TODO: implement dispose
    _searchController.dispose();
    super.dispose();
  }

  void searchForChat() async {
    _searchQuery = _searchController.text;
    if (_searchQuery.isEmpty) {
      setState(() {
        searchResult = [];
      });
      return;
    }
    // Perform search action with _searchQuery
    setState(() {
      isSearching = true;
    });
    await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isGreaterThanOrEqualTo: _searchQuery.trim())
        .where('phone', isLessThanOrEqualTo: '${_searchQuery.trim()}\uf8ff')
        .get()
        .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            setState(() {
              searchResult = snapshot.docs.where((doc) {
                return doc.id != ref.read(authProvider);
              }).toList();
            });
          } else {
            setState(() {
              searchResult = [];
            });
          }
        })
        .catchError((error) {
          print('Error searching for chat: $error');
        });
    setState(() {
      isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final myUserId = authState.userId;
    
    if (myUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to access chat'),
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
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter phone number to search',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      searchForChat();
                    },
                    icon: Icon(
                      Icons.search,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            if (isSearching) Center(child: CircularProgressIndicator()),
            if (!isSearching && searchResult.isEmpty)
              Center(child: Text('No results found.')),
            if (!isSearching && searchResult.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResult.length,
                  itemBuilder: (context, index) {
                    if (searchResult.isEmpty) {
                      return Center(child: Text('No results found.'));
                    }
                    DocumentSnapshot user = searchResult[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (user['profileImage'] != 'default_avatar')
                            ? NetworkImage(user['profileImage'])
                            : AssetImage('assets/images/default_avatar.png')
                                  as ImageProvider,
                      ),
                      title: Text(user['name'] ?? 'Unknown User'),
                      subtitle: Text(user['phone'] ?? 'No phone number'),
                      onTap: () async {
                        // Navigate to chat screen with this user
                        final chatId = '${user.id}_$myUserId';
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => ChatMessageScreen(
                              chatId: chatId,
                              receiver: user.data() as Map<String, dynamic>,
                              receiverId: user.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
