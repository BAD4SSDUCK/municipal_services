import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
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

import 'package:municipal_tracker_msunduzi/code/NoticePages/notice_config_arc_screen.dart';
import 'package:municipal_tracker_msunduzi/code/faultPages/fault_task_screen_archive.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/push_notification_message.dart';

class NoticeConfigScreen extends StatefulWidget {
  const NoticeConfigScreen({Key? key, required this.userNumber}) : super(key: key);

  final String userNumber;

  @override
  State<NoticeConfigScreen> createState() => _NoticeConfigScreenState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;

class _NoticeConfigScreenState extends State<NoticeConfigScreen> {

  @override
  void initState() {
    if(_searchController.text == ""){
      getUsersTokenStream();
      getUsersPropStream();
    }
    _fetchData();
    _fetchTokenData();
    checkAdmin();
    getUsersTokenStream();
    getUsersPropStream();
    getPropSuburbStream();
    countResult();
    _searchWardController.addListener(_onWardChanged);
    _searchController.addListener(_onSearchChanged);
    _searchSuburbController.addListener(_onSearchChanged);
    super.initState();
  }

  @override
  void dispose() {
    _headerController;
    _messageController;
    _allUserTokenResults;
    _allUserPropResults;
    _allUserResults;
    searchResultsList();
    token;
    title;
    body;
    searchText;
    usersNumbers;
    usersTokens;
    _searchWardController.dispose();
    _searchWardController.removeListener(_onWardChanged);
    _searchController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchWardController.dispose();
    _searchWardController.removeListener(_onSearchChanged);
    super.dispose();
  }

  final CollectionReference _listUserTokens =
  FirebaseFirestore.instance.collection('UserToken');

  final CollectionReference _listNotifications =
  FirebaseFirestore.instance.collection('Notifications');

  final CollectionReference _listProps =
  FirebaseFirestore.instance.collection('properties');

  final _headerController = TextEditingController();
  final _messageController = TextEditingController();
  late final TextEditingController _searchBarController = TextEditingController();
  late bool _noticeReadController;

  List<String> usersNumbers = [];
  List<String> usersTokens = [];
  List<String> usersRetrieve = [];

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

  bool visShow = true;
  bool visHide = false;
  bool adminAcc = false;

  int numTokens = 0;

  TextEditingController _searchController = TextEditingController();
  TextEditingController _searchWardController = TextEditingController();
  TextEditingController _searchSuburbController = TextEditingController();

  final CollectionReference _propList =  FirebaseFirestore.instance.collection('properties');

  List<String> dropdownWards = ['Select Ward','01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32','33','34','35','36','37','38','39','40',];
  String dropdownValue = 'Select Ward';
  String dropdownSuburbValue = 'Select Suburb';
  List<String> dropdownSuburbs = ['Select Suburb'];
  String userNameProp = '';
  String userAddress = '';
  String userWardProp = '';
  String userValid = '';
  String userPhoneProp = '';
  String userPhoneToken = '';
  String userPhoneNumber = '';
  String userRole = '';

  List _allUserResults = [];
  List _allUserPropResults = [];
  List _allUserWardResults = [];
  List _allUserSuburbResults = [];
  List _allPropResults = [];
  List _allSuburbResults = [];
  List _resultsList =[];
  List _allUserTokenResults = [];

  getUsersTokenStream() async{
    var data = await FirebaseFirestore.instance.collection('UserToken').get();
    _allUserTokenResults = data.docs;
    searchResultsList();
  }

  _onSearchChanged() async {
    searchResultsList();
  }

  searchResultsList() async {
    var showResults = [];
    if(_searchController.text != "") {
      getUsersPropStream();
      for(var userPropSnapshot in _allUserPropResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var phoneNumber = userPropSnapshot.id.toString().toLowerCase();

        if(phoneNumber.contains(_searchController.text.toLowerCase())) {
          showResults.add(userPropSnapshot);
        }
      }
    } else {
      getUsersPropStream();
      showResults = List.from(_allUserPropResults);
    }
    if(context.mounted) {
      setState(() {
      _allUserPropResults = showResults;
    });
    }
  }

  void countResult() async {
    _searchBarController.text = widget.userNumber;
    searchText = widget.userNumber;

    var query = _listUserTokens.where("token");
    var snapshot = await query.get();
    var count = snapshot.size;
    numTokens = snapshot.size;
    print('Records are ::: $count');
    print('num tokens are ::: $numTokens');
  }


  User? user = FirebaseAuth.instance.currentUser;

