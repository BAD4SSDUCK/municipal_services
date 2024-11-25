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

import '../Models/prop_provider.dart';
import '../Models/property.dart';

class ReportPropertyMenu extends StatefulWidget {
  final Property currentProperty;
  final bool isLocalMunicipality;
  final String municipalityId;
  final String? districtId;

  const ReportPropertyMenu({
    super.key,
    required this.currentProperty,
    required this.isLocalMunicipality,
    required this.municipalityId,
    this.districtId,
  });

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

late GoogleMapController _mapController;

class _ReportPropertyMenuState extends State<ReportPropertyMenu> {
  final _faultDescriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _reporterPhoneController = TextEditingController();
  late final CollectionReference _faultData;
  late final CollectionReference _deptInfo;
  late final CollectionReference _propList;
  String _streetNumber = '';
  String _street = '';
  String _city = '';
  String _zipCode = '';
  String districtId = '';
  String municipalityId = '';

  final String _currentUser = userID;

  // final CollectionReference _faultData =
  // FirebaseFirestore.instance.collection('faultReporting');
  //
  // final CollectionReference _deptInfo =
  // FirebaseFirestore.instance.collection('departments');
  //
  // final CollectionReference _propList =
  // FirebaseFirestore.instance.collection('properties');

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

  @override
  void initState() {
    fetchUserDetails();
    locationAllow();
    _reporterPhoneController.text = userPhone;
    super.initState();
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
          setState(() {
            propertyDocument = propertySnapshot.docs.first;
            isLoading = false;
            addressPass = currentProperty?.address ?? '';
            accountPass = currentProperty?.accountNo ?? '';
          });

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
      setState(() {
        isLoading = false; // Handle the error state appropriately
      });
    }
  }

  ///Form text field decoration style
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

  Future<Widget> _getImage(BuildContext context, String imageName) async {
    Image image;
    final value = await FireStorageService.loadImage(context, imageName);
    image = Image.network(
      value.toString(),
      fit: BoxFit.fill,
    );
    return image;
  }

  String faultDescriptionValue =
      "Select Fault Description"; // Default value for dropdown
  List<String> waterSanitationIssues = [
    'Select Fault Description',
    'Leakage',
    'Burst pipe',
    'Clogged storm drains/pipes',
    'No water'
  ];

