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
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;
import 'package:municipal_services/config/keys.dart';

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
  State<WaterSanitationReportMenu> createState() =>
      _WaterSanitationReportMenuState();
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
  Uint8List? _webImageBytes; // 📌 Holds selected image file (Web)
  String? _webImageName;
  File? _photo;
  final ImagePicker _picker = ImagePicker();
  String? meterType;

  TextEditingController nameController = TextEditingController();

  bool buttonEnabled = true;
  String location = 'Null, Press Button';
  String address = '';
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
    'No water',
    'Other'
  ];
  bool showOtherTextField = false;

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
          if (mounted) {
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
      if (mounted) {
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
                                style: TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: DropdownButtonFormField<String>(
                                value: faultDescriptionValue,
                                isExpanded: true,
                                items: waterSanitationIssues
                                    .map<DropdownMenuItem<String>>(
                                        (String issue) {
                                  return DropdownMenuItem<String>(
                                    value: issue,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: Text(issue,
                                          style: const TextStyle(fontSize: 16)),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (mounted) {
                                    setState(() {
                                      faultDescriptionValue = newValue!;
                                      showOtherTextField =
                                          faultDescriptionValue == 'Other';
                                      _faultDescriptionController.text =
                                          _faultDescriptionController.text =
                                              showOtherTextField
                                                  ? ''
                                                  : faultDescriptionValue;
                                    });
                                  }
                                },
                                decoration: formItemDecoration(
                                  'Select Fault Description',
                                  const Icon(Icons.warning_amber_outlined),
                                ),
                              ),
                            ),
                            if (showOtherTextField)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: TextFormField(
                                  controller: _faultDescriptionController,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.edit,
                                        color: Colors.black87),
                                    hintText: "Enter fault description...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          30), // Match others
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          30), // Match others
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide:
                                          const BorderSide(color: Colors.grey),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical:
                                            14), // Adjust padding to match others
                                    fillColor: Colors.white,
                                    filled: true,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextFormField(
                                controller: _addressController,
                                validator: (val) => val == ""
                                    ? "Please enter an Address"
                                    : null,
                                decoration: formItemDecoration(
                                  "Address...",
                                  const Icon(Icons.location_on_sharp,
                                      color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: TextFormField(
                                controller: _reporterPhoneController,
                                validator: (val) => val == ""
                                    ? "Enter reporter's contact number"
                                    : null,
                                decoration: formItemDecoration(
                                  "Reporter Phone Number...",
                                  const Icon(Icons.phone_in_talk,
                                      color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 50.0),
                                  child: Text(
                                    'Add Photo?',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      showImagePicker(context);
                                    },
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[400],
                                      child: _photo != null ||
                                              _webImageBytes != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      50), // Keep it circular
                                              child: kIsWeb
                                                  ? Image.memory(
                                                      _webImageBytes!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.file(
                                                      _photo!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30.0),
                                child: BasicIconButtonGreen(
                                  onPress: buttonEnabled &&
                                          (_addressController.text.isNotEmpty ||
                                              !isAddressLoading)
                                      ? () async {
                                          // Validate form fields
                                          if (_addressController.text.isEmpty) {
                                            Fluttertoast.showToast(
                                              msg: "Please enter an address.",
                                              gravity: ToastGravity.CENTER,
                                            );
                                            return;
                                          }
                                          if (_faultDescriptionController
                                              .text.isEmpty) {
                                            Fluttertoast.showToast(
                                              msg:
                                                  "Please provide a fault description.",
                                              gravity: ToastGravity.CENTER,
                                            );
                                            return;
                                          }
                                          if (_reporterPhoneController
                                                  .text.isEmpty ||
                                              !_reporterPhoneController.text
                                                  .startsWith("+27")) {
                                            Fluttertoast.showToast(
                                              msg:
                                                  "Please enter a valid phone number with +27 country code.",
                                              gravity: ToastGravity.CENTER,
                                            );
                                            return;
                                          }

                                          // Check if photo is attached
                                          if (_photo != null ||
                                              _webImageBytes != null) {
                                            await verifyAddress();
                                            if (addressExists) {
                                              await uploadFaultFile();
                                              Fluttertoast.showToast(
                                                msg:
                                                    "Fault has been reported successfully with an image!",
                                                gravity: ToastGravity.CENTER,
                                              );
                                              Navigator.pop(context);
                                            } else {
                                              Fluttertoast.showToast(
                                                msg:
                                                    "Please input a valid address.",
                                                gravity: ToastGravity.CENTER,
                                              );
                                            }
                                          } else {
                                            // If no photo is attached, confirm reporting without an image
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.all(
                                                                  Radius
                                                                      .circular(
                                                                          16))),
                                                  title: const Text(
                                                      "Report Fault Without Image"),
                                                  content: const Text(
                                                      "Reporting a fault without a photo is possible. You can add a photo later."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.green),
                                                      onPressed: () async {
                                                        await verifyAddress();
                                                        if (addressExists) {
                                                          await uploadFault();
                                                          Fluttertoast
                                                              .showToast(
                                                            msg:
                                                                "Fault has been reported successfully!",
                                                            gravity:
                                                                ToastGravity
                                                                    .CENTER,
                                                          );
                                                          Navigator.of(context)
                                                              .pop(); // Close confirmation
                                                          Navigator.pop(
                                                              context); // Close fault dialog
                                                        } else {
                                                          Fluttertoast
                                                              .showToast(
                                                            msg:
                                                                "Please input a valid address.",
                                                            gravity:
                                                                ToastGravity
                                                                    .CENTER,
                                                          );
                                                        }
                                                      },
                                                      child: const Text(
                                                        "Submit",
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        }
                                      : () {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Please wait until the address is loaded.",
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
                                    fontSize: 19, fontWeight: FontWeight.w700),
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
                      child: StreamBuilder<QuerySnapshot>(
                        stream:  _faultData
                            .where('reporterContact', isEqualTo: userPhone)
                            .where('address',
                                isEqualTo: widget.currentProperty.address)
                            .snapshots(),
                        builder: (context,
                            AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                          print(
                              '📡 Stream connection state: ${streamSnapshot.connectionState}');
                          print('📱 userPhone: $userPhone');
                          print(
                              '🏠 address: ${widget.currentProperty.address}');

                          if (streamSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            print('⏳ Waiting for faultReporting data...');
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (streamSnapshot.hasError) {
                            print('❌ Stream error: ${streamSnapshot.error}');
                            return const Center(
                                child: Text('Something went wrong.'));
                          }

                          if (!streamSnapshot.hasData ||
                              streamSnapshot.data!.docs.isEmpty) {
                            print('📭 No faults found matching criteria.');
                            return const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Center(
                                child: Card(
                                  margin: EdgeInsets.all(10),
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
                            );
                          }

                          print(
                              '✅ Faults found: ${streamSnapshot.data!.docs.length}');

                          return ListView.builder(
                            itemCount: streamSnapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              final documentSnapshot =
                                  streamSnapshot.data!.docs[index];
                              final bool faultResolved =
                                  documentSnapshot['faultResolved'];
                              final String status =
                                  faultResolved ? "Completed" : "Pending";

                              print(
                                  '📄 Processing fault #$index: ${documentSnapshot.id}');
                              print(
                                  '   - Contact: ${documentSnapshot['reporterContact']}');
                              print(
                                  '   - Address: ${documentSnapshot['address']}');
                              print('   - Status: $status');
                           if (documentSnapshot['address'] == widget.currentProperty.address) {
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Center(
                                        child: Text(
                                          'Fault Information',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                          'Reference Number: ${documentSnapshot['ref']}'),
                                      if (documentSnapshot['accountNumber'] !=
                                          "") ...[
                                        const SizedBox(height: 5),
                                        Text(
                                            'Reporter Account Number: ${documentSnapshot['accountNumber']}'),
                                      ],
                                      const SizedBox(height: 5),
                                      Text(
                                          'Street Address of Fault: ${documentSnapshot['address']}'),
                                      const SizedBox(height: 5),
                                      Text(
                                          'Date of Fault Report: ${documentSnapshot['dateReported']}'),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Fault Stage: ${documentSnapshot['faultStage']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: {
                                                1: Colors.deepOrange,
                                                2: Colors.orange,
                                                3: Colors.orangeAccent,
                                                4: Colors.lightGreen,
                                                5: Colors.green
                                              }[documentSnapshot[
                                                  'faultStage']] ??
                                              Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                          'Fault Type: ${documentSnapshot['faultType']}'),
                                      if (documentSnapshot[
                                              'faultDescription'] !=
                                          "") ...[
                                        const SizedBox(height: 5),
                                        Text(
                                            'Fault Description: ${documentSnapshot['faultDescription']}'),
                                      ],
                                      const SizedBox(height: 5),
                                      Text('Resolve State: $status'),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          BasicIconButtonGreen(
                                            onPress: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MapScreenProp(
                                                    propAddress:
                                                        documentSnapshot[
                                                            'address'],
                                                    propAccNumber:
                                                        documentSnapshot[
                                                            'accountNumber'],
                                                  ),
                                                ),
                                              );
                                            },
                                            labelText: 'Location',
                                            fSize: 14,
                                            faIcon: const FaIcon(Icons.map),
                                            fgColor: Colors.purple,
                                            btSize: const Size(40, 40),
                                          ),
                                          Expanded(
                                            child: BasicIconButtonGreen(
                                              onPress: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FaultImageUpload(
                                                      propertyAddress:
                                                          documentSnapshot[
                                                              'address'],
                                                      reportedDate:
                                                          documentSnapshot[
                                                              'dateReported'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              labelText: 'Image +',
                                              fSize: 14,
                                              faIcon: const FaIcon(
                                                  Icons.photo_camera),
                                              fgColor: Colors.blueGrey,
                                              btSize: const Size(40, 40),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                           } else {
                             return const SizedBox(); // Skip unrelated faults
                           }
                            },
                          );
                        },
                      ),
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
    if (mounted) {
      setState(() {
        isAddressLoading = true;
      });
    }

    // Check if running on web - SKIP GPS and allow manual address entry
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          isAddressLoading = false; // ✅ Allow manual input on web
        });
      }
      return; // Stop execution here for web
    }

    // If not web, continue with GPS logic for mobile
    try {
      Position position = await _getGeoLocationPosition();
      location = 'Lat: ${position.latitude} , Long: ${position.longitude}';

      await GetAddressFromLatLong(position);

      if (mounted) {
        setState(() {
          isAddressLoading = false;
          _addressController.text = address;
        });
      }
    } catch (e) {
      print("❌ Location error: $e");

      if (mounted) {
        setState(() {
          isAddressLoading = false;
        });
      }
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
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> GetAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    address =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  //Used to set the _photo file as image from gallery
  // Future imgFromGallery() async {
  //   final pickedFile = await _picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 60,
  //   );
  //        if(mounted) {
  //          setState(() {
  //            if (pickedFile != null) {
  //              _photo = File(pickedFile.path);
  //            } else {
  //              print('No image selected.');
  //            }
  //          });
  //        }
  // }
  //
  // //Used to set the _photo file as image from gallery
  // Future imgFromCamera() async {
  //   final pickedFile = await _picker.pickImage(
  //     source: ImageSource.camera,
  //     imageQuality: 60,
  //   );
  //     if(mounted) {
  //       setState(() {
  //         if (pickedFile != null) {
  //           _photo = File(pickedFile.path);
  //         } else {
  //           print('No image selected.');
  //         }
  //       });
  //     }
  // }
  Future<void> _pickImageFromPC() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.bytes != null) {
      if (mounted) {
        setState(() {
          _webImageBytes = result.files.single.bytes;
          _webImageName = result.files.single.name;
        });
      }
    }
  }

  /// 📷 Pick Image from Mobile Gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    }
  }

  /// 📷 Capture Image Using Camera (Mobile Only)
  Future<void> _pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      if (mounted) {
        setState(() {
          _photo = File(pickedFile.path);
        });
      }
    }
  }

  /// 📌 Show Image Picker (Handles Mobile & Web)
  Future<void> showImagePicker(BuildContext context) async {
    if (kIsWeb) {
      print("📂 Attempting to pick an image (Web)");
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.bytes != null) {
        if (mounted) {
          setState(() {
            _webImageBytes = result.files.single.bytes;
            _webImageName = result.files.single.name;
            print("✅ Image selected (Web): $_webImageName");
          });
        }
      } else {
        print("❌ No image selected (Web)");
      }
    } else {
      // For mobile devices (Gallery or Camera)
      showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    _pickImageFromGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    _pickImageFromCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  showImage(String image) {
    return Image.memory(base64Decode(image));
  }

  // void _showPicker(context) {
  //   showModalBottomSheet(
  //       context: context,
  //       builder: (BuildContext bc) {
  //         return SafeArea(
  //           child: Container(
  //             child: Wrap(
  //               children: <Widget>[
  //                 ListTile(
  //                     leading: const Icon(Icons.photo_library),
  //                     title: const Text('Gallery'),
  //                     onTap: () {
  //                       imgFromGallery();
  //                       Navigator.of(context).pop();
  //                     }),
  //                 ListTile(
  //                   leading: const Icon(Icons.photo_camera),
  //                   title: const Text('Camera'),
  //                   onTap: () {
  //                     imgFromCamera();
  //                     Navigator.of(context).pop();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       });
  // }

  ///Upload fault with an image file included
  // Future uploadFaultFile() async {
  //   if (_photo == null) return;
  //
  //   // Get the extension of the image file
  //   final extension = pathing
  //       .extension(_photo!.path); // Get the file extension (e.g., '.jpg')
  //
  //   // Clean the address to make sure it doesn't contain invalid characters for a file name
  //   String addressFault =
  //   _addressController.text.isEmpty ? address : _addressController.text;
  //   addressFault = addressFault.replaceAll(
  //       RegExp(r'[\/:*?"<>|]'), ''); // Remove invalid characters
  //
  //   // Use the cleaned address as the file name (without extra pathing)
  //   final fileName =
  //       '$addressFault$extension'; // File name will now be 'address.jpg'
  //
  //   // Create a folder with the date and time of the report (path should only include timestamp)
  //   DateTime now = DateTime.now();
  //   String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
  //   final destination =
  //       'files/faultImages/$formattedDate'; // Only the timestamp as folder path
  //
  //   final String faultDescription = _faultDescriptionController.text;
  //   final String refNum = UniqueKey().toString();
  //   const String faultType = "Water & Sanitation";
  //   await _faultData.add({
  //     "ref": refNum,
  //     "uid": _currentUser,
  //     "accountNumber": '',
  //     "address": addressFault,
  //     "faultType": faultType,
  //     "reporterContact": userPhone,
  //     "departmentSwitchComment": '',
  //     "reallocationComment": '',
  //     "attendeeAllocated": '',
  //     "managerAllocated": '',
  //     "adminComment": '',
  //     "attendeeCom1": '',
  //     "attendeeCom2": '',
  //     "attendeeCom3": '',
  //     "managerCom1": '',
  //     "managerCom2": '',
  //     "managerCom3": '',
  //     "managerReturnCom": '',
  //     "attendeeReturnCom": '',
  //     "faultDescription": faultDescription,
  //     "depAllocated": '',
  //     "faultResolved": false,
  //     "dateReported": formattedDate,
  //     "faultStage": 1,
  //   });
  //
  //   try {
  //     // Firebase storage reference with only the timestamp folder and the address as file name
  //     final ref = firebase_storage.FirebaseStorage.instance
  //         .ref(destination)
  //         .child(fileName); // Only fileName (e.g., 'address.jpg')
  //
  //     // Set metadata for correct content type (image MIME type)
  //     final metadata = firebase_storage.SettableMetadata(
  //       contentType:
  //       'image/${extension.replaceAll('.', '')}', // Correct MIME type
  //     );
  //
  //     // Upload the image with the correct metadata
  //     await ref.putFile(_photo!, metadata);
  //
  //     print('Image uploaded successfully: $destination/$fileName');
  //   } catch (e) {
  //     print('Error occurred during image upload: $e');
  //   }
  //
  //   // Clear input fields after the upload
  //   _addressController.text = '';
  //   _faultDescriptionController.text = '';
  //   addressExists = false;
  //
  //   if (mounted) {
  //     setState(() {
  //       dropdownValue = 'Select Fault Type';
  //     });
  //   }
  // }
  /// 📌 Upload Fault with Image (Works for Web & Mobile)
  Future<void> uploadFaultFile() async {
    if (_photo == null && _webImageBytes == null) return;

    // Get the current date for folder structuring
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);

    // Ensure address formatting is correct
    String addressFault =
        _addressController.text.isEmpty ? address : _addressController.text;
    addressFault = addressFault.replaceAll(
        RegExp(r'[\/:*?"<>|]'), ''); // Remove invalid characters

    // Ensure correct file extension for mobile
    String fileExtension = kIsWeb ? '.png' : pathing.extension(_photo!.path);
    final fileName = '$addressFault$fileExtension'; // Address as filename

    // ✅ Ensure the path is treated as a folder by appending a filename
    final destination = 'files/faultImages/$formattedDate/$fileName';
    // Generate a unique reference number
    final String refNum = UniqueKey().toString();
    const String faultType = "Water & Sanitation";

    // Store fault details in Firestore
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
      "faultDescription": _faultDescriptionController.text,
      "depAllocated": '',
      "faultResolved": false,
      "dateReported": formattedDate,
      "faultStage": 1,
    });

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);

      if (kIsWeb && _webImageBytes != null) {
        // Upload file from web as bytes
        await ref.putData(
          _webImageBytes!,
          firebase_storage.SettableMetadata(
              contentType: 'image/png'), // Ensure it's a PNG for web
        );
      } else if (_photo != null) {
        // Upload file from mobile (File object)
        await ref.putFile(
          _photo!,
          firebase_storage.SettableMetadata(
              contentType: 'image/jpeg'), // Ensure it's a JPEG for mobile
        );
      }

      print('✅ Image uploaded successfully: $destination');
    } catch (e) {
      print('❌ Error occurred during image upload: $e');
    }

    // Clear input fields after upload
    _addressController.text = '';
    _faultDescriptionController.text = '';
    addressExists = false;

    if (mounted) {
      setState(() {
        dropdownValue = 'Select Fault Type';
        _photo = null;
        _webImageBytes = null;
      });
    }

    Fluttertoast.showToast(msg: "Fault reported successfully!");
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
    if (mounted) {
      setState(() {
        dropdownValue = 'Select Fault Type';
      });
    }
  }

  Future<void> verifyAddress() async {
    final address = _addressController.text;

    if (address.isNotEmpty) {
      final response = await http.get(
        Uri.parse('https://maps.googleapis.com/maps/api/geocode/json'
            '?address=$address&key=$geocodeWebKey'),
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
    if (mounted) {
      setState(() {
        faultDescriptionValue = 'Select Fault Description';
        _faultDescriptionController.text = '';
      });
    }
    // Use showGeneralDialog for a full-screen dialog
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'FullScreenDialog',
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Report Property Fault',
                  style: TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the full-screen dialog
                  },
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Fault Description Dropdown
                      DropdownButtonFormField<String>(
                        value: faultDescriptionValue,
                        isExpanded: true,
                        menuMaxHeight:
                            400, // Expands dropdown for better visibility
                        items: waterSanitationIssues
                            .map<DropdownMenuItem<String>>((String issue) {
                          return DropdownMenuItem<String>(
                            value: issue,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(issue,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setModalState(() {
                            faultDescriptionValue = newValue!;
                            showOtherTextField =
                                faultDescriptionValue == 'Other';
                            _faultDescriptionController.text =
                                _faultDescriptionController.text =
                                    showOtherTextField
                                        ? ''
                                        : faultDescriptionValue;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Select Fault Description',
                          labelStyle: const TextStyle(fontSize: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 15),
                        ),
                      ),
                      if (showOtherTextField)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: TextFormField(
                            controller: _faultDescriptionController,
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.edit, color: Colors.black87),
                              hintText: "Enter fault description...",
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30), // Match others
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(30), // Match others
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical:
                                      14), // Adjust padding to match others
                              fillColor: Colors.white,
                              filled: true,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Address Field
                      TextFormField(
                        readOnly: true,
                        initialValue: addressField,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Address",
                          labelStyle: const TextStyle(fontSize: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 15),
                          prefixIcon: const Icon(Icons.location_on_sharp,
                              color: Colors.black87),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Account Number Field
                      TextFormField(
                        readOnly: true,
                        initialValue: accountNumber,
                        decoration: InputDecoration(
                          labelText: "Account Number",
                          labelStyle: const TextStyle(fontSize: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 15),
                          prefixIcon: const Icon(Icons.account_circle,
                              color: Colors.black87),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            // Confirm submission
                            showDialog(
                              barrierDismissible: false,
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text("Submit Fault"),
                                  content: const Text(
                                    "To add a photo to your property fault report, go to your Current Reports tab to upload or update your fault image.",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        DateTime now = DateTime.now();
                                        String formattedDate =
                                            DateFormat('yyyy-MM-dd – kk:mm')
                                                .format(now);
                                        const String faultType =
                                            'Water & Sanitation';
                                        final String refNum =
                                            UniqueKey().toString();
                                        final String faultDescription =
                                            _faultDescriptionController.text;

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
                                            "faultDescription":
                                                faultDescription,
                                            "depAllocated": '',
                                            "faultResolved": false,
                                            "dateReported": formattedDate,
                                            "faultStage": 1,
                                          });

                                          // Reset fields
                                          _faultDescriptionController.text = '';
                                          faultDescriptionValue =
                                              'Select Fault Description';

                                          Fluttertoast.showToast(
                                            msg:
                                                "Fault has been reported successfully!",
                                            gravity: ToastGravity.CENTER,
                                          );

                                          Navigator.of(context)
                                              .pop(); // Close confirmation dialog
                                          Navigator.of(context)
                                              .pop(); // Close full-screen dialog
                                        } else {
                                          Fluttertoast.showToast(
                                            msg:
                                                "Please fill in all required fields.",
                                            gravity: ToastGravity.CENTER,
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Okay",
                                        style: TextStyle(
                                            color: Colors.blue, fontSize: 18),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            "Submit Fault",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
