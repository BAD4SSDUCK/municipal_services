import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _databaseReference = FirebaseDatabase.instance.ref();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _databaseReference.child('messages').onChildAdded.listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder(
              stream: _databaseReference.child('messages').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  var messages = snapshot.data?.snapshot.value as Map;
                  List<Message> messageList = [];
                  messages.forEach((index, message) {
                    messageList.add(Message.fromJson(index, message));
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messageList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(messageList[index].text),
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Enter message...',
            ),
          ),
          ElevatedButton(
            child: Text('Send'),
            onPressed: () {
              _databaseReference
                  .child('messages')
                  .push()
                  .set({'text': _textController.text});
              _textController.clear();
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            },
          )
        ],
      ),
    );
  }
}

class Message {
  String key;
  String text;

  Message({required this.key, required this.text});

  Message.fromJson(String key, Map json)
      : key = key,
        text = json['text'];
}