  @override
  Widget build(BuildContext context) {
    final currentProperty =
        Provider.of<PropertyProvider>(context).selectedProperty;
    return GetBuilder<LocationController>(builder: (locationController) {
      if (isLoading) {
        // Show a loading indicator while data is being fetched
        return const Center(child: CircularProgressIndicator());
      }
      return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.grey[350],
            appBar: AppBar(
              title: const Text(
                'Report Fault',
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
                              const SizedBox(
                                height: 20,
                              ),
                              const Center(
                                child: Text(
                                  'Report Public Fault',
                                  style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: Column(children: [
                                  SizedBox(
                                    width: 450,
                                    height: 50,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 10, right: 10),
                                      child: Center(
                                        child: TextField(
                                          ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )),
                                            disabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                borderSide: const BorderSide(
                                                  color: Colors.grey,
                                                )),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 6),
                                            fillColor: Colors.white,
                                            filled: true,
                                            suffixIcon:
                                                DropdownButtonFormField<String>(
                                              value: dropdownValue,
                                                  isExpanded: true,
                                              items: <String>[
                                                'Select Fault Type',
                                                'Water & Sanitation',
                                               'Roadworks',
                                                'Waste Management'
                                              ].map<DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 0.0,
                                                        horizontal: 20.0),
                                                    child: Text(
                                                      value,
                                                      style: const TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  dropdownValue = newValue!;
                                                  _addressController.text =
                                                      Address;
                                                  if (dropdownValue !=
                                                      'Water & Sanitation') {
                                                    _faultDescriptionController
                                                        .text = '';
                                                  }
                                                });
                                              },
                                              icon: const Padding(
                                                padding: EdgeInsets.only(
                                                    left: 10, right: 10),
                                                child: Icon(Icons
                                                    .arrow_circle_down_sharp),
                                              ),
                                              iconEnabledColor: Colors.green,
                                              style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18),
                                              dropdownColor: Colors.grey[50],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(
                                height: 20,
                              ),

                              dropdownValue == 'Water & Sanitation'
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: DropdownButtonFormField<String>(
                                        value: faultDescriptionValue,
                                        items: waterSanitationIssues
                                            .map<DropdownMenuItem<String>>(
                                                (String issue) {
                                          return DropdownMenuItem<String>(
                                            value: issue,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              child: Text(
                                                issue,
                                                style: const TextStyle(
                                                    fontSize: 16),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            faultDescriptionValue = newValue!;
                                            _faultDescriptionController
                                                .text = faultDescriptionValue ==
                                                    'Select Fault Description'
                                                ? ''
                                                : faultDescriptionValue;
                                          });
                                        },
                                        decoration: formItemDecoration(
                                            'Select Fault Description',
                                            const Icon(
                                                Icons.warning_amber_outlined)),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10.0),
                                      child: TextFormField(
                                        controller: _faultDescriptionController,
                                        validator: (val) => val == ""
                                            ? "Please describe the fault"
                                            : null,
                                        decoration: formItemDecoration(
                                          "Fault Description...",
                                          const Icon(
                                            Icons.note_alt_outlined,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                              const SizedBox(
                                height: 20,
                              ),

                              // Padding(
                              //   padding: const EdgeInsets.symmetric(horizontal: 25.0),
                              //   child:
                              //   ///https://medium.com/@yshean/location-search-autocomplete-in-flutter-84f155d44721
                              //   Column(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: <Widget>[
                              //       TextField(
                              //         controller: _addressController,
                              //         readOnly: true,
                              //         onTap: () async {
                              //           // generate a new token here
                              //           final sessionToken = Uuid().v4();
                              //           final Suggestion? result = await showSearch(
                              //             context: context,
                              //             delegate: AddressSearch(),//sessionToken
                              //           );
                              //           // This will change the text displayed in the TextField
                              //           if (result != null) {
                              //             final placeDetails = await PlaceApiProvider(sessionToken)
                              //                 .getPlaceDetailFromId(result.placeId);
                              //             setState(() {
                              //               _addressController.text = result.description;
                              //               _streetNumber = placeDetails.streetNumber;
                              //               _street = placeDetails.street;
                              //               _city = placeDetails.city;
                              //               _zipCode = placeDetails.zipCode;
                              //               _addressController.text = '$_streetNumber $_street $_city $_zipCode';
                              //             });
                              //           }
                              //         },
                              //         decoration: const InputDecoration(
                              //           icon: SizedBox(
                              //             width: 10,
                              //             height: 10,
                              //             child: Icon(
                              //               Icons.home,
                              //               color: Colors.black,
                              //             ),
                              //           ),
                              //           hintText: "Report Address...",
                              //           border: InputBorder.none,
                              //           contentPadding: EdgeInsets.only(left: 8.0, top: 16.0),
                              //         ),
                              //       ),
                              //       const SizedBox(height: 20.0),
                              //       Text('Street Number: $_streetNumber'),
                              //       Text('Street: $_street'),
                              //       Text('City: $_city'),
                              //       Text('ZIP Code: $_zipCode'),
                              //     ],
                              //   ),
                              // ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: TextFormField(
                                  controller: _addressController,
                                  validator: (val) => val == ""
                                      ? "Please enter an Address"
                                      : null,
                                  decoration: formItemDecoration(
                                    "Address...",
                                    const Icon(
                                      Icons.location_on_sharp,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: TextFormField(
                                  controller: _reporterPhoneController,
                                  validator: (val) => val == ""
                                      ? "Enter reporters contact number"
                                      : null,
                                  decoration: formItemDecoration(
                                    "Reporter Phone Number...",
                                    const Icon(
                                      Icons.phone_in_talk,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                children: [
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 50.0),
                                    child: Text(
                                      'Add Photo?',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ), //fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        _showPicker(context);
                                      },
                                      child: CircleAvatar(
                                        radius: 50,
                                        backgroundColor: Colors.grey[400],
                                        child: _photo != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
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
                              const SizedBox(
                                height: 20,
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0),
                                  child: BasicIconButtonGreen(
                                    onPress: buttonEnabled && !isAddressLoading
                                        ? () async {
                                            if (_photo != null) {
                                              if (dropdownValue !=
                                                      'Select Fault Type' &&
                                                  _addressController
                                                      .text.isNotEmpty &&
                                                  _faultDescriptionController
                                                      .text.isNotEmpty &&
                                                  _reporterPhoneController
                                                      .text.isNotEmpty) {
                                                if (_reporterPhoneController
                                                    .text
                                                    .contains('+27')) {
                                                  // Wait for the address verification to complete
                                                  await verifyAddress();

                                                  if (addressExists) {
                                                    // If address verification is successful, proceed with reporting
                                                    uploadFaultFile();
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Fault has been Reported with Image!",
                                                        gravity: ToastGravity
                                                            .CENTER);
                                                    navigator?.pop();
                                                  } else {
                                                    Fluttertoast.showToast(
                                                        msg:
                                                            "Please input a valid address!",
                                                        gravity: ToastGravity
                                                            .CENTER);
                                                  }
                                                } else {
                                                  Fluttertoast.showToast(
                                                      msg:
                                                          "Contact number must have +27 country code!",
                                                      gravity:
                                                          ToastGravity.CENTER);
                                                }
                                              } else {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Please fill all fields to report!",
                                                    gravity:
                                                        ToastGravity.CENTER);
                                              }
                                            } else if (_photo == null) {
                                              if (dropdownValue !=
                                                      'Select Fault Type' &&
                                                  _addressController
                                                      .text.isNotEmpty &&
                                                  _faultDescriptionController
                                                      .text.isNotEmpty &&
                                                  _reporterPhoneController
                                                      .text.isNotEmpty) {
                                                showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        shape: const RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(Radius
                                                                        .circular(
                                                                            16))),
                                                        title: const Text(
                                                            "Report Fault Without Image!"),
                                                        content: const Text(
                                                            "Reporting a fault without a photo is possible. A photo can be added later on if necessary,\n\nare you sure you want to leave out a photo?"),
                                                        actions: [
                                                          IconButton(
                                                            onPressed: () {
                                                              Fluttertoast.showToast(
                                                                  msg:
                                                                      "Please tap on the image area and select the image to upload!",
                                                                  gravity:
                                                                      ToastGravity
                                                                          .CENTER);
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            icon: const Icon(
                                                              Icons.cancel,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                () async {
                                                              // Verify the address before proceeding
                                                              await verifyAddress();

                                                              if (addressExists) {
                                                                if (dropdownValue !=
                                                                        'Select Fault Type' &&
                                                                    _addressController
                                                                        .text
                                                                        .isNotEmpty &&
                                                                    _faultDescriptionController
                                                                        .text
                                                                        .isNotEmpty &&
                                                                    _reporterPhoneController
                                                                        .text
                                                                        .isNotEmpty) {
                                                                  if (_reporterPhoneController
                                                                      .text
                                                                      .contains(
                                                                          '+27')) {
                                                                    uploadFault();
                                                                    Fluttertoast.showToast(
                                                                        msg:
                                                                            "Fault has been Reported!",
                                                                        gravity:
                                                                            ToastGravity.CENTER);
                                                                  } else {
                                                                    Fluttertoast.showToast(
                                                                        msg:
                                                                            "Contact number must have +27 country code!",
                                                                        gravity:
                                                                            ToastGravity.CENTER);
                                                                  }
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                } else {
                                                                  Fluttertoast.showToast(
                                                                      msg:
                                                                          "Please fill all fields to report!",
                                                                      gravity:
                                                                          ToastGravity
                                                                              .CENTER);
                                                                }
                                                              } else {
                                                                Fluttertoast.showToast(
                                                                    msg:
                                                                        "Please input a valid address!",
                                                                    gravity:
                                                                        ToastGravity
                                                                            .CENTER);
                                                              }
                                                            },
                                                            icon: const Icon(
                                                              Icons.done,
                                                              color:
                                                                  Colors.green,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    });
                                              } else {
                                                Fluttertoast.showToast(
                                                    msg:
                                                        "Please fill all fields to report!",
                                                    gravity:
                                                        ToastGravity.CENTER);
                                              }
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg:
                                                      "Please fill all fields to report!",
                                                  gravity: ToastGravity.CENTER);
                                            }
                                          }
                                        : () {
                                            Fluttertoast.showToast(
                                                msg:
                                                    "Please allow location access and wait for address to load!",
                                                gravity: ToastGravity.CENTER);
                                          },
                                    labelText: 'Report Fault',
                                    fSize: 20,
                                    faIcon: const FaIcon(Icons.report),
                                    fgColor: Colors.orangeAccent,
                                    btSize: const Size(300, 40),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 10,
                              ),

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

                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ///TAB for property fault report view
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

                // Expanded(
                //   child: StreamBuilder<QuerySnapshot>(
                //     stream: _propList.snapshots(),
                //     builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                //       if (streamSnapshot.hasData) {
                //         return ListView.builder(
                //           ///this call is to display all details for all users but is only displaying for the current user account.
                //           ///it can be changed to display all users for the staff to see if the role is set to all later on.
                //           itemCount: streamSnapshot.data!.docs.length,
                //           itemBuilder: (context, index) {
                //             final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                //             ///A check for if payment is outstanding or not
                //             if (documentSnapshot['eBill'] != '' ||
                //                 documentSnapshot['eBill'] != 'R0,000.00' ||
                //                 documentSnapshot['eBill'] != 'R0.00' ||
                //                 documentSnapshot['eBill'] != 'R0' ||
                //                 documentSnapshot['eBill'] != '0') {
                //               billMessage = documentSnapshot['eBill'];
                //               buttonEnabled = false;
                //             } else {
                //               billMessage = 'No outstanding payments';
                //               buttonEnabled = true;
                //             }
                //             ///Check for only user information, this displays only for the users details and not all users in the database.
                //             if (streamSnapshot.data!.docs[index]['cell number'] == userPhone) {
                //               return Card(
                //                 margin: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 0),
                //                 child: Padding(
                //                   padding: const EdgeInsets.all(20.0),
                //                   child: Column(
                //                     mainAxisAlignment: MainAxisAlignment.center,
                //                     crossAxisAlignment: CrossAxisAlignment.start,
                //                     children: [
                //                       const SizedBox(height: 5,),
                //                       const Center(
                //                         child: Text(
                //                           'Property Information',
                //                           style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                //                         ),
                //                       ),
                //                       const SizedBox(height: 20,),
                //                       Text(
                //                         'Account Number: ${documentSnapshot['account number']}',
                //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                //                       ),
                //                       const SizedBox(height: 5,),
                //                       Text(
                //                         'Street Address: ${documentSnapshot['address']}',
                //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                //                       ),
                //                       const SizedBox(height: 5,),
                //                       Text(
                //                         'Area Code: ${documentSnapshot['area code'].toString()}',
                //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                //                       ),
                //                       const SizedBox(height: 5,),
                //                       Text(
                //                         'Property Bill: $billMessage',
                //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                //                       ),
                //                       const SizedBox(height: 10,),
                //                       ///Report adding button
                //                       Center(
                //                           child: BasicIconButtonGreen(
                //                             onPress: buttonEnabled ? () {
                //                               userPass = _currentUser;
                //                               addressPass = documentSnapshot['address'];
                //                               accountPass = documentSnapshot['account number'];
                //                               phoneNumPass = documentSnapshot['cell number'];
                //
                //                               _addNewFaultReport();
                //                             } : () {
                //                               Fluttertoast.showToast(msg: "Outstanding bill on property, Fault Reporting unavailable!",
                //                                 gravity: ToastGravity.CENTER,);
                //                             },
                //                             labelText: 'Report Property Fault',
                //                             fSize: 16,
                //                             faIcon: const FaIcon(Icons.report),
                //                             fgColor: Colors.orangeAccent,
                //                             btSize: const Size(150, 40),
                //                           )
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               );
                //             } else {
                //               ///a card to display ALL details for users when role is set to admin is in "display_info_all_users.dart"
                //               return const SizedBox();
                //             }
                //           },
                //         );
                //       }
                //       return const Padding(
                //         padding: EdgeInsets.all(10.0),
                //         child: Center(child: CircularProgressIndicator()),
                //       );
                //     },
                //   ),
                // ),

                ///TAB for viewing all current reports ordered latest to oldest and not completed

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
                                                        BasicIconButtonGreen(
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
          ));
    });
  }

  ///All code bellow for geolocation and adding fault with and without an image
  Future<void> locationAllow() async {
    if(mounted) {
      setState(() {
        isAddressLoading = true; // Set to true while fetching location
      });
    }
    Position position = await _getGeoLocationPosition();
    location = 'Lat: ${position.latitude} , Long: ${position.longitude}';
    await GetAddressFromLatLong(
        position); // Await to ensure address is fully populated

    if (_getGeoLocationPosition.isBlank == false) {
      buttonEnabled = true;
    }
       if(mounted) {
         setState(() {
           isAddressLoading =
           false; // Set to false after fetching location and populating address
           _addressController.text =
               Address; // Populate the address field after geolocation
         });
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
    Address =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  //Used to set the _photo file as image from gallery
  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

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
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
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
    await _faultData.add({
      "ref": refNum,
      "uid": _currentUser,
      "accountNumber": '',
      "address": addressFault,
      "faultType": dropdownValue,
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

    await _faultData.add({
      "ref": refNum,
      "uid": _currentUser,
      "accountNumber": '',
      "address": addressFault,
      "faultType": dropdownValue,
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

  ///Modal for adding fault report to property since address and details not needed,
  ///a check is also made beforehand if the property has outstanding bill and blocks unpaid bill property fault reporting
  // Future<void> _addNewFaultReport() async {
  //   await showModalBottomSheet(
  //       isScrollControlled: true,
  //       context: context,
  //       builder: (BuildContext ctx) {
  //         return SingleChildScrollView(
  //           child: Padding(
  //             padding: EdgeInsets.only(
  //                 top: 20,
  //                 left: 20,
  //                 right: 20,
  //                 bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 DropdownButtonFormField<String>(
  //                   value: dropdownValue,
  //                   items: <String>[
  //                     'Select Fault Type',
  //                     'Water & Sanitation',
  //                     'Roadworks',
  //                     'Waste Management'
  //                   ].map<DropdownMenuItem<String>>((String value) {
  //                     return DropdownMenuItem<String>(
  //                       value: value,
  //                       child: Text(
  //                         value,
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                     );
  //                   }).toList(),
  //                   onChanged: (String? newValue) {
  //                     setState(() {
  //                       dropdownValue = newValue!;
  //                       // Reset the fault description controller if a new fault type is selected
  //                       if (dropdownValue != 'Water & Sanitation') {
  //                         _faultDescriptionController.text = '';
  //                       }
  //                     });
  //                   },
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 // Show dropdown for fault description if 'Water & Sanitation' is selected
  //                 dropdownValue == 'Water & Sanitation'
  //                     ? DropdownButtonFormField<String>(
  //                   value: faultDescriptionValue,
  //                   items: <String>[
  //                     'Select Fault Description',
  //                     'Leakage',
  //                     'Burst pipe',
  //                     'Clogged storm drains/pipes',
  //                     'No water'
  //                   ].map<DropdownMenuItem<String>>((String description) {
  //                     return DropdownMenuItem<String>(
  //                       value: description,
  //                       child: Text(
  //                         description,
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                     );
  //                   }).toList(),
  //                   onChanged: (String? newValue) {
  //                     setState(() {
  //                       faultDescriptionValue = newValue!;
  //                       _faultDescriptionController.text =
  //                       faultDescriptionValue ==
  //                           'Select Fault Description'
  //                           ? ''
  //                           : faultDescriptionValue;
  //                     });
  //                   },
  //                   decoration: InputDecoration(
  //                     labelText: 'Select Fault Description',
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(10),
  //                     ),
  //                   ),
  //                 )
  //                     : TextField(
  //                   controller: _faultDescriptionController,
  //                   decoration: const InputDecoration(
  //                       labelText: 'Fault Description'),
  //                 ),
  //                 const SizedBox(height: 20),
  //
  //                 Center(
  //                   child: Row(
  //                     children: [
  //                       ElevatedButton(
  //                         child: const Text('Report'),
  //                         onPressed: () async {
  //                           showDialog(
  //                               barrierDismissible: false,
  //                               context: context,
  //                               builder: (context) {
  //                                 return AlertDialog(
  //                                   shape: const RoundedRectangleBorder(
  //                                       borderRadius: BorderRadius.all(
  //                                           Radius.circular(16))),
  //                                   title: const Text("Submit Fault"),
  //                                   content: const Text(
  //                                       "To add a photo to your property fault report go to your Current Reports tab to upload or update your fault image."),
  //                                   actions: [
  //                                     IconButton(
  //                                       onPressed: () {
  //                                         Navigator.of(context).pop();
  //                                       },
  //                                       icon: const Icon(
  //                                         Icons.cancel,
  //                                         color: Colors.red,
  //                                       ),
  //                                     ),
  //                                     IconButton(
  //                                       onPressed: () async {
  //                                         DateTime now = DateTime.now();
  //                                         String formattedDate = DateFormat(
  //                                             'yyyy-MM-dd – kk:mm')
  //                                             .format(now);
  //
  //                                         final String uid = _currentUser;
  //                                         String accountNumber = accountPass;
  //                                         String addressFault = addressPass;
  //                                         final String faultDescription =
  //                                             _faultDescriptionController.text;
  //                                         String faultType = dropdownValue;
  //                                         final String refNum =
  //                                         UniqueKey().toString();
  //
  //                                         if (faultType != 'Select Fault Type') {
  //                                           if (faultDescription != '') {
  //                                             if (uid == _currentUser) {
  //                                               await _faultData.add({
  //                                                 "ref": refNum,
  //                                                 "uid": _currentUser,
  //                                                 "accountNumber":
  //                                                 accountNumber,
  //                                                 "address": addressFault,
  //                                                 "faultType": faultType,
  //                                                 "reporterContact": userPhone,
  //                                                 "departmentSwitchComment": '',
  //                                                 "reallocationComment": '',
  //                                                 "attendeeAllocated": '',
  //                                                 "managerAllocated": '',
  //                                                 "adminComment": '',
  //                                                 "attendeeCom1": '',
  //                                                 "attendeeCom2": '',
  //                                                 "attendeeCom3": '',
  //                                                 "managerCom1": '',
  //                                                 "managerCom2": '',
  //                                                 "managerCom3": '',
  //                                                 "managerReturnCom": '',
  //                                                 "attendeeReturnCom": '',
  //                                                 "faultDescription":
  //                                                 faultDescription,
  //                                                 "depAllocated": '',
  //                                                 "faultResolved": false,
  //                                                 "dateReported": formattedDate,
  //                                                 "faultStage": 1,
  //                                               });
  //                                             }
  //                                             _addressController.text = '';
  //                                             _faultDescriptionController.text =
  //                                             '';
  //                                             dropdownValue =
  //                                             'Select Fault Type';
  //
  //                                             Fluttertoast.showToast(
  //                                               msg:
  //                                               "Fault has been reported successfully!",
  //                                               gravity: ToastGravity.CENTER,
  //                                             );
  //
  //                                             if (context.mounted)
  //                                               Navigator.of(context).pop();
  //                                             Get.back();
  //                                           } else {
  //                                             Fluttertoast.showToast(
  //                                               msg:
  //                                               "Please Give A Fault Description!",
  //                                               gravity: ToastGravity.CENTER,
  //                                             );
  //                                           }
  //                                         } else {
  //                                           Fluttertoast.showToast(
  //                                             msg:
  //                                             "Please Select Fault Type being Reported!!",
  //                                             gravity: ToastGravity.CENTER,
  //                                           );
  //                                         }
  //                                       },
  //                                       icon: const Icon(
  //                                         Icons.done,
  //                                         color: Colors.green,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 );
  //                               });
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         );
  //       });
  // }
  Future<void> _addNewFaultReport() async {
    // Reset the dropdown and controller before opening the dialog to ensure it's reset correctly
    setState(() {
      dropdownValue = 'Select Fault Type'; // Reset fault type dropdown
      faultDescriptionValue =
          'Select Fault Description'; // Reset fault description
      _faultDescriptionController.text =
          ''; // Clear the fault description controller
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
            "Report Fault",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown for Fault Type
                    DropdownButtonFormField<String>(
                      value: dropdownValue,
                      items: <String>[
                        'Select Fault Type',
                        'Water & Sanitation',
                        'Roadworks',
                        'Waste Management'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          dropdownValue = newValue!;
                          // Reset fault description controller if the selected type is not 'Water & Sanitation'
                          if (dropdownValue != 'Water & Sanitation') {
                            _faultDescriptionController.text = '';
                            faultDescriptionValue =
                            'Select Fault Description'; // Reset the dropdown
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Show dropdown for fault description only if 'Water & Sanitation' is selected
                    dropdownValue == 'Water & Sanitation'
                        ? DropdownButtonFormField<String>(
                      value: faultDescriptionValue,
                      items: <String>[
                        'Select Fault Description',
                        'Leakage',
                        'Burst pipe',
                        'Clogged storm drains/pipes',
                        'No water'
                      ].map<DropdownMenuItem<String>>((String description) {
                        return DropdownMenuItem<String>(
                          value: description,
                          child: Text(
                            description,
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          faultDescriptionValue = newValue!;
                          _faultDescriptionController.text =
                          faultDescriptionValue ==
                              'Select Fault Description'
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
                    )
                        : TextField(
                      controller: _faultDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Fault Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
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
              onPressed: () {
                // Confirmation dialog to ask for submission and notify the user about adding a photo
                showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16))),
                      title: const Text("Submit Fault"),
                      content: const Text(
                          "To add a photo to your property fault report, go to your Current Reports tab to upload or update your fault image."),
                      actions: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Cancel the confirmation
                          },
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            DateTime now = DateTime.now();
                            String formattedDate =
                            DateFormat('yyyy-MM-dd – kk:mm').format(now);

                            final String uid = _currentUser;
                            String accountNumber = accountPass;
                            String addressFault = addressPass;
                            final String faultDescription =
                                _faultDescriptionController.text;
                            String faultType = dropdownValue;
                            final String refNum = UniqueKey().toString();

                            if (faultType != 'Select Fault Type' &&
                                faultDescription.isNotEmpty) {
                              if (uid == _currentUser) {
                                await _faultData.add({
                                  "ref": refNum,
                                  "uid": _currentUser,
                                  "accountNumber": accountNumber,
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
                                dropdownValue = 'Select Fault Type';

                                Fluttertoast.showToast(
                                  msg: "Fault has been reported successfully!",
                                  gravity: ToastGravity.CENTER,
                                );

                                Navigator.of(context)
                                    .pop(); // Close the confirmation dialog
                                Navigator.of(context)
                                    .pop(); // Close the fault reporting dialog
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: "Please fill in all required fields.",
                                gravity: ToastGravity.CENTER,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.done,
                            color: Colors.green,
                          ),
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
}
