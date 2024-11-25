import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as pathing;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'package:municipal_services/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/faultPages/fault_viewing_screen.dart';
import 'package:municipal_services/code/MapTools/address_search.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/location_search_dialogue.dart';
import 'package:municipal_services/code/MapTools/place_service.dart';
import 'package:provider/provider.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';

class WaterSanitationReportMenu extends StatefulWidget {
  final Property currentProperty;
  final bool isLocalMunicipality;
  final String municipalityId;
  final String? districtId;

  const WaterSanitationReportMenu({
    super.key,
    required this.currentProperty,
    required this.isLocalMunicipality,
    required this.municipalityId,
    this.districtId,
  });

  @override
  State<WaterSanitationReportMenu> createState() => _WaterSanitationReportMenuState();
}
class _WaterSanitationReportMenuState extends State<WaterSanitationReportMenu> {
  final _faultDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _reporterPhoneController = TextEditingController();
  late final CollectionReference _faultData;
  late final CollectionReference _deptInfo;
  late final CollectionReference _propList;
  String districtId = '';
  String municipalityId = '';
  String userPass = '';
  String addressPass = '';
  String accountPass = '';
  String phoneNumPass = '';
  String dropdownValue = 'Select Fault Type';
  late String billMessage;
  String reporterCellGiven = '';
  String reporterDateGiven = '';
  String accountNumberRep = '';
  String locationGivenRep = '';
  bool imageVisibility = true;
  bool addressExists = false;

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;

  TextEditingController nameController = TextEditingController();

  bool buttonEnabled = true;
  String location = 'Null, Press Button';
  String Address = '';
  DocumentSnapshot? propertyDocument;
  bool isLoading = true;
  bool isAddressLoading = true;
  final String _currentUser = userID;
  String faultDescriptionValue = "Select Fault Description";
  List<String> waterSanitationIssues = [
    'Select Fault Description',
    'Leakage',
    'Burst pipe',
    'Clogged storm drains/pipes',
    'No water'
  ];

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    locationAllow();
    _reporterPhoneController.text = userPhone;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    final currentProperty =
        Provider.of<PropertyProvider>(context, listen: false).selectedProperty;
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userPhoneNumber = user.phoneNumber!;
        String? accountNumber = currentProperty?.accountNo;

        // Print statements to debug
        print('User Phone Number: $userPhoneNumber');
        print('Account Number: $accountNumber');

        QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('cellNumber', isEqualTo: userPhoneNumber)
            .where('accountNumber', isEqualTo: accountNumber)
            .limit(1)
            .get();

