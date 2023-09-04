import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:municipal_tracker_msunduzi/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_tracker_msunduzi/code/MapTools/map_screen_prop.dart';
import 'package:municipal_tracker_msunduzi/code/faultPages/fault_viewing_screen.dart';
import 'package:path/path.dart' as pathing;
import 'package:url_launcher/url_launcher.dart';
import 'package:municipal_tracker_msunduzi/code/Reusable/icon_elevated_button.dart';

class ReportPropertyMenu extends StatefulWidget {
  const ReportPropertyMenu({Key? key}) : super(key: key);

  @override
  State<ReportPropertyMenu> createState() => _ReportPropertyMenuState();
}


final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String userPhone = phone as String;

DateTime now = DateTime.now();

class _ReportPropertyMenuState extends State<ReportPropertyMenu> {

  final _faultDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _reporterPhoneController = TextEditingController();

  final String _currentUser = userID;

  final CollectionReference _faultData =
  FirebaseFirestore.instance.collection('faultReporting');

  final CollectionReference _deptInfo =
  FirebaseFirestore.instance.collection('departments');

  final CollectionReference _propList =
  FirebaseFirestore.instance.collection('properties');

  String userPass = '';
  String addressPass = '';
  String accountPass = '';
  String phoneNumPass = '';
  String dropdownValue = 'Select Fault Type';

  String reporterCellGiven = '';
  String reporterDateGiven = '';
  String accountNumberRep = '';
  String locationGivenRep = '';
  bool imageVisibility = true;

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;

  TextEditingController nameController = TextEditingController();

  bool buttonEnabled = true;
  String location ='Null, Press Button';
  String Address = 'search';

  @override
  void initState() {
    locationAllow();
    _reporterPhoneController.text = userPhone;
    super.initState();
  }