  void checkAdmin() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      adminAcc = true;
    } else {
      adminAcc = false;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    if(context.mounted) {
      setState(() {
      _allUserResults = data.docs;
    });
    }
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          adminAcc = true;
        } else {
          adminAcc = false;
        }
      }
    }
  }

  getUsersPropStream() async{
    var data = await FirebaseFirestore.instance.collection('properties').get();
    if(context.mounted) {
      setState(() {
        _allPropResults = data.docs;
        _allUserPropResults = data.docs;
        _allUserWardResults = data.docs;
        _allUserSuburbResults = data.docs;
      });
    }
    getUserDetails();
  }

  getPropSuburbStream() async{
    var data = await FirebaseFirestore.instance.collection('suburbs').orderBy('suburb', descending: false).get();

    if(context.mounted) {
      setState(() {
        _allSuburbResults = data.docs;
      });
    }
    getSuburbDetails();
  }

  getSuburbDetails() async{
    for(var suburbSnapshot in _allSuburbResults){
      dropdownSuburbs.add(suburbSnapshot['suburb']);
      print('the suburbs are $dropdownSuburbs');
    }
  }

  searchWardsList() async {
    var showResults = [];
    if(_searchWardController.text != "Select Ward") {
      getUsersPropStream();
      for(var propSnapshot in _allUserPropResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var ward = propSnapshot['ward'].toString().toLowerCase();

        if(ward.contains(_searchController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getUsersPropStream();
      showResults = List.from(_allUserPropResults);
    }
    if(_searchSuburbController.text != "Select Suburb") {
      getUsersPropStream();
      for(var propSnapshot in _allUserPropResults){
        ///Need to build a property model that retrieves property data entirely from the db
        var suburb = propSnapshot['address'].toString().toLowerCase();

        if(suburb.contains(_searchSuburbController.text.toLowerCase())) {
          showResults.add(propSnapshot);
        }
      }
    } else {
      getUsersPropStream();
      showResults = List.from(_allUserPropResults);
    }
    if(context.mounted) {
      setState(() {
      _allUserPropResults = showResults;
    });
    }
  }

  _onWardChanged() async {
    searchWardsList();
  }

  Future<List<Map<String, dynamic>>> _fetchData() async {
    List<Map<String, dynamic>> combinedData = [];
    // Fetch data from first Firebase table
    QuerySnapshot allUserPropSnapshot = await FirebaseFirestore.instance
        .collection('properties')
        .get();

    print('The snapshot is::: $allUserPropSnapshot');
    List<DocumentSnapshot> allUserPropDocs = allUserPropSnapshot.docs;
    for (var doc in allUserPropDocs) {
      String phoneNumber = doc['cell number'];
      String propertyOwner = '${doc['first name']} ${doc['last name']}';
      String propertyAddress = doc['address'];
      String propertyWard = doc['ward'];
      // Check if this phoneNumber exists in the second table
      QuerySnapshot allUserTokenSnapshot = await FirebaseFirestore.instance
          .collection('UserToken')
          .where(doc.id, isEqualTo: phoneNumber)
          .get();
      List<DocumentSnapshot> allUserTokenDocs = allUserTokenSnapshot.docs;
      if (allUserTokenDocs.isNotEmpty) {
        // If phoneNumber exists in second table, combine data
        String token = allUserTokenDocs.first['token'];
        combinedData.add({
          'name': propertyOwner,
          'address': propertyAddress,
          'ward': propertyWard,
          'phoneNumber': phoneNumber,
          'registered': 'User will receive notice',
          'token': token,
        });
      } else {
        // If phoneNumber doesn't exist in second table, add only table1 data
        combinedData.add({
          'name': propertyOwner,
          'address': propertyAddress,
          'ward': propertyWard,
          'phoneNumber': phoneNumber,
          'registered': 'User not  this app',
          'token': 'No token data available',
        });
      }
    }
    return combinedData;
  }

  Future<List<Map<String, dynamic>>> _fetchTokenData() async {
    List<Map<String, dynamic>> combinedData = [];


    // Iterate over UserToken documents
    for (var tokenDoc in _allUserTokenResults) {
      String phoneNumber = tokenDoc.id;
      String token = tokenDoc['token'];

      // Fetch properties data where cell number matches phoneNumber
      QuerySnapshot matchingPropertiesSnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('cell number', isEqualTo: phoneNumber)
          .get();

      List<DocumentSnapshot> matchingPropertiesDocs = matchingPropertiesSnapshot.docs;

      if (matchingPropertiesDocs.isNotEmpty) {
        // If matching properties found, combine data
        for (var propertyDoc in matchingPropertiesDocs) {
          String propertyOwner = '${propertyDoc['first name']} ${propertyDoc['last name']}';
          String propertyAddress = propertyDoc['address'];
          String propertyWard = propertyDoc['ward'];

          combinedData.add({
            'name': propertyOwner,
            'address': propertyAddress,
            'ward': propertyWard,
            'phoneNumber': phoneNumber,
            'registered': 'User will receive notice',
            'token': token,
          });
        }
      } else {
        // If no matching properties found, add token data with default values
        combinedData.add({
          'name': 'No Property Owner Found',
          'address': 'No Address Found',
          'ward': 'No Ward Found',
          'phoneNumber': phoneNumber,
          'registered': 'User not registered in this app',
          'token': token,
        });
      }
    }

    return combinedData;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('User Notifications', style: TextStyle(color: Colors.white),),
          backgroundColor: Colors.green,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: <Widget>[
            Visibility(
              visible: adminAcc,
              child: IconButton(
                  onPressed: () {
                    usersNumbers = [];
                    usersTokens = [];
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const NoticeConfigArcScreen()));
                  },
                  icon: const Icon(
                    Icons.history_outlined, color: Colors.white,)),),
          ],
          bottom: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Notify\nAll', textAlign: TextAlign.center,),),
                ),
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Target\nNotice', textAlign: TextAlign.center,),),
                ),
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Ward\nNotice', textAlign: TextAlign.center,),),
                ),
                Tab(
                  child: Container(alignment: Alignment.center,
                    child: const Text('Suburb\nNotice', textAlign: TextAlign.center,),),
                ),
              ]
          ),
        ),

        body: TabBarView(
            children: [

              ///Tab for all
              Column(
                children: [
                  const SizedBox(height: 8,),

                  ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                  ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

                  BasicIconButtonGrey(
                    onPress: () async {
                      _headerController.text = '';
                      _messageController.text = '';
                      _notifyAllUser();
                    },
                    labelText: 'Send Notice To All',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.notifications,),
                    fgColor: Theme.of(context).primaryColor,
                    btSize: const Size(300, 50),
                  ),

                  const SizedBox(height: 5,),

                  ///made the listview card a reusable widget
                  Expanded(
                      child: userCard(),
                  ),

                ],
              ),

              ///Tab for searching
              Column(
                children: [
                  ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                  ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

                  /// Search bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10.0,5.0,10.0,5.0),
                    child: SearchBar(

                      controller: _searchController,
                      padding: const MaterialStatePropertyAll<EdgeInsets>(
                          EdgeInsets.symmetric(horizontal: 16.0)),
                      leading: const Icon(Icons.search),
                      hintText: "Search by Phone Number...",
                      onChanged: (value) async{
                        if(context.mounted) {
                          setState(() {
                          searchText = value;
                          print('this is the input text ::: $searchText');
                        });
                        }
                      },
                    ),
                  ),
                  /// Search bar end

                  ///made the listview card a reusable widget
                  Expanded(
                      child: userTokenSearchCard(),
                  ),

                ],
              ),

              ///Tab for wards
              Column(
                children: [
                  ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                  ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

                  /// Warc select bar
                  const SizedBox(height: 5,),
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
                                  controller: _searchWardController,
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
                                        if(context.mounted) {
                                          setState(() {
                                          getUsersTokenStream();
                                          getUsersPropStream();
                                          dropdownValue = newValue!;
                                          _searchWardController.text = dropdownValue;
                                        });
                                        }
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
                  /// Search bar end

                  const SizedBox(height: 5,),

                  BasicIconButtonGrey(
                    onPress: () async {
                      _notifyWardUsers();
                    },
                    labelText: 'Notify Selected Ward',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.notifications,),
                    fgColor: Theme.of(context).primaryColor,
                    btSize: const Size(300, 50),
                  ),

                  const SizedBox(height: 5,),
                  ///made the listview card a reusable widget
                  Expanded(
                    child: userWardCard(),
                  ),

                ],
              ),

              ///Tab for suburb
              Column(
                children: [
                  ///this onPress code bellow is used to set the message information and pop it up to the user in their notifications.
                  ///button not needed as it will only be used when a new chat is sent or when an admin sends to a specific phone which will be a list of tokens per device

                  /// Warc select bar
                  const SizedBox(height: 5,),
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
                                  controller: _searchSuburbController,
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
                                      value: dropdownSuburbValue,
                                      items: dropdownSuburbs.map<DropdownMenuItem<String>>((String value) {
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
                                        if(context.mounted) {
                                          setState(() {
                                            getUsersTokenStream();
                                            getUsersPropStream();
                                            dropdownSuburbValue = newValue!;
                                            _searchSuburbController.text = dropdownSuburbValue;
                                          });
                                        }
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
                  /// Search bar end

                  const SizedBox(height: 5,),

                  BasicIconButtonGrey(
                    onPress: () async {
                      _notifyWardUsers();
                    },
                    labelText: 'Notify Selected Suburb',
                    fSize: 16,
                    faIcon: const FaIcon(Icons.notifications,),
                    fgColor: Theme.of(context).primaryColor,
                    btSize: const Size(300, 50),
                  ),

                  const SizedBox(height: 5,),
                  ///made the listview card a reusable widget
                  Expanded(
                    child: userSuburbCard(),
                  ),

                ],
              ),

            ]
        ),
      ),
    );
  }

  Widget tokenItemField(String tokenData, String userNameProp, String userAddress, String userPhoneProp, String userValidity, String userWardProp) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'User: $userNameProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phone: $tokenData',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Property: $userAddress',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Register status: $userValidity',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ward: $userWardProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget tokenItemWardField(String tokenData, String userNameProp, String userAddress, String userPhoneProp, String userNumber, String userWardProp) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'User: $userNameProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Phone: $tokenData',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Property: $userAddress',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ward: $userWardProp',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //this widget is for displaying users phone numbers with the hidden stored device token
  Widget userCard() {
    if (_allPropResults.isNotEmpty){
      return ListView.builder(
          itemCount: _allPropResults.length,
          itemBuilder: (context, index) {
            userNameProp =
            '${_allPropResults[index]['first name']} ${_allPropResults[index]['last name']}';
            userAddress = _allPropResults[index]['address'];
            userWardProp = _allPropResults[index]['ward'];
            userPhoneNumber = _allPropResults[index]['cell number'];

            for (var tokenSnapshot in _allUserTokenResults) {
              if (tokenSnapshot.id == _allPropResults[index]['cell number']) {
                userPhoneToken = tokenSnapshot['token'];
                notifyToken = tokenSnapshot['token'];
                userValid = 'User will receive notification';
                break;
              } else {
                userPhoneToken = '';
                notifyToken = '';
                userValid = 'User is not yet registered';
              }
            }

            return Card(
              margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text('Users Device Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    tokenItemField(
                        userPhoneNumber, userNameProp,
                        userAddress,
                        userPhoneNumber, userValid,
                        userWardProp),
                    Visibility(
                      visible: false,
                      child: Text('User Token: $userPhoneToken',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(height: 5,),
                  ],
                ),
              ),
            );
          }
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget userTokenSearchCard() {
    if (_allUserPropResults.isNotEmpty){
      return ListView.builder(
          itemCount: _allUserPropResults.length,
          itemBuilder: (context, index) {

            userNameProp = '${_allUserPropResults[index]['first name']} ${_allUserPropResults[index]['last name']}';
            userAddress = _allUserPropResults[index]['address'];
            userWardProp = _allUserPropResults[index]['ward'];
            userPhoneNumber = _allUserPropResults[index]['cell number'];

            for (var tokenSnapshot in _allUserTokenResults) {
              if (tokenSnapshot.id == _allUserPropResults[index]['cell number']) {
                notifyToken = tokenSnapshot['token'];
                userValid = 'User will receive notification';
                break;
              } else {
                notifyToken = '';
                userValid = 'User is not yet registered';
              }
            }

            if (_searchController.text == '' || userPhoneNumber.contains(_searchController.text)) {
              return Card(
                margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Users Device Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      tokenItemField(
                          userPhoneNumber, userNameProp,
                          userAddress,
                          userPhoneNumber, userValid,
                          userWardProp),
                      Visibility(
                        visible: false,
                        child: Text('User Token: $userPhoneToken',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              BasicIconButtonGrey(
                                onPress: () async {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(16))),
                                          title: const Text("Call User!"),
                                          content: const Text("Would you like to call the user directly?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                String cellGiven = userPhoneNumber;

                                                final Uri _tel = Uri.parse('tel:${cellGiven.toString()}');
                                                launchUrl(_tel);

                                                Navigator.of(context).pop();
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
                                labelText: 'Call User',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.call,),
                                fgColor: Colors.green,
                                btSize: const Size(50, 38),
                              ),
                              BasicIconButtonGrey(
                                onPress: () async {
                                  for (var tokenSnapshot in _allUserTokenResults) {
                                    if (tokenSnapshot.id == _allUserPropResults[index]['cell number']) {
                                      notifyToken = tokenSnapshot['token'];
                                      userValid = 'User will receive notification';
                                      break;
                                    } else {
                                      notifyToken = '';
                                      userValid = 'User is not yet registered';
                                    }
                                  }
                                  if(notifyToken!=''){
                                    userPhoneNumber = _allUserPropResults[index]['cell number'];
                                    _notifyThisUser(_allUserPropResults[index]);
                                  } else {
                                    Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                                  }
                                },
                                labelText: 'Notify',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.edit,),
                                fgColor: Theme
                                    .of(context)
                                    .primaryColor,
                                btSize: const Size(50, 38),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5,),
                          BasicIconButtonGrey(
                            onPress: () async {
                              if(notifyToken!=''){
                                userPhoneNumber = _allUserPropResults[index]['cell number'];
                                _disconnectThisUser(_allUserTokenResults[index]);
                              } else {
                                Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                              }
                            },
                            labelText: 'Disconnect',
                            fSize: 14,
                            faIcon: const FaIcon(Icons.warning_amber,),
                            fgColor: Colors.amber,
                            btSize: const Size(50, 38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              const SizedBox();
            }
          }
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget userWardCard() {
    if (_allUserPropResults.isNotEmpty){
      return ListView.builder(
          itemCount: _allUserWardResults.length,
          itemBuilder: (context, index) {

            userNameProp = '${_allUserWardResults[index]['first name']} ${_allUserWardResults[index]['last name']}';
            userAddress = _allUserWardResults[index]['address'];
            userWardProp = _allUserWardResults[index]['ward'];
            userPhoneNumber = _allUserWardResults[index]['cell number'];

            for (var tokenSnapshot in _allUserTokenResults) {
              if (tokenSnapshot.id == _allUserWardResults[index]['cell number']) {
                notifyToken = tokenSnapshot['token'];
                userValid = 'User will receive notification';
                break;
              } else {
                notifyToken = '';
                userValid = 'User is not yet registered';
              }
            }

            if (_allUserWardResults[index]['cell number'].contains('+27') &&
                (userWardProp == dropdownValue ||
                    dropdownValue == 'Select Ward')) {
              return Card(
                margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Users Device Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      tokenItemField(
                          userPhoneNumber, userNameProp,
                          userAddress,
                          userPhoneNumber, userValid,
                          userWardProp),
                      Visibility(
                        visible: false,
                        child: Text('User Token: $notifyToken',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              BasicIconButtonGrey(
                                onPress: () async {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .all(
                                                  Radius.circular(16))),
                                          title: const Text("Call User!"),
                                          content: const Text(
                                              "Would you like to call the user directly?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                String cellGiven = userPhoneNumber;

                                                final Uri _tel = Uri.parse('tel:${cellGiven.toString()}');
                                                launchUrl(_tel);

                                                Navigator.of(context).pop();
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
                                labelText: 'Call User',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.call,),
                                fgColor: Colors.green,
                                btSize: const Size(50, 38),
                              ),
                              BasicIconButtonGrey(
                                onPress: () async {
                                  for (var tokenSnapshot in _allUserTokenResults) {
                                    if (tokenSnapshot.id == _allUserWardResults[index]['cell number']) {
                                      notifyToken = tokenSnapshot['token'];
                                      userValid = 'User will receive notification';
                                      break;
                                    } else {
                                      notifyToken = '';
                                      userValid = 'User is not yet registered';
                                    }
                                  }
                                  if(notifyToken!=''){
                                    userPhoneNumber = _allUserPropResults[index]['cell number'];
                                    _notifyThisUser(_allUserWardResults[index]);
                                  } else {
                                    Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                                  }
                                },
                                labelText: 'Notify',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.edit,),
                                fgColor: Theme
                                    .of(context)
                                    .primaryColor,
                                btSize: const Size(50, 38),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5,),
                          BasicIconButtonGrey(
                            onPress: () async {
                              for (var tokenSnapshot in _allUserTokenResults) {
                                if (tokenSnapshot.id == _allUserWardResults[index]['cell number']) {
                                  notifyToken = tokenSnapshot['token'];
                                  userValid = 'User will receive notification';
                                  break;
                                } else {
                                  notifyToken = '';
                                  userValid = 'User is not yet registered';
                                }
                              }
                              if(notifyToken!=''){
                                userPhoneNumber = _allUserWardResults[index]['cell number'];
                                _disconnectThisUser(_allUserWardResults[index]);
                              } else {
                                Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                              }
                            },
                            labelText: 'Disconnect',
                            fSize: 14,
                            faIcon: const FaIcon(Icons.warning_amber,),
                            fgColor: Colors.amber,
                            btSize: const Size(50, 38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              const SizedBox();
            }
          }
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  Widget userSuburbCard() {
    if (_allUserSuburbResults.isNotEmpty){
      return ListView.builder(
          itemCount: _allUserSuburbResults.length,
          itemBuilder: (context, index) {

            userNameProp = '${_allUserSuburbResults[index]['first name']} ${_allUserSuburbResults[index]['last name']}';
            userAddress = _allUserSuburbResults[index]['address'];
            userWardProp = _allUserSuburbResults[index]['ward'];
            userPhoneNumber = _allUserSuburbResults[index]['cell number'];

            for (var tokenSnapshot in _allUserTokenResults) {
              if (tokenSnapshot.id == _allUserSuburbResults[index]['cell number']) {
                notifyToken = tokenSnapshot['token'];
                userValid = 'User will receive notification';
                break;
              } else {
                notifyToken = '';
                userValid = 'User is not yet registered';
              }
            }

            if (_allUserSuburbResults[index]['cell number'].contains('+27') &&
                (_allUserSuburbResults[index]['address'].toLowerCase().contains(dropdownSuburbValue.toString().toLowerCase()) ||
                    dropdownSuburbValue == 'Select Suburb')) {
              return Card(
                margin: const EdgeInsets.fromLTRB(10.0, 5.0, 10.0, 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text('Users Device Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      tokenItemField(
                          userPhoneNumber, userNameProp,
                          userAddress,
                          userPhoneNumber, userValid,
                          userWardProp),
                      Visibility(
                        visible: false,
                        child: Text('User Token: $notifyToken',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ),
                      const SizedBox(height: 10,),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              BasicIconButtonGrey(
                                onPress: () async {
                                  showDialog(
                                      barrierDismissible: false,
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius
                                                  .all(
                                                  Radius.circular(16))),
                                          title: const Text("Call User!"),
                                          content: const Text(
                                              "Would you like to call the user directly?"),
                                          actions: [
                                            IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                String cellGiven = userPhoneNumber;

                                                final Uri _tel = Uri.parse('tel:${cellGiven.toString()}');
                                                launchUrl(_tel);

                                                Navigator.of(context).pop();
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
                                labelText: 'Call User',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.call,),
                                fgColor: Colors.green,
                                btSize: const Size(50, 38),
                              ),
                              BasicIconButtonGrey(
                                onPress: () async {
                                  for (var tokenSnapshot in _allUserTokenResults) {
                                    if (tokenSnapshot.id == _allUserSuburbResults[index]['cell number']) {
                                      notifyToken = tokenSnapshot['token'];
                                      userValid = 'User will receive notification';
                                      break;
                                    } else {
                                      notifyToken = '';
                                      userValid = 'User is not yet registered';
                                    }
                                  }
                                  if(notifyToken!=''){
                                    userPhoneNumber = _allUserPropResults[index]['cell number'];
                                    _notifyThisUser(_allUserSuburbResults[index]);
                                  } else {
                                    Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                                  }
                                },
                                labelText: 'Notify',
                                fSize: 14,
                                faIcon: const FaIcon(Icons.edit,),
                                fgColor: Theme
                                    .of(context)
                                    .primaryColor,
                                btSize: const Size(50, 38),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5,),
                          BasicIconButtonGrey(
                            onPress: () async {
                              for (var tokenSnapshot in _allUserTokenResults) {
                                if (tokenSnapshot.id == _allUserSuburbResults[index]['cell number']) {
                                  notifyToken = tokenSnapshot['token'];
                                  userValid = 'User will receive notification';
                                  break;
                                } else {
                                  notifyToken = '';
                                  userValid = 'User is not yet registered';
                                }
                              }
                              if(notifyToken!=''){
                                userPhoneNumber = _allUserPropResults[index]['cell number'];
                                _disconnectThisUser(_allUserSuburbResults[index]);
                              } else {
                                Fluttertoast.showToast(msg: 'This user has not registered on this app yet!', gravity: ToastGravity.CENTER);
                              }
                            },
                            labelText: 'Disconnect',
                            fSize: 14,
                            faIcon: const FaIcon(Icons.warning_amber,),
                            fgColor: Colors.amber,
                            btSize: const Size(50, 38),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            } else {
              const SizedBox();
            }
          }
      );
    }
    return const Padding(
      padding: EdgeInsets.all(10.0),
      child: Center(
          child: CircularProgressIndicator()),
    );
  }

  //This class is for updating the notification
  Future<void> _notifyUpdateUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _noticeReadController = documentSnapshot['read'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = Future(() async => showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(labelText: 'Message'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.only(left: 0.0, right: 25.0),
                                child: Row(
                                  children: <Widget>[
                                    const Text('Notice Has Been Read', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),),
                                    const SizedBox(width: 5,),
                                    Checkbox(
                                      checkColor: Colors.white,
                                      fillColor: MaterialStateProperty.all<Color>(Colors.green),
                                      value: _noticeReadController,
                                      onChanged: (bool? value) async {
                                        if(context.mounted) {
                                          setState(() {
                                          _noticeReadController = value!;
                                        });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                  final String tokenSelected = notifyToken;
                                  final String? userNumber = documentSnapshot?.id;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  final bool readStatus = _noticeReadController;

                                  if (title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                    await _listNotifications.doc(documentSnapshot?.id).update({
                                      "token": tokenSelected,
                                      "user": userNumber,
                                      "title": notificationTitle,
                                      "body": notificationBody,
                                      "read": readStatus,
                                      "date": notificationDate,
                                    });

                                    ///It can be changed to the firebase notification
                                    String titleText = title.text;
                                    String bodyText = body.text;

                                    ///gets users phone token to send notification to this phone
                                    if (userNumber != "") {
                                      DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                      String token = snap['token'];
                                      sendPushMessage(token, titleText, bodyText);
                                    }
                                  } else {
                                    Fluttertoast.showToast(msg: 'Please fill Header and Message of the Notification!', gravity: ToastGravity.CENTER);
                                  }

                                  username.text = '';
                                  title.text = '';
                                  body.text = '';
                                  _headerController.text = '';
                                  _messageController.text = '';
                                  _noticeReadController = false;

                                  if(context.mounted)Navigator.of(context).pop();
                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              })));
    }

    _createBottomSheet();
  }

  Future<void> _notifyAllUser([DocumentSnapshot? documentSnapshot]) async {
    _searchBarController.text = '';

    // for (var i = 0; i < numTokens; i++) {
    //   if (documentSnapshot?.id == documentSnapshot[i]) {
    //     usersNumbers.removeAt(i);
    //   }
    // }
    print(usersNumbers);
    print(usersNumbers.length);
    print(usersTokens);
    print(usersTokens.length);

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = Future(() async => showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Notify All Users',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(labelText: 'Message'),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                  for (int i = 0; i < usersTokens.length; i++) {
                                    final String tokenSelected = usersTokens[i];
                                    final String userNumber = usersNumbers[i];
                                    final String notificationTitle = title.text;
                                    final String notificationBody = body.text;
                                    final String notificationDate = formattedDate;
                                    const bool readStatus = false;

                                    if (title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                      await _listNotifications.add({
                                        "token": tokenSelected,
                                        "user": userNumber,
                                        "title": notificationTitle,
                                        "body": notificationBody,
                                        "read": readStatus,
                                        "date": notificationDate,
                                        "level": 'general',
                                      });

                                      ///It can be changed to the firebase notification
                                      String titleText = title.text;
                                      String bodyText = body.text;

                                      ///gets users phone token to send notification to this phone
                                      if (userNumber != "") {
                                        DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                        String token = snap['token'];
                                        print('The phone number is retrieved as ::: $userNumber');
                                        print('The token is retrieved as ::: $token');
                                        sendPushMessage(token, titleText, bodyText);
                                        Fluttertoast.showToast(msg: 'All users have been sent the notification!', gravity: ToastGravity.CENTER);
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                    }
                                  }

                                  username.text = '';
                                  title.text = '';
                                  body.text = '';
                                  _headerController.text = '';
                                  _messageController.text = '';

                                  if(context.mounted)Navigator.of(context).pop();
                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              })));
    }

    _createBottomSheet();
  }

  Future<void> _notifyWardUsers([DocumentSnapshot? documentSnapshot]) async {


    // for (var i = 0; i < numTokens; i++) {
    //   if (documentSnapshot?.id == usersNumbers[i]) {
    //     usersNumbers.removeAt(i);
    //   }
    // }
    print(usersNumbers);
    print(usersNumbers.length);
    print(usersTokens);
    print(usersTokens.length);

    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = documentSnapshot['title'];
      body.text = documentSnapshot['body'];
      _headerController.text = documentSnapshot['title'];
      _messageController.text = documentSnapshot['body'];
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = Future(() async => showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Notify Users on Selected Ward ',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(labelText: 'Message'),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                  if (title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                    if(dropdownValue != 'Select Ward'){

                                      for (int i = 0; i < usersTokens.length; i++) {
                                        final String tokenSelected = usersTokens.first[i];
                                        final String userNumber = usersNumbers[i];
                                        final String notificationTitle = title.text;
                                        final String notificationBody = body.text;
                                        final String notificationDate = formattedDate;
                                        const bool readStatus = false;

                                        final String wardSelected = dropdownValue;

                                        for (var userSnapshot in _allUserPropResults) {
                                          if(dropdownValue == userSnapshot['ward']){
                                            userNameProp = '${userSnapshot['first name']} ${userSnapshot['last name']}';
                                            userAddress = userSnapshot['address'];
                                            userWardProp = userSnapshot['ward'];
                                            userPhoneProp = userSnapshot['cell number'].toString();

                                            if(wardSelected == userWardProp){
                                              await _listNotifications.add({
                                                "token": tokenSelected,
                                                "user": userPhoneProp,
                                                "title": notificationTitle,
                                                "body": notificationBody,
                                                "read": readStatus,
                                                "date": notificationDate,
                                                "level": 'general',
                                              });
                                              ///It can be changed to the firebase notification
                                              String titleText = title.text;
                                              String bodyText = body.text;

                                              ///gets users phone token to send notification to this phone
                                              if (userNumber != "") {
                                                DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                                String token = snap['token'];
                                                print('The phone number is retrieved as ::: $userNumber');
                                                print('The token is retrieved as ::: $token');
                                                sendPushMessage(token, titleText, bodyText);
                                                Fluttertoast.showToast(msg: 'All users on this ward have been notified!', gravity: ToastGravity.CENTER);
                                              }
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      Fluttertoast.showToast(msg: 'Please select the ward receiving the notification first!', gravity: ToastGravity.CENTER);
                                    }
                                  } else {
                                    Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                  }

                                  username.text = '';
                                  title.text = '';
                                  body.text = '';
                                  _headerController.text = '';
                                  _messageController.text = '';
                                  dropdownValue = 'Select Ward';

                                  if(context.mounted)Navigator.of(context).pop();
                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              })));
    }

    _createBottomSheet();
  }

  Future<void> _notifyThisUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = documentSnapshot.id;
      title.text = '';
      body.text = '';
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = Future(() async => showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
              isScrollControlled: true,
              context: context,
              builder: (BuildContext ctx) {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Notify Selected Users',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: title,
                                decoration: const InputDecoration(labelText: 'Message Header'),
                              ),
                            ),
                            Visibility(
                              visible: visShow,
                              child: TextField(
                                controller: body,
                                decoration: const InputDecoration(labelText: 'Message'),
                              ),
                            ),
                            const SizedBox(height: 10,),
                            ElevatedButton(
                                child: const Text('Send Notification'),
                                onPressed: () async {
                                  DateTime now = DateTime.now();
                                  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                  final String tokenSelected = notifyToken;
                                  final String userNumber = userPhoneNumber;
                                  final String notificationTitle = title.text;
                                  final String notificationBody = body.text;
                                  final String notificationDate = formattedDate;
                                  const bool readStatus = false;

                                  if (title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                    await _listNotifications.add({
                                      "token": tokenSelected,
                                      "user": userNumber,
                                      "title": notificationTitle,
                                      "body": notificationBody,
                                      "read": readStatus,
                                      "date": notificationDate,
                                      "level": 'general',
                                    });

                                    ///It can be changed to the firebase notification
                                    String titleText = title.text;
                                    String bodyText = body.text;

                                    ///gets users phone token to send notification to this phone
                                    if (userNumber != "") {
                                      DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                      String token = snap['token'];
                                      print('The phone number is retrieved as ::: $userNumber');
                                      print('The token is retrieved as ::: $token');
                                      sendPushMessage(token, titleText, bodyText);
                                      Fluttertoast.showToast(msg: 'The user has been sent the notification!', gravity: ToastGravity.CENTER);
                                    }
                                  } else {
                                    Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                                  }

                                  username.text = '';
                                  title.text = '';
                                  body.text = '';
                                  _headerController.text = '';
                                  _messageController.text = '';

                                  if(context.mounted)Navigator.of(context).pop();
                                }
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              })));
    }

    _createBottomSheet();
  }

  Future<void> _disconnectThisUser([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      username.text = widget.userNumber;
      title.text = 'Utilities Disconnection Warning';
      body.text = 'Please complete payment of your utilities. Failing to do so will result in utilities on your property being cut off in 14 days!';
    }

    /// on update the only info necessary to change should be meter reading on the bottom modal sheet to only specify that information but let all data stay the same
    void _createBottomSheet() async {
      Future<void> future = Future(() async => showModalBottomSheet(
          context: context,
          builder: await showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext ctx) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 20,
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Notify Users Utilities Disconnection',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Visibility(
                          visible: visShow,
                          child: TextField(
                            controller: title,
                            decoration: const InputDecoration(labelText: 'Message Header'),
                          ),
                        ),
                        Visibility(
                          visible: visShow,
                          child: TextField(
                            controller: body,
                            decoration: const InputDecoration(labelText: 'Message'),
                          ),
                        ),

                        const SizedBox(height: 10,),
                        ElevatedButton(
                            child: const Text('Send Notification'),
                            onPressed: () async {
                              DateTime now = DateTime.now();
                              String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                              final String tokenSelected = notifyToken;
                              final String userNumber = userPhoneNumber;
                              final String notificationTitle = title.text;
                              final String notificationBody = body.text;
                              final String notificationDate = formattedDate;
                              const bool readStatus = false;

                              if (title.text != '' || title.text.isNotEmpty || body.text != '' || body.text.isNotEmpty) {
                                await _listNotifications.add({
                                  "token": tokenSelected,
                                  "user": userNumber,
                                  "title": notificationTitle,
                                  "body": notificationBody,
                                  "read": readStatus,
                                  "date": notificationDate,
                                  "level": 'severe',
                                });

                                ///It can be changed to the firebase notification
                                String titleText = title.text;
                                String bodyText = body.text;

                                ///gets users phone token to send notification to this phone
                                if (userNumber != "") {
                                  DocumentSnapshot snap = await FirebaseFirestore.instance.collection("UserToken").doc(userNumber).get();
                                  print('Snap token $snap');
                                  print('User number $userNumber');
                                  String token = snap['token'];
                                  print('The phone number is retrieved as ::: $userNumber');
                                  print('The token is retrieved as ::: $token');
                                  sendPushMessage(token, titleText, bodyText);
                                  Fluttertoast.showToast(msg: 'The user has been sent the notification!', gravity: ToastGravity.CENTER);
                                }
                              } else {
                                Fluttertoast.showToast(msg: 'Please Fill Header and Message of the notification!', gravity: ToastGravity.CENTER);
                              }

                              username.text = '';
                              title.text = '';
                              body.text = '';
                              _headerController.text = '';
                              _messageController.text = '';

                              if (context.mounted) Navigator.of(context).pop();
                            }
                        )
                      ],
                    ),
                  ),
                );
              },
            );
          })));

    }

    _createBottomSheet();
  }

}
