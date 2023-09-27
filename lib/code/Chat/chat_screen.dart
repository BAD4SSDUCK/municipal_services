import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Chat extends StatefulWidget {
  String chatRoomId;

  Chat({required this.chatRoomId});

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {

  late bool _isLoading;
  late Stream<QuerySnapshot> chats;
  TextEditingController messageEditingController = TextEditingController();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    ///This is the circular loading widget in this future.delayed call
    _isLoading = true;
    checkUser();
    print(Constants.myName);
    Future.delayed(const Duration(seconds: 3),(){
      setState(() {
        _isLoading = false;
      });
    });

    DatabaseMethods().getChats(widget.chatRoomId).then((val) {
      setState(() {
        chats = val;
      });
    });
    super.initState();
  }

  Future<void> checkUser() async{
    print('username must be :::${user?.phoneNumber}');
    if(user?.phoneNumber == null ||
        user?.phoneNumber == ''){
      useNum = '';
      useEmail = user?.email!;
      Constants.myName = useEmail;
    } else if (user?.email == null ||
        user?.email == ''){
      useNum = user?.phoneNumber!;
      useEmail = '';
      Constants.myName = useNum;
    }

    print('chatroom name is ${widget.chatRoomId}');
    print('username is :::${Constants.myName}');
  }

  Widget chatMessages(){
    return StreamBuilder<QuerySnapshot>(
      stream: chats, //Provide the proper stream source here
      builder: (context, snapshot){
        return snapshot.hasData ? ListView.builder(
            itemCount: snapshot.data?.docs.length ?? 0,
            itemBuilder: (context, index){
              return MessageTile(
                message: snapshot.data?.docs[index]["message"],
                sendByMe: Constants.myName == snapshot.data?.docs[index]["sendBy"],

              );
            }) : Container();
      },
    );
  }

  String official = 'official';

  addMessage() {
    if (messageEditingController.text.isNotEmpty) {
      if (Constants.myName == '') {
        Constants.myName = useEmail;
        // 'official';
        Map<String, dynamic> chatMessageMap = {
          "sendBy": Constants.myName,
          "message": messageEditingController.text,
          'time': DateTime
              .now()
              .millisecondsSinceEpoch,
        };

        DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);

        setState(() {
          messageEditingController.text = "";
        });
      } else {
        Map<String, dynamic> chatMessageMap = {
          "sendBy": Constants.myName,
          "message": messageEditingController.text,
          'time': DateTime
              .now()
              .millisecondsSinceEpoch,
        };

        DatabaseMethods().addMessage(widget.chatRoomId, chatMessageMap);

        setState(() {
          messageEditingController.text = "";
        });
      }
    }
  }


  ///need to fix auto generate to custom named generate
  Future<void> setIDName() async {

    String thisNewChat = widget.chatRoomId;
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(thisNewChat).doc(thisNewChat).get();

    DatabaseMethods().addChatDocName(documentSnapshot, thisNewChat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Chat',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        child: Stack(
          children: [_isLoading
              ? const Center(child: CircularProgressIndicator(),)
              :
          chatMessages(),
            Container(alignment: Alignment.bottomCenter,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                color: Colors.grey[350],
                child: Row(
                  children: [
                    Expanded(
                        child: TextField(
                          controller: messageEditingController,
                          style: simpleTextStyle(),
                          decoration: InputDecoration(
                              hintText: "Message ...",
                              hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                              border: InputBorder.none
                          ),
                        )),
                    SizedBox(width: 16,),
                    GestureDetector(
                      onTap: () {
                        addMessage();
                      },
                      child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF39833C),
                                    Color(0xFF474747)
                                  ],
                                  begin: FractionalOffset.topLeft,
                                  end: FractionalOffset.bottomRight
                              ),
                              borderRadius: BorderRadius.circular(40)
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Image.asset("assets/images/send.png",
                            height: 30, width: 30,)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool sendByMe;

  const MessageTile({super.key, required this.message, required this.sendByMe});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: sendByMe ? 0 : 24,
          right: sendByMe ? 24 : 0),
      alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: sendByMe
            ? EdgeInsets.only(left: 30)
            : EdgeInsets.only(right: 30),
        padding: EdgeInsets.only(
            top: 17, bottom: 17, left: 20, right: 20),
        decoration: BoxDecoration(
            borderRadius: sendByMe ? BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomLeft: Radius.circular(23)
            ) :
            BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomRight: Radius.circular(23)),
            gradient: LinearGradient(
              colors: sendByMe ? [
                const Color(0xff007EF4),
                const Color(0xff2A75BC)
              ]
                  : [
                const Color(0xFF505050),
                const Color(0xFF474747)
              ],
            )
        ),
        child: Text(message,
            textAlign: TextAlign.start,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'OverpassRegular',
                fontWeight: FontWeight.w400)),
      ),
    );
  }
}

final FirebaseAuth auth = FirebaseAuth.instance;
final User? user = auth.currentUser;
String? useNum ;
String? useEmail ;

///Constraints class
class Constants{
  static String? myName = useNum;
}

///Widget items
Widget appBarMain(BuildContext context) {
  return AppBar(
    title: Image.asset(
      "assets/images/logo.png",
      height: 40,
    ),
    elevation: 0.0,
    centerTitle: false,
  );
}

InputDecoration textFieldInputDecoration(String hintText) {
  return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white54),
      focusedBorder:
      UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      enabledBorder:
      UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)));
}

TextStyle simpleTextStyle() {
  return TextStyle(color: Colors.black54, fontSize: 16);
}

TextStyle biggerTextStyle() {
  return TextStyle(color: Colors.white, fontSize: 17);
}

///Database functions/APIs
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

  Future<void> addChatDocName(DocumentSnapshot? documentSnapshot, String chatRoomId) async{
    final CollectionReference namedChatAdd =
    FirebaseFirestore.instance.collection("chatRoom");

    if (documentSnapshot != null) {
      await namedChatAdd.add({
        "chatRoom": chatRoomId,
      });
    }
  }
}
