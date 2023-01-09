import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final user = FirebaseAuth.instance.currentUser!;

  void getCurrentUser() async {
    //final user = await _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Municipality Chat'),
          backgroundColor: Colors.green,
        ),
      body: SafeArea(
        child: Column(

        ),
      ),
    );
  }
}
