import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:municipal_track/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_track/code/faultPages/general_fault_screen.dart';

class ReportPropertyMenu extends StatefulWidget {
  const ReportPropertyMenu({Key? key}) : super(key: key);

  @override
  State<ReportPropertyMenu> createState() => _ReportPropertyMenuState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
String userID = uid as String;

class _ReportPropertyMenuState extends State<ReportPropertyMenu> {

  final _electricalFaultController = TextEditingController();
  final _waterFaultController = TextEditingController();

  final String _currentUser = userID;

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  String userPass = '';
  String addressPass = '';
  String accountPass = '';

  bool elecDesVis = true;
  bool waterDesVis = false;
  bool buttonEnabled = true;

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget faultItemField(String propertyDat) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8,),
      child: Row(
        children: [
          const SizedBox(width: 6,),
          Text(
            propertyDat,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewFaultReport() async {

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
                  //Text controllers for the properties db visibility only available for the electric and water readings
                  Visibility(
                    visible: elecDesVis,
                    child: TextField(
                      controller: _electricalFaultController,
                      decoration: const InputDecoration(
                          labelText: 'Electrical Fault Description'),
                    ),
                  ),
                  Visibility(
                    visible: waterDesVis,
                    child: TextField(
                      controller: _waterFaultController,
                      decoration: const InputDecoration(
                          labelText: 'Water Fault Description'),
                    ),
                  ),
                  const SizedBox(height: 20,),
                  ElevatedButton(
                    child: const Text('Report'),
                    onPressed: () async {

                      final String uid = _currentUser;
                      String accountNumber = accountPass;
                      final String addressFault = addressPass;
                      final String electricityFaultDes = _electricalFaultController.text;
                      final String waterFaultDes = _waterFaultController.text;
                      DateTime now = DateTime.now();
                      String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                      if (uid == _currentUser) {
                        await _faultData.add({
                          "uid": uid,
                          "accountNumber": accountNumber,
                          "address": addressFault,
                          "electricityFaultDes": electricityFaultDes,
                          "waterFaultDes": waterFaultDes,
                          "dateReported": formattedDate,
                        });
                      }

                      _electricalFaultController.text ='';
                      _waterFaultController.text='';

                      Fluttertoast.showToast(msg: "Fault has been reported successfully!",
                        gravity: ToastGravity.CENTER,);

                      //Navigator.of(context).pop();
                      Get.back();

                      AlertDialog(
                        shape: const RoundedRectangleBorder(borderRadius:
                        BorderRadius.all(Radius.circular(16))),
                        title: const Text("Call Report Center!"),
                        content: const Text(
                            "Would you like to call the report center after sending your report description?"),
                        actions: [
                          IconButton(
                            onPressed: () {
                              Get.back();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          IconButton(
                            onPressed: () {

                              final Uri _tel = Uri.parse(
                                  'tel:+27${0800001868}');
                              launchUrl(_tel);

                              Navigator.of(context).pop();
                              Get.back();
                            },
                            icon: const Icon(
                              Icons.done,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      );

                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Report Fault'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Card(
            margin: const EdgeInsets.all(10),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedIconButton(
                  onPress: () async {
                    Navigator.push(context,
                        MaterialPageRoute(
                            builder: (context) => GeneralFaultReporting()));
                  },
                  labelText: 'General Fault',
                  fSize: 20,
                  faIcon: const FaIcon(Icons.report_problem),
                  fgColor: Colors.orangeAccent,
                  btSize: const Size(280, 60),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _propList.snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(

                    ///this call is to display all details for all users but is only displaying for the current user account.
                    ///it can be changed to display all users for the staff to see if the role is set to all later on.
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];

                      String billMessage;

                      ///A check for if payment is outstanding or not
                      if (documentSnapshot['eBill'] != '') {
                        billMessage = 'Utilities bill outstanding: '+documentSnapshot['eBill'];
                        buttonEnabled = false;
                      } else {
                        billMessage = 'No outstanding payments';
                        buttonEnabled = true;
                      }

                      ///Check for only user information, this displays only for the users details and not all users in the database.
                      if (streamSnapshot.data!.docs[index]['user id'] == userID) {
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
                                          'Property Information',
                                          style: TextStyle(fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(height: 10,),
                                      Text(
                                        'Account Number: ' + documentSnapshot['account number'],
                                        style: const TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                      Text(
                                        'Street Address: ' + documentSnapshot['address'],
                                        style: const TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                      Text(
                                        'Area Code: ' + documentSnapshot['area code'].toString(),
                                        style: const TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                      Text(
                                        'Property Bill: $billMessage',
                                        style: const TextStyle(fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                      ),

                                      const SizedBox(height: 20,),

                                      ///button visibility only when the current month is selected
                                      Center(
                                        child: ElevatedIconButton(
                                          onPress: buttonEnabled ? () {
                                            userPass = _currentUser;
                                            addressPass = documentSnapshot['address'];
                                            accountPass = documentSnapshot['account number'];
                                            elecDesVis = true;
                                            waterDesVis = false;
                                            _addNewFaultReport();
                                          } : () {
                                            Fluttertoast.showToast(
                                              msg: "Outstanding bill on property, Fault Reporting unavailable!",
                                              gravity: ToastGravity.CENTER,);
                                          },
                                          labelText: 'Report Electrical Fault',
                                          fSize: 20,
                                          faIcon: const FaIcon(
                                              Icons.electric_bolt),
                                          fgColor: Colors.amberAccent,
                                          btSize: const Size(280, 60),
                                        ),
                                      ),

                                      const SizedBox(height: 10,),

                                      ///Report adding button
                                      Center(
                                          child: ElevatedIconButton(
                                            onPress: buttonEnabled ? () {
                                              userPass = _currentUser;
                                              addressPass = documentSnapshot['address'];
                                              accountPass = documentSnapshot['account number'];
                                              elecDesVis = false;
                                              waterDesVis = true;
                                              _addNewFaultReport();
                                            } : () {
                                              Fluttertoast.showToast(
                                                msg: "Outstanding bill on property, Fault Reporting unavailable!",
                                                gravity: ToastGravity.CENTER,);
                                            },
                                            labelText: 'Report Water Fault',
                                            fSize: 20,
                                            faIcon: const FaIcon(
                                                Icons.water_drop),
                                            fgColor: Colors.blue,
                                            btSize: const Size(280, 60),
                                          )
                                      ),

                                      const SizedBox(height: 5,),

                                      // GestureDetector(
                                      //   onTap: () {
                                      //     _delete(documentSnapshot.id);
                                      //   },
                                      //   child: Row(
                                      //     children: [
                                      //       Icon(
                                      //         Icons.delete,
                                      //         color: Colors.red[700],
                                      //       ),
                                      //     ],

                                    ],
                                ),
                            ),
                        );
                      } else {
                        ///a card to display ALL details for users when role is set to admin is in "display_info_all_users.dart"
                        return Card();
                      }
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
          ),
        ],
      ),
    );
  }
}