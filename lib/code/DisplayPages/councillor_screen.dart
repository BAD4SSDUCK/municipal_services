import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:municipal_tracker_msunduzi/code/Chat/chat_screen_councillors.dart';
import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_user_arc_screen.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';

class CouncillorScreen extends StatefulWidget {
  const CouncillorScreen({Key? key}) : super(key: key);

  @override
  State<CouncillorScreen> createState() => _CouncillorScreenState();
}

final storageRef = FirebaseStorage.instance.ref();
String councillorName = ' ';

class _CouncillorScreenState extends State<CouncillorScreen> {

  @override
  void initState() {
    _searchController.addListener(_onSearchChanged);
    if(dropdownValue == 'Select Ward'){
      getCouncillorStream();
    }
    super.initState();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _headerController;
    _messageController;
    searchText;
    super.dispose();
  }

  final user = FirebaseAuth.instance.currentUser!;

  final CollectionReference _listCounsellors =
  FirebaseFirestore.instance.collection('councillors');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();

  ///Methods and implementation for push notifications with firebase and specific device token saving
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  TextEditingController username = TextEditingController();
  TextEditingController title = TextEditingController();
  TextEditingController body = TextEditingController();
  String? mtoken = " ";

  ///This was made for testing a default message
  String title2 = "Outstanding Utilities Payment";
  String body2 = "Make sure you pay utilities before the end of this month or your services will be disconnected";

  String token = '';
  String notifyToken = '';
  String searchText = '';

  String dropdownValue = 'Select Ward';
  List<String> dropdownWards = ['Select Ward','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40',];

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  TextEditingController _searchController = TextEditingController();
  List _resultsList =[];
  List _allCouncillorResults = [];

  getCouncillorStream() async{
    var data = await FirebaseFirestore.instance.collection('councillors').orderBy('wardNum').get();

    // MyCacheManager().defaultCacheManager;

    setState(() {
      _allCouncillorResults = data.docs;
    });
    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];