  ///Form text field decoration style
  InputDecoration formItemDecoration(String hintTextString, Icon iconItem){
    return InputDecoration(
      prefixIcon: iconItem,
      hintText: hintTextString,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
              30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )
      ),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
              30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
              30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )
      ),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
              30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6
      ),
      fillColor: Colors.white,
      filled: true,
    );
  }

  Future<Widget> _getImage(BuildContext context, String imageName) async{
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);
    image =Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Report Fault'),
          backgroundColor: Colors.green,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Public Fault'),
              Tab(text: 'Property Fault'),
              Tab(text: 'Current Faults'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ///Tab for public fault reporting
            SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    // height: 500,
                    child: Card(
                      margin: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20,),
                          const Center(
                            child: Text(
                              'Report Public Fault',
                              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 15.0),
                            child: Column(
                                children: [
                                  SizedBox(
                                    width: 400,
                                    height: 50,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 10, right: 10),
                                      child: Center(
                                        child: TextField(
                                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )
                                            ),
                                            disabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                    30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 6
                                            ),
                                            fillColor: Colors.white,
                                            filled: true,
                                            suffixIcon: DropdownButtonFormField <String>(
                                              value: dropdownValue,
                                              items: <String>['Select Fault Type', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                                                  .map<DropdownMenuItem<String>>((String value) {
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
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  dropdownValue = newValue!;
                                                  _addressController.text = Address;
                                                  if(dropdownValue == 'Select Fault Type'){
                                                    _addressController.text = '';
                                                  }
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
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
                            child: TextFormField(
                              controller: _faultDescriptionController,
                              validator: (val) =>
                              val == ""
                                  ? "Please describe the fault"
                                  : null,
                              decoration: formItemDecoration("Fault Description...", const Icon(
                                Icons.note_alt_outlined,
                                color: Colors.black87,),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
                            child: TextFormField(
                              controller: _addressController,
                              validator: (val) =>
                              val == ""
                                  ? "Please enter an Address"
                                  : null,
                              decoration: formItemDecoration("Address...", const Icon(
                                Icons.location_on_sharp,
                                color: Colors.black87,),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25.0),
                            child: TextFormField(
                              controller: _reporterPhoneController,
                              validator: (val) =>
                              val == ""
                                  ? "Enter reporters contact number"
                                  : null,
                              decoration: formItemDecoration("Reporter Phone Number...", const Icon(
                                Icons.phone_in_talk,
                                color: Colors.black87,),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20,),
                          Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 50.0),
                                child: Text(
                                  'Add Photo?',
                                  style: TextStyle(fontSize: 16, ),//fontWeight: FontWeight.w700),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                child: GestureDetector(
                                  onTap: () {
                                    _showPicker(context);
                                  },
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[400],
                                    child: _photo != null ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _photo!, width: 60, height: 60, fit: BoxFit.cover,),
                                    )
                                        : Container(decoration: BoxDecoration(color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(10)), width: 60, height: 60, child: Icon(Icons.camera_alt, color: Colors.grey[800],),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20,),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30.0),
                            child:
                            BasicIconButtonGreen(
                              onPress: buttonEnabled? () {
                                if (_photo != null) {
                                  if(dropdownValue !='Select Fault Type' && _addressController.text.isNotEmpty && _faultDescriptionController.text.isNotEmpty && _reporterPhoneController.text.isNotEmpty){
                                    if(_reporterPhoneController.text.contains('+27')){
                                      uploadFaultFile();
                                      Fluttertoast.showToast(msg: "Fault has been Reported with Image!", gravity: ToastGravity.CENTER);
                                      navigator?.pop();
                                    } else {
                                      Fluttertoast.showToast(msg: "Contact number must have +27 country code!", gravity: ToastGravity.CENTER);
                                    }
                                  } else {
                                    Fluttertoast.showToast(msg: "Please fill all fields to report!", gravity: ToastGravity.CENTER);
                                  }
                                } else if (_photo == null) {
                                  if(dropdownValue !='Select Fault Type' && _addressController.text.isNotEmpty && _faultDescriptionController.text.isNotEmpty && _reporterPhoneController.text.isNotEmpty) {
                                    showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) {
                                          return
                                            AlertDialog(
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.all(
                                                      Radius.circular(16))),
                                              title: const Text("Report Fault Without Image!"),
                                              content: const Text("Reporting a fault without a photo is possible. A photo can be added later on if necessary,\n\nare you sure you want to leave out a photo?"),
                                              actions: [
                                                IconButton(
                                                  onPressed: () {
                                                    Fluttertoast.showToast(
                                                        msg: "Please tap on the image area and select the image to upload!",
                                                        gravity: ToastGravity.CENTER);
                                                    Navigator.of(context).pop();
                                                  },
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    if (dropdownValue != 'Select Fault Type' && _addressController.text.isNotEmpty && _faultDescriptionController.text.isNotEmpty && _reporterPhoneController.text.isNotEmpty) {
                                                      if (_reporterPhoneController.text.contains('+27')) {
                                                        uploadFault();
                                                        Fluttertoast.showToast(
                                                            msg: "Fault has been Reported!",
                                                            gravity: ToastGravity.CENTER);
                                                        Navigator.of(context).pop();
                                                      } else {
                                                        Fluttertoast.showToast(
                                                            msg: "Contact number must have +27 country code!",
                                                            gravity: ToastGravity.CENTER);
                                                      }
                                                    } else {
                                                      Fluttertoast.showToast(
                                                          msg: "Please fill all fields to report!",
                                                          gravity: ToastGravity.CENTER);
                                                    }
                                                    if (_reporterPhoneController.text.contains('+27')) {

                                                    } else {
                                                      Fluttertoast.showToast(
                                                          msg: "Contact number must have +27 country code!",
                                                          gravity: ToastGravity.CENTER);
                                                    }
                                                  },
                                                  icon: const Icon(
                                                    Icons.done,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            );
                                        });
                                  } else {
                                    Fluttertoast.showToast(msg: "Please fill all fields to report!", gravity: ToastGravity.CENTER);
                                  }
                                } else {
                                  Fluttertoast.showToast(msg: "Please fill all fields to report!", gravity: ToastGravity.CENTER);
                                }
                              } : (){
                                Fluttertoast.showToast(msg: "Please allow location access!", gravity: ToastGravity.CENTER);
                              },
                              labelText: 'Report Fault',
                              fSize: 20,
                              faIcon: const FaIcon(Icons.report),
                              fgColor: Colors.orangeAccent,
                              btSize: const Size(500, 60),
                            ),
                          ),
                          const SizedBox(height: 10,),

                          // Padding(
                          //   padding: const EdgeInsets.only(left: 10),
                          //   child: Row(
                          //     children: [
                          ///button for calling municipality report center
                          //       ElevatedIconButton(
                          //         onPress: () {
                          //           showDialog(
                          //               barrierDismissible: false,
                          //               context: context,
                          //               builder: (context) {
                          //                 return
                          //                   AlertDialog(
                          //                     shape: const RoundedRectangleBorder(
                          //                         borderRadius:
                          //                         BorderRadius.all(Radius.circular(16))),
                          //                     title: const Text("Call Report Center!"),
                          //                     content: const Text(
                          //                         "Would you like to call the report center directly?"),
                          //                     actions: [
                          //                       IconButton(
                          //                         onPressed: () {
                          //                           Navigator.of(context).pop();
                          //                         },
                          //                         icon: const Icon(
                          //                           Icons.cancel,
                          //                           color: Colors.red,
                          //                         ),
                          //                       ),
                          //                       IconButton(
                          //                         onPressed: () {
                          //                           final Uri _tel = Uri.parse(
                          //                               'tel:+27${0800001868}');
                          //                           launchUrl(_tel);
                          //
                          //                           Navigator.of(context).pop();
                          //                           Get.back();
                          //                         },
                          //                         icon: const Icon(
                          //                           Icons.done,
                          //                           color: Colors.green,
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   );
                          //               });
                          //         },
                          //         labelText: 'Call Center',
                          //         fSize: 16,
                          //         faIcon: const FaIcon(Icons.phone),
                          //         fgColor: Colors.orangeAccent,
                          //         btSize: const Size(50, 50),
                          //       ),
                          //
                          //     ],
                          //   ),
                          // ),

                          const SizedBox(height: 20,),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            ///TAB for property fault report view
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
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
                          billMessage = documentSnapshot['eBill'];
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
                                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(height: 20,),
                                  Text(
                                    'Account Number: ${documentSnapshot['account number']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                  Text(
                                    'Street Address: ${documentSnapshot['address']}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                  Text(
                                    'Area Code: ${documentSnapshot['area code'].toString()}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 5,),
                                  Text(
                                    'Property Bill: $billMessage',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 10,),
                                  ///Report adding button
                                  Center(
                                      child: BasicIconButtonGreen(
                                        onPress: buttonEnabled ? () {
                                          userPass = _currentUser;
                                          addressPass = documentSnapshot['address'];
                                          accountPass = documentSnapshot['account number'];
                                          phoneNumPass = documentSnapshot['cell number'];

                                          _addNewFaultReport();
                                        } : () {
                                          Fluttertoast.showToast(msg: "Outstanding bill on property, Fault Reporting unavailable!",
                                            gravity: ToastGravity.CENTER,);
                                        },
                                        labelText: 'Report Property Fault',
                                        fSize: 16,
                                        faIcon: const FaIcon(Icons.report),
                                        fgColor: Colors.orangeAccent,
                                        btSize: const Size(200, 50),
                                      )
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          ///a card to display ALL details for users when role is set to admin is in "display_info_all_users.dart"
                          return const Card();
                        }
                      },
                    );
                  }
                  return const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),

            ///TAB for viewing all current reports ordered latest to oldest and not completed
            StreamBuilder<QuerySnapshot>(
              stream: _faultData.orderBy('dateReported', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  return ListView.builder(
                    itemCount: streamSnapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documentSnapshot =
                      streamSnapshot.data!.docs[index];
                      String status;
                      if(documentSnapshot['faultResolved'] == false){
                        status = "Pending";
                      } else {
                        status = "Completed";
                      }
                      if(streamSnapshot.data!.docs[index]['faultResolved'] == false && streamSnapshot.data!.docs[index]['reporterContact'] == phone){
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
                                    'Fault Information',
                                    style: TextStyle(
                                        fontSize: 19, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(height: 10,),
                                Column(
                                  children: [
                                    if(status != "")...[
                                      Text(
                                        'Reporter Account Number: ${documentSnapshot['accountNumber']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Text(
                                  'Street Address of Fault: ${documentSnapshot['address']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Fault Type: ${documentSnapshot['faultType']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Column(
                                  children: [
                                    if(documentSnapshot['faultDescription'] != "")...[
                                      Text(
                                        'Fault Description: ${documentSnapshot['faultDescription']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Column(
                                  children: [
                                    if(documentSnapshot['depComment1'] != "")...[
                                      Text(
                                        'Department Comment 1: ${documentSnapshot['depComment1']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Column(
                                  children: [
                                    if(documentSnapshot['handlerCom1'] != "")...[
                                      Text(
                                        'Handler Comment: ${documentSnapshot['handlerCom1']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Column(
                                  children: [
                                    if(documentSnapshot['depComment2'] != "")...[
                                      Text(
                                        'Department Comment: ${documentSnapshot['depComment2']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Column(
                                  children: [
                                    if(documentSnapshot['handlerCom2'] != "")...[
                                      Text(
                                        'Handler Final Comment: ${documentSnapshot['handlerCom2']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Column(
                                  children: [
                                    if(documentSnapshot['depComment3'] != "")...[
                                      Text(
                                        'Department Final Comment: ${documentSnapshot['depComment3']}',
                                        style: const TextStyle(
                                            fontSize: 16, fontWeight: FontWeight.w400),
                                      ),
                                      const SizedBox(height: 5,),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                Text(
                                  'Resolve State: $status',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Text(
                                  'Date of Fault Report: ${documentSnapshot['dateReported']}',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w400),
                                ),
                                const SizedBox(height: 5,),
                                Column(
                                  children: [
                                    if(documentSnapshot['faultDescription'] != "")...[
                                      Visibility(
                                        visible: imageVisibility,
                                        child: InkWell(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 5),
                                            // height: 180,
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
                                                      ///Firebase image location must be changed to display image based on the address
                                                        context, 'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
                                                    builder: (context, snapshot) {
                                                      if (snapshot.hasError) {
                                                        return const Padding(
                                                          padding: EdgeInsets.all(20.0),
                                                          child: Text('Image not uploaded for Fault.',),
                                                        ); //${snapshot.error} if error needs to be displayed instead
                                                      }
                                                      if (snapshot.connectionState ==
                                                          ConnectionState.done) {
                                                        return SizedBox(
                                                          height: 180,
                                                          child: snapshot.data,
                                                        );
                                                      }
                                                      if (snapshot.connectionState ==
                                                          ConnectionState.waiting) {
                                                        return Container(
                                                          child: const CircularProgressIndicator(),);
                                                      }
                                                      return Container();
                                                    }
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[

                                    ],
                                  ],
                                ),
                                const SizedBox(height: 0,),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          BasicIconButtonGreen(
                                            onPress: () {
                                              accountNumberRep = documentSnapshot['accountNumber'];
                                              locationGivenRep = documentSnapshot['address'];

                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (context) => MapScreenProp(propAddress: locationGivenRep, propAccNumber: accountNumberRep,)
                                                    //MapPage()
                                                  ));
                                            },
                                            labelText: 'Location',
                                            fSize: 15,
                                            faIcon: const FaIcon(Icons.map),
                                            fgColor: Colors.purple,
                                            btSize: const Size(50, 50),
                                          ),
                                          BasicIconButtonGreen(
                                            onPress: () {
                                              locationGivenRep = documentSnapshot['address'];
                                              reporterDateGiven = documentSnapshot['dateReported'];
                                              Navigator.push(context,
                                                  MaterialPageRoute(
                                                      builder: (context) => FaultImageUpload(propertyAddress: locationGivenRep, reportedDate: reporterDateGiven)
                                                    //MapPage()
                                                  ));
                                            },
                                            labelText: 'Image +',
                                            fSize: 15,
                                            faIcon: const FaIcon(Icons.photo_camera),
                                            fgColor: Colors.blueGrey,
                                            btSize: const Size(50, 50),
                                          ),
                                        ],
                                      ),

                                      ///Button for staff to use in calling the user that reported this fault, not needed here
                                      // ElevatedButton(
                                      //   onPressed: () {
                                      //     showDialog(
                                      //         barrierDismissible: false,
                                      //         context: context,
                                      //         builder: (context) {
                                      //           return
                                      //             AlertDialog(
                                      //               shape: const RoundedRectangleBorder(
                                      //                   borderRadius:
                                      //                   BorderRadius.all(Radius.circular(16))),
                                      //               title: const Text("Call Reporter!"),
                                      //               content: const Text(
                                      //                   "Would you like to call the individual who logged the fault?"),
                                      //               actions: [
                                      //                 IconButton(
                                      //                   onPressed: () {
                                      //                     Navigator.of(context).pop();
                                      //                   },
                                      //                   icon: const Icon(
                                      //                     Icons.cancel,
                                      //                     color: Colors.red,
                                      //                   ),
                                      //                 ),
                                      //                 IconButton(
                                      //                   onPressed: () {
                                      //                     reporterCellGiven = documentSnapshot['reporterContact'];
                                      //
                                      //                     final Uri _tel = Uri.parse('tel:${reporterCellGiven.toString()}');
                                      //                     launchUrl(_tel);
                                      //
                                      //                     Navigator.of(context).pop();
                                      //                   },
                                      //                   icon: const Icon(
                                      //                     Icons.done,
                                      //                     color: Colors.green,
                                      //                   ),
                                      //                 ),
                                      //               ],
                                      //             );
                                      //         });
                                      //   },
                                      //   style: ElevatedButton.styleFrom(
                                      //     backgroundColor: Colors.grey[350],
                                      //     fixedSize: const Size(150, 10),),
                                      //   child: Row(
                                      //     children: [
                                      //       Icon(
                                      //         Icons.call,
                                      //         color: Colors.orange[700],
                                      //       ),
                                      //       const SizedBox(width: 2,),
                                      //       const Text('Call Reporter', style: TextStyle(
                                      //         fontWeight: FontWeight.w600,
                                      //         color: Colors.black,),),
                                      //     ],
                                      //   ),
                                      // ),
                                      // const SizedBox(width: 5,),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      else {
                        return const Card();
                      }
                    },
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: Card(
                      margin: EdgeInsets.all(10),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No Faults Reported',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),                      ),
                      ),
                    ),
                  ),);
              },
            ),
          ],
        ),
      ),
    );
  }

  ///All code bellow for geolocation and adding fault with and without an image
  Future<void> locationAllow() async {
    Position position = await _getGeoLocationPosition();
    location ='Lat: ${position.latitude} , Long: ${position.longitude}';
    GetAddressFromLatLong(position);
    if(_getGeoLocationPosition.isBlank == false){
      buttonEnabled = true;
    }
  }
  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {

        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
  Future<void> GetAddressFromLatLong(Position position)async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    Address = '${place.street} ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  //Used to set the _photo file as image from gallery
  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }
  //Used to set the _photo file as image from gallery
  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60,);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  showImage(String image){
    return Image.memory(base64Decode(image));
  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Gallery'),
                      onTap: () {
                        imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Camera'),
                    onTap: () {
                      imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  ///Upload fault with an image file included
  Future uploadFaultFile() async {
    if (_photo == null) return;

    final fileName = pathing.basename(_photo!.path);

    File? imageFile = _photo;
    List<int> imageBytes = imageFile!.readAsBytesSync();
    String imageData = base64Encode(imageBytes);

    final String photoName;

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    final destination = 'files/faultImages/$formattedDate';

    String addressFault = _addressController.text;

    if(_addressController.text.isEmpty){
      addressFault = Address;
    }

    final String faultDescription = _faultDescriptionController.text;

    if (_currentUser != null) {
      await _faultData.add({
        "uid": _currentUser,
        "accountNumber": '',
        "address": addressFault,
        "faultType": dropdownValue,
        "reporterContact": userPhone,
        "deptHandler": '',
        "depComment1": '',
        "depComment2": '',
        "depComment3": '',
        "handlerCom1": '',
        "handlerCom2": '',
        "faultDescription": faultDescription,
        "depAllocated": '',
        "faultResolved": false,
        "dateReported": formattedDate,
        "faultStage": 1,
      });

      try {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref(destination)
            .child('$addressFault/');   ///this is the jpg filename which needs to be named something on the db in order to display in the display screen
        await ref.putFile(_photo!);
        photoName = _photo!.toString();
        print(destination);
      } catch (e) {
        print('error occured');
      }

      _addressController.text = '';
      _faultDescriptionController.text = '';
      setState(() {
        dropdownValue = 'Select Fault Type';
      });

    } else {
      Fluttertoast.showToast(msg: "Connection failed. Fix network!",
          gravity: ToastGravity.CENTER);
    }
  }
  ///Upload fault without an image file included and an image may be added later on
  Future uploadFault() async {

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    final String addressFault = Address;
    final String faultDescription = _faultDescriptionController.text;

    if (_currentUser != null) {
      await _faultData.add({
        "uid": _currentUser,
        "accountNumber": '',
        "address": addressFault,
        "faultType": dropdownValue,
        "reporterContact": userPhone,
        "deptHandler": '',
        "depComment1": '',
        "depComment2": '',
        "depComment3": '',
        "handlerCom1": '',
        "handlerCom2": '',
        "faultDescription": faultDescription,
        "depAllocated": '',
        "faultResolved": false,
        "dateReported": formattedDate,
        "faultStage": 1,
      });

      _addressController.text = '';
      _faultDescriptionController.text = '';
      setState(() {
        dropdownValue = 'Select Fault Type';
      });

    } else {
      Fluttertoast.showToast(msg: "Connection failed. Fix network!",
          gravity: ToastGravity.CENTER);
    }
  }

  ///Modal for adding fault report to property since address and details not needed,
  ///a check is also made beforehand if the property has outstanding bill and blocks unpaid bill property fault reporting
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
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField <String>(
                    value: dropdownValue,
                    items: <String>['Select Fault Type', 'Electricity', 'Water & Sanitation', 'Roadworks', 'Waste Management']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                  ),
                  TextField(
                    controller: _faultDescriptionController,
                    decoration: const InputDecoration(
                        labelText: 'Fault Description'),
                  ),
                  const SizedBox(height: 20,),
                  Center(
                    child: Row(
                      children: [
                        ElevatedButton(
                          child: const Text('Report'),
                          onPressed: () async {
                            showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (context) {
                                  return
                                    AlertDialog(
                                      shape: const RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.all(
                                              Radius.circular(
                                                  16))),
                                      title: const Text(
                                          "Submit Fault"),
                                      content: const Text(
                                          "To add a photo to your property fault report go to your Current Reports tab to upload or update your fault image."),
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
                                          onPressed: () async {
                                            DateTime now = DateTime.now();
                                            String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

                                            final String uid = _currentUser;
                                            String accountNumber = accountPass;
                                            final String addressFault = addressPass;
                                            final String faultDescription = _faultDescriptionController.text;
                                            String faultType = dropdownValue;

                                            if (faultType != 'Select Fault Type') {
                                              if (faultDescription != '') {
                                                if (uid == _currentUser) {
                                                  await _faultData.add({
                                                    "uid": uid,
                                                    "accountNumber": accountNumber,
                                                    "address": addressFault,
                                                    "reporterContact": userPhone,
                                                    "deptHandler": '',
                                                    "depComment1": '',
                                                    "depComment2": '',
                                                    "depComment3": '',
                                                    "handlerCom1": '',
                                                    "handlerCom2": '',
                                                    "faultType": faultType,
                                                    "faultDescription": faultDescription,
                                                    "dateReported": formattedDate,
                                                    "depAllocated": '',
                                                    "faultResolved": false,
                                                    "faultStage": 1,
                                                  });
                                                }
                                                _addressController.text = '';
                                                _faultDescriptionController.text = '';
                                                dropdownValue = 'Select Fault Type';

                                                Fluttertoast.showToast(
                                                  msg: "Fault has been reported successfully!",
                                                  gravity: ToastGravity.CENTER,);

                                                if(context.mounted)Navigator.of(context).pop();
                                                Get.back();
                                              } else {
                                                Fluttertoast.showToast(
                                                  msg: "Please Give A Fault Description!",
                                                  gravity: ToastGravity.CENTER,);
                                              }
                                            } else {
                                              Fluttertoast.showToast(
                                                msg: "Please Select Fault Type being Reported!!",
                                                gravity: ToastGravity.CENTER,);
                                            }
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
