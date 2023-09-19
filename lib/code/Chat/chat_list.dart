import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'chat_screen.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final userEmail = user?.email;
String userID = uid as String;
String userE = userEmail as String;

class _ChatListState extends State<ChatList> {

  final CollectionReference _chatsList =
  FirebaseFirestore.instance.collection('chatRoom');

  final CollectionReference _userList =
  FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Chat Rooms List',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _chatsList.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              ///this call is supposed display all chat document names.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                String chatRoomID = documentSnapshot.id;
                return Card(
                  margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Chat Room',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Text(
                            'Chat from: $chatRoomID',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 10,),
                          ChatButtonWidget(chatRoomId: chatRoomID),
                        ]
                    ),
                  ),
                );
              },
            );
         }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

///This is a button to open the selected chat from the list of chats on the server per user.
class ChatButtonWidget extends StatelessWidget {
  final String chatRoomId;

  const ChatButtonWidget({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BasicIconButtonGrey(
              onPress: () async {

                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Chat(chatRoomId: chatRoomId,)));
              },
              labelText: 'Chat',
              fSize: 16,
              faIcon: const FaIcon(Icons.chat,),
              fgColor: Theme.of(context).primaryColor,
              btSize: const Size(100, 38),
            ),
            const SizedBox(width: 5,),
          ],
        ),
      ],
    );
  }
}