        if (propertySnapshot.docs.isNotEmpty) {
          if(mounted) {
            setState(() {
              propertyDocument = propertySnapshot.docs.first;
              isLoading = false;
              addressPass = currentProperty?.address ?? '';
              accountPass = currentProperty?.accountNo ?? '';
            });
          }
          // Determine Firestore path based on whether the property belongs to a local municipality or district
          if (widget.isLocalMunicipality) {
            // Local Municipality Path
            _faultData = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(widget.municipalityId)
                .collection('faultReporting');

            _deptInfo = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(widget.municipalityId)
                .collection('departments');

            _propList = FirebaseFirestore.instance
                .collection('localMunicipalities')
                .doc(widget.municipalityId)
                .collection('properties');
          } else {
            // District Municipality Path
            _faultData = FirebaseFirestore.instance
                .collection('districts')
                .doc(widget.districtId)
                .collection('municipalities')
                .doc(widget.municipalityId)
                .collection('faultReporting');

            _deptInfo = FirebaseFirestore.instance
                .collection('districts')
                .doc(widget.districtId)
                .collection('municipalities')
                .doc(widget.municipalityId)
                .collection('departments');

            _propList = FirebaseFirestore.instance
                .collection('districts')
                .doc(widget.districtId)
                .collection('municipalities')
                .doc(widget.municipalityId)
                .collection('properties');
          }
        } else {
          print('No matching property found for the user.');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
      if(mounted) {
        setState(() {
          isLoading = false; // Handle the error state appropriately
        });
      }
    }
  }
  /// Form text field decoration style
  InputDecoration formItemDecoration(String hintTextString, Icon iconItem) {
    return InputDecoration(
      prefixIcon: iconItem,
      hintText: hintTextString,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(
            color: Colors.grey,
          )),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      fillColor: Colors.white,
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(builder: (locationController) {
      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.grey[350],
          appBar: AppBar(
            title: const Text(
              'Report Water & Sanitation Fault',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(
                  text: 'Public Fault',
                  icon: FaIcon(Icons.location_city_rounded),
                ),
                Tab(
                  text: 'Property Fault',
                  icon: FaIcon(Icons.house_rounded),
                ),
                Tab(
                  text: 'Current Faults',
                  icon: FaIcon(Icons.bar_chart),
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Report Public Fault',
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: DropdownButtonFormField<String>(
                                value: faultDescriptionValue,
                                isExpanded: true,
                                items: waterSanitationIssues.map<DropdownMenuItem<String>>((String issue) {
                                  return DropdownMenuItem<String>(
                                    value: issue,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(issue, style: const TextStyle(fontSize: 16)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    faultDescriptionValue = newValue!;
                                    _faultDescriptionController.text =
                                    faultDescriptionValue == 'Select Fault Description' ? '' : faultDescriptionValue;
                                  });
                                },
                                decoration: formItemDecoration(
                                  'Select Fault Description',
                                  const Icon(Icons.warning_amber_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextFormField(
                                controller: _addressController,
                                validator: (val) => val == "" ? "Please enter an Address" : null,
                                decoration: formItemDecoration(
                                  "Address...",
                                  const Icon(Icons.location_on_sharp, color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextFormField(
                                controller: _reporterPhoneController,
                                validator: (val) => val == "" ? "Enter reporter's contact number" : null,
                                decoration: formItemDecoration(
                                  "Reporter Phone Number...",
                                  const Icon(Icons.phone_in_talk, color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 50.0),
                                  child: Text(
                                    'Add Photo?',
                                    style: TextStyle(fontSize: 16),
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
                                      child: _photo != null
                                          ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _photo!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                          : Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(10)),
                                        width: 60,
                                        height: 60,
                                        child: Icon(
                                          Icons.camera_alt,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                                child: BasicIconButtonGreen(
                                  onPress: buttonEnabled && !isAddressLoading
                                      ? () async {
                                    // Validate form fields
                                    if (_addressController.text.isEmpty) {
                                      Fluttertoast.showToast(
                                        msg: "Please enter an address.",
                                        gravity: ToastGravity.CENTER,
                                      );
                                      return;
                                    }
                                    if (_faultDescriptionController.text.isEmpty) {
                                      Fluttertoast.showToast(
                                        msg: "Please provide a fault description.",
                                        gravity: ToastGravity.CENTER,
                                      );
                                      return;
                                    }
                                    if (_reporterPhoneController.text.isEmpty ||
                                        !_reporterPhoneController.text.startsWith("+27")) {
                                      Fluttertoast.showToast(
                                        msg: "Please enter a valid phone number with +27 country code.",
                                        gravity: ToastGravity.CENTER,
                                      );
                                      return;
                                    }

                                    // Check if photo is attached
                                    if (_photo != null) {
                                      await verifyAddress();
                                      if (addressExists) {
                                        await uploadFaultFile();
                                        Fluttertoast.showToast(
                                          msg: "Fault has been reported successfully with an image!",
                                          gravity: ToastGravity.CENTER,
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        Fluttertoast.showToast(
                                          msg: "Please input a valid address.",
                                          gravity: ToastGravity.CENTER,
                                        );
                                      }
                                    } else {
                                      // If no photo is attached, confirm reporting without an image
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(16))),
                                            title: const Text("Report Fault Without Image"),
                                            content: const Text(
                                                "Reporting a fault without a photo is possible. You can add a photo later."),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green),
                                                onPressed: () async {
                                                  await verifyAddress();
                                                  if (addressExists) {
                                                    await uploadFault();
                                                    Fluttertoast.showToast(
                                                      msg: "Fault has been reported successfully!",
                                                      gravity: ToastGravity.CENTER,
                                                    );
                                                    Navigator.of(context).pop(); // Close confirmation
                                                    Navigator.pop(context); // Close fault dialog
                                                  } else {
                                                    Fluttertoast.showToast(
                                                      msg: "Please input a valid address.",
                                                      gravity: ToastGravity.CENTER,
                                                    );
                                                  }
                                                },
                                                child: const Text("Submit",style: TextStyle(color: Colors.white),),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  }
                                      : () {
                                    Fluttertoast.showToast(
                                      msg: "Please wait until the address is loaded.",
                                      gravity: ToastGravity.CENTER,
                                    );
                                  },
                                  labelText: 'Report Fault',
                                  fSize: 20,
                                  faIcon: const FaIcon(Icons.report),
                                  fgColor: Colors.orangeAccent,
                                  btSize: const Size(300, 40),
                                ),
                              ),
                            ),


                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              propertyDocument != null
                  ? Card(
                margin: const EdgeInsets.only(
                    left: 10, right: 10, top: 10, bottom: 0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Property Information',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Account Number: ${propertyDocument!['accountNumber']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Street Address: ${propertyDocument!['address']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Area Code: ${propertyDocument!['areaCode'].toString()}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Property Bill: ${propertyDocument!['eBill']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: BasicIconButtonGreen(
                          onPress: () {
                            _addNewFaultReport(); // Your fault reporting logic
                          },
                          labelText: 'Report Property Fault',
                          fSize: 16,
                          faIcon: const FaIcon(Icons.report),
                          fgColor: Colors.orangeAccent,
                          btSize: const Size(150, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : const Center(child: CircularProgressIndicator()),
              Column(
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: _faultData != null
                          ? StreamBuilder<QuerySnapshot>(
                        stream: _faultData
                            .orderBy('dateReported', descending: true)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<QuerySnapshot>
                            streamSnapshot) {
                          if (streamSnapshot.hasData) {
                            return ListView.builder(
                              itemCount:
                              streamSnapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                final DocumentSnapshot
                                documentSnapshot =
                                streamSnapshot.data!.docs[index];
                                String status;
                                if (documentSnapshot['faultResolved'] ==
                                    false) {
                                  status = "Pending";
                                } else {
                                  status = "Completed";
                                }
                                if (streamSnapshot.data!.docs[index]
                                ['faultResolved'] ==
                                    false &&
                                    streamSnapshot.data!.docs[index]
                                    ['reporterContact'] ==
                                        userPhone) {
                                  return Card(
                                    margin: const EdgeInsets.only(
                                        left: 10,
                                        right: 10,
                                        top: 10,
                                        bottom: 5),
                                    child: Padding(
                                      padding:
                                      const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Center(
                                            child: Text(
                                              'Fault Information',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight:
                                                  FontWeight.w700),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            'Reference Number: ${documentSnapshot['ref']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w400),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Column(
                                            children: [
                                              if (documentSnapshot[
                                              'accountNumber'] !=
                                                  "") ...[
                                                Text(
                                                  'Reporter Account Number: ${documentSnapshot['accountNumber']}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w400),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else
                                                ...[],
                                            ],
                                          ),
                                          Text(
                                            'Street Address of Fault: ${documentSnapshot['address']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w400),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            'Date of Fault Report: ${documentSnapshot['dateReported']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w400),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Column(
                                            children: [
                                              if (documentSnapshot[
                                              'faultStage'] ==
                                                  1) ...[
                                                Text(
                                                  'Fault Stage: ${documentSnapshot['faultStage'].toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color: Colors
                                                          .deepOrange),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else if (documentSnapshot[
                                              'faultStage'] ==
                                                  2) ...[
                                                Text(
                                                  'Fault Stage: ${documentSnapshot['faultStage'].toString()}',
                                                  style:
                                                  const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color: Colors
                                                          .orange),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else if (documentSnapshot[
                                              'faultStage'] ==
                                                  3) ...[
                                                Text(
                                                  'Fault Stage: ${documentSnapshot['faultStage'].toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color: Colors
                                                          .orangeAccent),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else if (documentSnapshot[
                                              'faultStage'] ==
                                                  4) ...[
                                                Text(
                                                  'Fault Stage: ${documentSnapshot['faultStage'].toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color: Colors
                                                          .lightGreen),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else if (documentSnapshot[
                                              'faultStage'] ==
                                                  5) ...[
                                                Text(
                                                  'Fault Stage: ${documentSnapshot['faultStage'].toString()}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w500,
                                                      color: Colors
                                                          .lightGreen),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else
                                                ...[],
                                            ],
                                          ),
                                          Text(
                                            'Fault Type: ${documentSnapshot['faultType']}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w400),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Column(
                                            children: [
                                              if (documentSnapshot[
                                              'faultDescription'] !=
                                                  "") ...[
                                                Text(
                                                  'Fault Description: ${documentSnapshot['faultDescription']}',
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .w400),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                              ] else
                                                ...[],
                                            ],
                                          ),
                                          Text(
                                            'Resolve State: $status',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                FontWeight.w400),
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Center(
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                              children: [
                                                BasicIconButtonGreen(
                                                  onPress: () {
                                                    accountNumberRep =
                                                    documentSnapshot[
                                                    'accountNumber'];
                                                    locationGivenRep =
                                                    documentSnapshot[
                                                    'address'];

                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (context) =>
                                                            MapScreenProp(
                                                              propAddress:
                                                              locationGivenRep,
                                                              propAccNumber:
                                                              accountNumberRep,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  labelText: 'Location',
                                                  fSize: 14,
                                                  faIcon: const FaIcon(
                                                      Icons.map),
                                                  fgColor:
                                                  Colors.purple,
                                                  btSize: const Size(
                                                      40, 40),
                                                ),
                                                Expanded(
                                                  child: BasicIconButtonGreen(
                                                    onPress: () {
                                                      locationGivenRep =
                                                      documentSnapshot[
                                                      'address'];
                                                      reporterDateGiven =
                                                      documentSnapshot[
                                                      'dateReported'];
                                                      String? districtId =
                                                          widget
                                                              .currentProperty
                                                              .districtId;
                                                      String
                                                      municipalityId =
                                                          widget
                                                              .currentProperty
                                                              .municipalityId;
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (context) =>
                                                              FaultImageUpload(
                                                                propertyAddress:
                                                                locationGivenRep,
                                                                reportedDate:
                                                                reporterDateGiven,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    labelText: 'Image +',
                                                    fSize: 14,
                                                    faIcon: const FaIcon(
                                                        Icons
                                                            .photo_camera),
                                                    fgColor:
                                                    Colors.blueGrey,
                                                    btSize: const Size(
                                                        40, 40),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return const SizedBox();
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
                                      'No Faults Reported Yet',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> locationAllow() async {
    setState(() {
      isAddressLoading = true; // Set to true while fetching location
    });

    Position position = await _getGeoLocationPosition();
    location = 'Lat: ${position.latitude} , Long: ${position.longitude}';
    await GetAddressFromLatLong(
        position); // Await to ensure address is fully populated

    if (_getGeoLocationPosition.isBlank == false) {
      buttonEnabled = true;
    }

    setState(() {
      isAddressLoading =
      false; // Set to false after fetching location and populating address
      _addressController.text =
          Address; // Populate the address field after geolocation
    });
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
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> GetAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    Address =
    '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  //Used to set the _photo file as image from gallery
  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
         if(mounted) {
           setState(() {
             if (pickedFile != null) {
               _photo = File(pickedFile.path);
             } else {
               print('No image selected.');
             }
           });
         }
  }

  //Used to set the _photo file as image from gallery
  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );
      if(mounted) {
        setState(() {
          if (pickedFile != null) {
            _photo = File(pickedFile.path);
          } else {
            print('No image selected.');
          }
        });
      }
  }

  showImage(String image) {
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

    // Get the extension of the image file
    final extension = pathing
        .extension(_photo!.path); // Get the file extension (e.g., '.jpg')

    // Clean the address to make sure it doesn't contain invalid characters for a file name
    String addressFault =
    _addressController.text.isEmpty ? Address : _addressController.text;
    addressFault = addressFault.replaceAll(
        RegExp(r'[\/:*?"<>|]'), ''); // Remove invalid characters

    // Use the cleaned address as the file name (without extra pathing)
    final fileName =
        '$addressFault$extension'; // File name will now be 'address.jpg'

    // Create a folder with the date and time of the report (path should only include timestamp)
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    final destination =
        'files/faultImages/$formattedDate'; // Only the timestamp as folder path

    final String faultDescription = _faultDescriptionController.text;
    final String refNum = UniqueKey().toString();
    const String faultType = "Water & Sanitation";
    await _faultData.add({
      "ref": refNum,
      "uid": _currentUser,
      "accountNumber": '',
      "address": addressFault,
      "faultType": faultType,
      "reporterContact": userPhone,
      "departmentSwitchComment": '',
      "reallocationComment": '',
      "attendeeAllocated": '',
      "managerAllocated": '',
      "adminComment": '',
      "attendeeCom1": '',
      "attendeeCom2": '',
      "attendeeCom3": '',
      "managerCom1": '',
      "managerCom2": '',
      "managerCom3": '',
      "managerReturnCom": '',
      "attendeeReturnCom": '',
      "faultDescription": faultDescription,
      "depAllocated": '',
      "faultResolved": false,
      "dateReported": formattedDate,
      "faultStage": 1,
    });

    try {
      // Firebase storage reference with only the timestamp folder and the address as file name
      final ref = firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .child(fileName); // Only fileName (e.g., 'address.jpg')

      // Set metadata for correct content type (image MIME type)
      final metadata = firebase_storage.SettableMetadata(
        contentType:
        'image/${extension.replaceAll('.', '')}', // Correct MIME type
      );

      // Upload the image with the correct metadata
      await ref.putFile(_photo!, metadata);

      print('Image uploaded successfully: $destination/$fileName');
    } catch (e) {
      print('Error occurred during image upload: $e');
    }

    // Clear input fields after the upload
    _addressController.text = '';
    _faultDescriptionController.text = '';
    addressExists = false;

    if (mounted) {
      setState(() {
        dropdownValue = 'Select Fault Type';
      });
    }
  }

  ///Upload fault without an image file included and an image may be added later on
  Future uploadFault() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    final String addressFault = _addressController.text;
    final String faultDescription = _faultDescriptionController.text;
    final String refNum = UniqueKey().toString();
    const String faultType = "Water & Sanitation";

    await _faultData.add({
      "ref": refNum,
      "uid": _currentUser,
      "accountNumber": '',
      "address": addressFault,
      "faultType": faultType,
      "reporterContact": userPhone,
      "departmentSwitchComment": '',
      "reallocationComment": '',
      "attendeeAllocated": '',
      "managerAllocated": '',
      "adminComment": '',
      "attendeeCom1": '',
      "attendeeCom2": '',
      "attendeeCom3": '',
      "managerCom1": '',
      "managerCom2": '',
      "managerCom3": '',
      "managerReturnCom": '',
      "attendeeReturnCom": '',
      "faultDescription": faultDescription,
      "depAllocated": '',
      "faultResolved": false,
      "dateReported": formattedDate,
      "faultStage": 1,
    });

    _addressController.text = '';
    _faultDescriptionController.text = '';
    addressExists = false;
    setState(() {
      dropdownValue = 'Select Fault Type';
    });
  }

  Future<void> verifyAddress() async {
    const apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
    final address = _addressController.text;

    if (address.isNotEmpty) {
      final response = await http.get(
        Uri.parse(
            'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Address is valid, and you can get the coordinates
          final location = data['results'][0]['geometry']['location'];
          final double latitude = location['lat'];
          final double longitude = location['lng'];

          addressExists = true;

          print('Address exists at: $latitude, $longitude');
        } else {
          // Address is not valid
          addressExists = false;
          Fluttertoast.showToast(
            msg: "Address does not exist!",
            gravity: ToastGravity.CENTER,
          );
          print('Address does not exist');
        }
      } else {
        // Handle error
        addressExists = false;
        Fluttertoast.showToast(
          msg: "Error verifying address",
          gravity: ToastGravity.CENTER,
        );
        print('Error verifying address');
      }
    } else {
      // Address is empty
      addressExists = false;
      Fluttertoast.showToast(
        msg: "Please enter an address",
        gravity: ToastGravity.CENTER,
      );
      print('Please enter an address');
    }
  }
  Future<void> _addNewFaultReport() async {
    // Ensure the property data is available
    if (widget.currentProperty == null) {
      Fluttertoast.showToast(
        msg: "Property data is not available. Please try again later.",
        gravity: ToastGravity.CENTER,
      );
      return;
    }

    // Set default values from the current property
    String addressField = widget.currentProperty.address;
    String accountNumber = widget.currentProperty.accountNo;

    // Reset the dropdown and description controller
    setState(() {
      faultDescriptionValue = 'Select Fault Description';
      _faultDescriptionController.text = '';
    });

    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          title: const Text(
            "Report Property Fault",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: faultDescriptionValue,
                      isExpanded: true,
                      items: waterSanitationIssues.map<DropdownMenuItem<String>>((String issue) {
                        return DropdownMenuItem<String>(
                          value: issue,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(issue, style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          faultDescriptionValue = newValue!;
                          _faultDescriptionController.text = faultDescriptionValue == 'Select Fault Description'
                              ? ''
                              : faultDescriptionValue;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Fault Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Show the address and account number (non-editable)
                    Text(
                      'Address: $addressField',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Account Number: $accountNumber',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel the dialog
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Confirm submission
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      title: const Text("Submit Fault"),
                      content: const Text(
                        "To add a photo to your property fault report, go to your Current Reports tab to upload or update your fault image.",
                      ),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Cancel confirmation
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                        ),
                        IconButton(
                          onPressed: () async {
                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
                            const String faultType = 'Water & Sanitation';
                            final String refNum = UniqueKey().toString();
                            final String faultDescription = _faultDescriptionController.text;

                            if (faultDescription.isNotEmpty) {
                              await _faultData.add({
                                "ref": refNum,
                                "uid": _currentUser,
                                "accountNumber": accountNumber,
                                "address": addressField,
                                "faultType": faultType,
                                "reporterContact": userPhone,
                                "departmentSwitchComment": '',
                                "reallocationComment": '',
                                "attendeeAllocated": '',
                                "managerAllocated": '',
                                "adminComment": '',
                                "attendeeCom1": '',
                                "attendeeCom2": '',
                                "attendeeCom3": '',
                                "managerCom1": '',
                                "managerCom2": '',
                                "managerCom3": '',
                                "managerReturnCom": '',
                                "attendeeReturnCom": '',
                                "faultDescription": faultDescription,
                                "depAllocated": '',
                                "faultResolved": false,
                                "dateReported": formattedDate,
                                "faultStage": 1,
                                // Other fields as needed
                              });

                              // Reset fields
                              _faultDescriptionController.text = '';
                              faultDescriptionValue = 'Select Fault Description';

                              Fluttertoast.showToast(
                                msg: "Fault has been reported successfully!",
                                gravity: ToastGravity.CENTER,
                              );

                              Navigator.of(context).pop(); // Close confirmation
                              Navigator.of(context).pop(); // Close fault dialog
                            } else {
                              Fluttertoast.showToast(
                                msg: "Please fill in all required fields.",
                                gravity: ToastGravity.CENTER,
                              );
                            }
                          },
                          icon: const Icon(Icons.done, color: Colors.green),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }
}
