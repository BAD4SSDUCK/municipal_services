import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
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

final User? user = auth.currentUser;
final uid = user?.uid;
String doccumentID = uid as String;

String chatID = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;


class _ChatListState extends State<ChatList> {

  final _chatUserController = TextEditingController();
  final _userIDController = doccumentID;

  final CollectionReference _chatsList =
  FirebaseFirestore.instance.collection('chatRoom');

 // var chatDocuments = await FirebaseFirestore.instance.collection('chatRoom').document(widget.currentUserUID).collection("Stores").getDocuments();

  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState1,
                    child: TextField(
                      controller: _chatUserController,
                      decoration: const InputDecoration(labelText: 'Document ID'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Create'),
                    onPressed: () async {
                      final String documentID = _chatUserController.text;

                      if (documentID != null) {
                        await _chatsList.add({
                          "chatRoom": documentID,
                        });

                        _chatUserController.text = '';

                        Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  /// on update the only info necessary to change should be meter reading
  Future<void> _update([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _chatUserController.text = documentSnapshot['chatRoom'];
      doccumentID = documentSnapshot['chatRoom'];
    }
    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery
                      .of(ctx)
                      .viewInsets
                      .bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: visibilityState2,
                    child: TextField(
                      controller: _chatUserController,
                      decoration: const InputDecoration(labelText: 'chatRoom'),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    child: const Text('Update'),
                    onPressed: () async {
                      final String chatID = _chatUserController.text;

                      if (chatID != null) {
                        await _chatsList
                            .doc(documentSnapshot!.id)
                            .update({
                          "chatRoom": chatID,
                          "user id" : doccumentID,
                        });

                        _chatUserController.text = '';
                        Navigator.of(context).pop();
                      }
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _delete(String users) async {
    await _chatsList.doc(users).delete();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a chat')));
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Chat List'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: _chatsList.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(

              ///this call is to display all chat users.
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

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
                              'Chat Rooms',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10,),
                          Text(
                            'Chat: ' +
                                documentSnapshot['chatRoom'].id,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),



                          const SizedBox(height: 20,),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async{
                                      ///Chat room ID needs to be passed(Will get specifics for each user as an admin)
                                      String id = documentSnapshot['chatRoom'];

                                      ///Directly to the chatapp page that creates a chat id that will be saved on the DB. for an admin to access the chat I will have to
                                      ///make a new page that lists all DB chats for the admin to select and connect to for responding to users
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) => Chat(chatRoomId: id,)));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[350],
                                      fixedSize: const Size(108, 10),),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.chat,
                                          color: Theme
                                              .of(context)
                                              .primaryColor,
                                        ),
                                        const SizedBox(width: 2,),
                                        Text('Chat', style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,),),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                  ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                          barrierDismissible: false,
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("Delete Chat"),
                                              content: const Text(
                                                  "Deleting a chat will remove all chat history!"),
                                              actions: [
                                                IconButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () async {
                                                    ScaffoldMessenger.of(
                                                        this.context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'User chat has been deleted!'),
                                                      ),
                                                    );
                                                    _delete(
                                                        documentSnapshot.id);
                                                  },
                                                  icon: const Icon(
                                                    Icons.done,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            );
                                          });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[350]),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color: Colors.red[700],
                                        ),
                                        const SizedBox(width: 2,),
                                        Text('Delete Chat', style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black),),
                                      ],
                                    ),

                                  ),
                                ],
                              ),
                            ],
                          ),
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

      /// Add new account, removed because it was not necessary for non-staff users.
      //   floatingActionButton: FloatingActionButton(
      //     onPressed: () => _create(),
      //     child: const Icon(Icons.add),
      //   ),
      //   floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat

    );
  }
}

class DatabaseMethods {
  Future<void> addUserInfo(userData) async {
    FirebaseFirestore.instance.collection("users").add(userData).catchError((e) {
      print(e.toString());
    });
  }

  getUserInfo(String phone) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("cell number", isEqualTo: phone)
        .get()
        .catchError((e) {
      print(e.toString());
    });
  }

  searchByName(String searchField) {
    return FirebaseFirestore.instance
        .collection("users")
        .where('first name', isEqualTo: searchField)
        .get();
  }

  Future<bool> addChatRoom(Map<String, dynamic> chatRoom, String chatRoomId) async {
    try {
      await FirebaseFirestore.instance
          .collection("chatRoom")
          .doc(chatRoomId)
          .set(chatRoom);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }


  getChats(String chatRoomId) async{
    return FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy('time')
        .snapshots();
  }


  Future<void> addMessage(String chatRoomId, chatMessageData) async {

    FirebaseFirestore.instance.collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .add(chatMessageData).catchError((e){
      print(e.toString());
    });
  }

  getUserChats(String itIsMyName) async {
    return await FirebaseFirestore.instance
        .collection("chatRoom")
        .where('users', arrayContains: itIsMyName)
        .snapshots();
  }

}