    if(dropdownValue != 'Select Ward') {
      getCouncillorStream();
      for(var councillorSnapshot in _allCouncillorResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var wardNum = councillorSnapshot['wardNum'].toString().toLowerCase();

        if(wardNum.contains(dropdownValue.toLowerCase())) {
          showResults.add(councillorSnapshot);
        }
      }
    } else {
      getCouncillorStream();
      showResults = List.from(_allCouncillorResults);
    }
    setState(() {
      _allCouncillorResults = showResults;
    });
  }

  //it is called within a listview page widget
  Widget noticeItemField(String noticeData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          Expanded(
            child: Text(
              noticeData,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _getImage(BuildContext context, String imageName) async{
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);
    final imageUrl = await storageRef.child(imageName).getDownloadURL();

    ///Check what the app is running on
    if(defaultTargetPlatform == TargetPlatform.android){
      image =Image.network(
        value.toString(),
        fit: BoxFit.fill,
        width: double.infinity,
        height: double.infinity,
      );
    }else{
      // print('The url is::: $imageUrl');
      image =Image.network(
        imageUrl,
        fit: BoxFit.fitHeight,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return image;
  }

  Widget counsellorCard() {
    if (_allCouncillorResults.isNotEmpty) {
    return ListView.builder(
        itemCount: _allCouncillorResults.length,
        itemBuilder: (context, index) {
          councillorName = _allCouncillorResults[index]['councillorName'];

          return Card(
              margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('Ward Councillor',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10,),


                    InkWell(

                      ///Can be later changed to display the picture zoomed in if user taps on it.
                      onTap: () {

                      },
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 1),
                          height: 100,
                          width: 100,
                          child: Center(
                            child: Card(
                              color: Colors.grey,
                              semanticContainer: true,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 0,
                              margin: const EdgeInsets.all(10.0),
                              child:
                              FutureBuilder(
                                  future: _getImage(

                                    ///Firebase image location must be changed to display image based on the councillor name
                                      context,
                                      'files/councillors/$councillorName.jpg'),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Text('Image not yet uploaded.',),
                                            // SizedBox(height: 10,),
                                            FaIcon(Icons.person, size: 50,),
                                          ],
                                        ),
                                      );
                                    }
                                    if (snapshot.connectionState ==
                                        ConnectionState.done) {
                                      return SizedBox(
                                        height: 100,
                                        width: 100,
                                        child: snapshot.data,
                                      );
                                    }
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(5.0),
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    return Container();
                                  }
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),


                    const Text('Ward:',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    noticeItemField(_allCouncillorResults[index]['wardNum']),
                    const Text('Name:',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    noticeItemField(_allCouncillorResults[index]['councillorName']),
                    const Text('Contact Number:',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    noticeItemField(_allCouncillorResults[index]['councillorPhone']),
                    const SizedBox(height: 10,),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                BasicIconButtonGrey(
                                  onPress: () async {
                                    String phoneNum = _allCouncillorResults[index]['councillorPhone'];
                                    String passedID = user.phoneNumber!;
                                    String councillorName = _allCouncillorResults[index]['councillorName'];
                                    print(councillorName);
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) =>
                                                ChatCouncillor(chatRoomId: phoneNum, councillorName: councillorName)));
                                  },
                                  labelText: 'Chat',
                                  fSize: 14,
                                  faIcon: const FaIcon(Icons.message,),
                                  fgColor: Colors.blue,
                                  btSize: const Size(50, 38),
                                ),
                                // BasicIconButtonGrey(
                                //   onPress: () async {
                                //     String phoneNum = documentSnapshot['councillorPhone'];
                                //     final Uri _tel = Uri.parse(
                                //         'tel:$phoneNum');
                                //     launchUrl(_tel);
                                //   },
                                //   labelText: 'Contact by Phone',
                                //   fSize: 14,
                                //   faIcon: const FaIcon(Icons.add_call,),
                                //   fgColor: Colors.green,
                                //   btSize: const Size(50, 38),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

        });
    } return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget wardCounsellorCard(CollectionReference<Object?> wardCounsellorStream){
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: wardCounsellorStream.orderBy('wardNum', descending: false).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                streamSnapshot.data!.docs[index];

                councillorName = documentSnapshot['councillorName'];

                if(documentSnapshot['wardNum'].trim()==dropdownValue.trim()|| dropdownValue == 'Select Ward') {
                  return Card(
                    margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Ward Councillor',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          // const SizedBox(height: 10,),
                          InkWell(
                            ///Can be later changed to display the picture zoomed in if user taps on it.
                            onTap: () {

                            },
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 1),
                                height: 100,
                                width: 100,
                                child: Center(
                                  child: Card(
                                    color: Colors.grey,
                                    semanticContainer: true,
                                    clipBehavior: Clip.antiAliasWithSaveLayer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    elevation: 0,
                                    margin: const EdgeInsets.all(10.0),
                                    child: FutureBuilder(
                                        future: _getImage(
                                          ///Firebase image location must be changed to display image based on the meter number
                                            context, 'files/councillors/$councillorName.jpg'),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasError) {
                                            return const Padding(
                                              padding: EdgeInsets.all(10.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Text('Image not yet uploaded.',),
                                                  // SizedBox(height: 10,),
                                                  FaIcon(Icons.person,size: 50,),
                                                ],
                                              ),
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.done) {
                                            return Container(
                                              height: 100,
                                              width: 100,
                                              child: snapshot.data,
                                            );
                                          }
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Container(
                                              child: const Padding(
                                                padding: EdgeInsets.all(5.0),
                                                child: CircularProgressIndicator(),
                                              ),);
                                          }
                                          return Container();
                                        }
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Ward:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          noticeItemField(documentSnapshot['wardNum']),
                          const Text(
                            'Name:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          noticeItemField(documentSnapshot['councillorName']),
                          const Text(
                            'Contact Number:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          noticeItemField(documentSnapshot['councillorPhone']),
                          const SizedBox(height: 10,),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      BasicIconButtonGrey(
                                        onPress: () async {
                                          String phoneNum = documentSnapshot['councillorPhone'];
                                          String passedID = user.phoneNumber!;
                                          String councillorName = documentSnapshot['councillorName'];
                                          print(councillorName);
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (context) => ChatCouncillor(chatRoomId: phoneNum, councillorName: councillorName)));

                                        },
                                        labelText: 'Chat',
                                        fSize: 14,
                                        faIcon: const FaIcon(Icons.message,),
                                        fgColor: Colors.blue,
                                        btSize: const Size(50, 38),
                                      ),
                                      // BasicIconButtonGrey(
                                      //   onPress: () async {
                                      //     String phoneNum = documentSnapshot['councillorPhone'];
                                      //     final Uri _tel = Uri.parse(
                                      //         'tel:$phoneNum');
                                      //     launchUrl(_tel);
                                      //   },
                                      //   labelText: 'Contact by Phone',
                                      //   fSize: 14,
                                      //   faIcon: const FaIcon(Icons.add_call,),
                                      //   fgColor: Colors.green,
                                      //   btSize: const Size(50, 38),
                                      // ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Card();
              },
            );
          }
          return const Padding(
            padding: EdgeInsets.all(10.0),
            child: Center(
                child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Ward Counsellors',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: <Widget>[
          Visibility(
              visible: false,
              child: IconButton(
                  onPressed: (){
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const NoticeArchiveScreen()));
                  },
                  icon: const Icon(Icons.history_outlined, color: Colors.white,)),),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 10,),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0,5.0,10.0,5.0),
            child: Column(
                children: [
                  SizedBox(
                    // width: 400,
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Center(
                        child: TextField(
                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.grey,)
                            ),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.grey,)
                            ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.grey,)
                            ),
                            disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.grey,)
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            fillColor: Colors.white,
                            filled: true,
                            suffixIcon: DropdownButtonFormField <String>(
                              value: dropdownValue,
                              items: dropdownWards.map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) async{
                                setState(() {
                                  dropdownValue = newValue!;
                                });
                              },
                              icon: const Padding(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                child: Icon(Icons.arrow_circle_down_sharp),
                              ),
                              iconEnabledColor: Colors.green,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18
                              ),
                              dropdownColor: Colors.grey[50],
                              isExpanded: true,

                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
            ),
          ),
          // const SizedBox(height: 10,),
          ///made the listview card a reusable widget
          // wardCounsellorCard(_listCounsellors),

          Expanded(child: counsellorCard()),

          const SizedBox(height: 5,),

        ],
      ),
    );
  }
}
