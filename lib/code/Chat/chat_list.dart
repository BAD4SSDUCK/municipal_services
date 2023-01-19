import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'chat_screen.dart';

class ChatList extends StatefulWidget {
  const ChatList({Key? key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

class _ChatListState extends State<ChatList> {

  final CollectionReference _chatsList =
  FirebaseFirestore.instance.collection('chatRoom');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Chat Rooms List'),
        backgroundColor: Colors.green,
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

                String chatRoomID = documentSnapshot.id.toString();

                print('The chat rooms listed are $chatRoomID');

                return Card(
                  margin: const EdgeInsets.all(10),
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
                            'Chat from: ' +
                                chatRoomID.toString(),
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 20,),
                          ChatButtonWidget(chatRoomId: chatRoomID.toString()),
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

  ChatButtonWidget({required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async{
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Chat(chatRoomId: chatRoomId,)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[350],
                fixedSize: const Size(108, 10),),
              child: Row(
                children: [
                  Icon(
                    Icons.chat,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 2,),
                  Text('Chat', style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,),),
                ],
              ),
            ),
            const SizedBox(width: 5,),
          ],
        ),
      ],
    );
  }
}
