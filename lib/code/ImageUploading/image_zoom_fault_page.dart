import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:municipal_services/code/ImageUploading/image_upload_fault.dart';
import 'package:municipal_services/code/MapTools/map_screen_prop.dart';
import 'package:municipal_services/code/MapTools/map_screen.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';

class ImageZoomFaultPage extends StatefulWidget {
  const ImageZoomFaultPage({
    super.key,
    required this.imageName,
    required this.dateReported, required this.isLocalMunicipality, required this.districtId, required this.municipalityId, required this.isLocalUser,
  });

  final String imageName;
  final String dateReported;
  final bool isLocalMunicipality; // New property
  final String districtId; // Required for district municipalities
  final String municipalityId;
  final bool isLocalUser;
  @override
  _ImageZoomFaultPageState createState() => _ImageZoomFaultPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String phoneNum = phone as String;
DateTime now = DateTime.now();

String accountNumber = ' ';
String locationGiven = ' ';
String eMeterNumber = ' ';
String accountNumberW = ' ';
String locationGivenW = ' ';
String wMeterNumber = ' ';

String propPhoneNum = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

bool imgUploadCheck = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    try {
      print('Loading image from Firebase Storage: $image');
      return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
    } catch (e) {
      print('Error loading image from Firebase Storage: $e');
      throw Exception('Failed to load image');
    }
  }
}


class _ImageZoomFaultPageState extends State<ImageZoomFaultPage> {
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality = false;


  @override
  void initState() {
    super.initState();
    print("ImageZoomFaultPage initialized with:");
    print("Image Name: ${widget.imageName}");
    print("Date Reported: ${widget.dateReported}");
    print("isLocalMunicipality: ${widget.isLocalMunicipality}");
    print("District ID: ${widget.districtId}");
    print("Municipality ID: ${widget.municipalityId}");
    print("isLocalUser: ${widget.isLocalUser}");
    // Fetch municipality details to determine if the property belongs to a local or district municipality.
    fetchMunicipalityDetails();
    print("fetchMunicipalityDetails fetched");
  }


  Future<void> fetchMunicipalityDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userEmail = user.email ?? '';
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: userEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;

          setState(() {
            municipalityId = userDoc['municipalityId'] ?? '';
            isLocalMunicipality = userDoc['isLocalMunicipality'] ?? false;
            districtId = userDoc['districtId'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching municipality details: $e');
    }
  }


  String formattedMonth =
      DateFormat.MMMM().format(now); //format for full Month by name
  String formattedDateMonth =
      DateFormat.MMMMd().format(now); //format for Day Month only

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = [
    'Select Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  final CollectionReference _propList =
      FirebaseFirestore.instance.collection('properties');

  String reporterCellGiven = '';
  String reporterDateGiven = '';
  String accountNumberRep = '';
  String locationGivenRep = '';
  bool imageVisibility = true;

  Future<String> _getImageUrl(BuildContext context, String dateReported, String address) async {
    print("starting getImageUrl");
    try {
      // Construct the correct image path (with no duplication)
      String imagePath = 'files/faultImages/$dateReported/$address.jpg'; // Ensure no extra 'files/faultImages/' is added

      // Print the constructed image path to check if it's correct
      print('Attempting to load image from path: $imagePath');

      // Load the image URL from Firebase Storage
      final imageUrl = await FireStorageService.loadImage(context, imagePath);

      // Print the image URL to verify it's correct
      print('Image URL retrieved: $imageUrl');

      return imageUrl; // Return the URL, not the widget
    } catch (e) {
      // Print any errors encountered
      print('Error occurred while loading image: $e');
      throw Exception('Image not available');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.municipalityId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Print out the Firestore paths
    final CollectionReference _faultData = widget.isLocalMunicipality
        ? FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(widget.municipalityId)
        .collection('faultReporting')
        : FirebaseFirestore.instance
        .collection('districts')
        .doc(widget.districtId)
        .collection('municipalities')
        .doc(widget.municipalityId)
        .collection('faultReporting');

    print('Firestore path: ${_faultData.path}');

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Fault Image', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder<QuerySnapshot>(
          future: _faultData.get(),  // Instead of using snapshots(), fetch data directly
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              print('Fetching data from Firestore...');
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('Error fetching data: ${snapshot.error}');
              return const Center(
                child: Text('Error fetching data'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('No matching faults found');
              return const Center(
                child: Text('No matching faults found.'),
              );
            }

            // Finding matching documents based on the date reported
            List<DocumentSnapshot> matchingDocs = snapshot.data!.docs.where((doc) {
              if (doc['dateReported'] is Timestamp) {
                Timestamp faultTimestamp = doc['dateReported'];
                String formattedFaultDate = DateFormat('yyyy-MM-dd HH:mm').format(faultTimestamp.toDate());
                return formattedFaultDate == widget.dateReported;
              } else if (doc['dateReported'] is String) {
                return doc['dateReported'] == widget.dateReported;
              }
              return false;
            }).toList();

            if (matchingDocs.isEmpty) {
              print('No documents matched the date reported');
              return const Center(
                child: Text('No matching fault found.'),
              );
            }

            // Now we display the first matching document
            DocumentSnapshot documentSnapshot = matchingDocs.first;
            String status = documentSnapshot['faultResolved'] ? "Completed" : "Pending";

            return SingleChildScrollView(
              child: Card(
                margin: const EdgeInsets.all(10.0),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'Fault ${documentSnapshot['ref']}',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Street Address of Fault: ${documentSnapshot['address']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Fault Type: ${documentSnapshot['faultType']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      if (documentSnapshot['faultDescription'] != "")
                        Text(
                          'Fault Description: ${documentSnapshot['faultDescription']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      const SizedBox(height: 5),
                      Text(
                        'Resolve State: $status',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Date of Fault Report: ${documentSnapshot['dateReported']}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: 10),

                      // The image loading part
                      FutureBuilder<String>(
                        future: _getImageUrl(context, widget.dateReported, widget.imageName),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError || !snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('Image not available for this fault.'),
                            );
                          } else {
                            return Container(
                              width: double.infinity,
                              height: 500,
                              child: Image.network(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }




  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Colors.grey[350],
  //     appBar: AppBar(
  //       title: const Text('Fault Image', style: TextStyle(color: Colors.white)),
  //       backgroundColor: Colors.green,
  //       iconTheme: const IconThemeData(color: Colors.white),
  //     ),
  //     body: Padding(
  //       padding: const EdgeInsets.fromLTRB(0.0, 5.0, 0.0, 5.0),
  //       child: StreamBuilder<QuerySnapshot>(
  //         stream: _faultData.orderBy('dateReported', descending: true).snapshots(),
  //         builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
  //           if (streamSnapshot.hasData) {
  //             return ListView.builder(
  //               itemCount: streamSnapshot.data!.docs.length,
  //               itemBuilder: (context, index) {
  //                 final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
  //                 String status = documentSnapshot['faultResolved'] == false ? "Pending" : "Completed";
  //
  //                 if (documentSnapshot['dateReported'] == widget.dateReported) {
  //                   return Card(
  //                     margin: const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
  //                     child: Padding(
  //                       padding: const EdgeInsets.all(20.0),
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Center(
  //                             child: Text(
  //                               'Fault ${documentSnapshot['ref']}',
  //                               style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
  //                             ),
  //                           ),
  //                           const SizedBox(height: 10),
  //                           Text(
  //                             'Street Address of Fault: ${documentSnapshot['address']}',
  //                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                           ),
  //                           const SizedBox(height: 5),
  //                           Text(
  //                             'Fault Type: ${documentSnapshot['faultType']}',
  //                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                           ),
  //                           const SizedBox(height: 5),
  //                           Column(
  //                             children: [
  //                               if (documentSnapshot['faultDescription'] != "") ...[
  //                                 Text(
  //                                   'Fault Description: ${documentSnapshot['faultDescription']}',
  //                                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                                 ),
  //                                 const SizedBox(height: 5),
  //                               ],
  //                             ],
  //                           ),
  //                           Text(
  //                             'Resolve State: $status',
  //                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                           ),
  //                           const SizedBox(height: 5),
  //                           Text(
  //                             'Date of Fault Report: ${documentSnapshot['dateReported']}',
  //                             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
  //                           ),
  //                           const SizedBox(height: 5),
  //                           Column(
  //                             children: [
  //                               if (documentSnapshot['faultDescription'] != "") ...[
  //                                 Visibility(
  //                                   visible: imageVisibility,
  //                                   child: InkWell(
  //                                     child: Container(
  //                                       margin: const EdgeInsets.only(bottom: 5),
  //                                       child: Center(
  //                                         child: Card(
  //                                           color: Colors.grey,
  //                                           semanticContainer: true,
  //                                           clipBehavior: Clip.antiAliasWithSaveLayer,
  //                                           shape: RoundedRectangleBorder(
  //                                             borderRadius: BorderRadius.circular(10.0),
  //                                           ),
  //                                           elevation: 0,
  //                                           margin: const EdgeInsets.all(10.0),
  //                                           child: FutureBuilder(
  //                                             future: _getImage(context, 'files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}'),
  //                                             builder: (context, snapshot) {
  //                                               // Log the image path and snapshot state
  //                                               print('Fetching image from path: files/faultImages/${documentSnapshot['dateReported']}/${documentSnapshot['address']}');
  //                                               print('Snapshot ConnectionState: ${snapshot.connectionState}');
  //
  //                                               if (snapshot.connectionState == ConnectionState.waiting) {
  //                                                 return const Center(
  //                                                   child: CircularProgressIndicator(),
  //                                                 );
  //                                               } else if (snapshot.hasError) {
  //                                                 print('Error loading image: ${snapshot.error}');
  //                                                 return const Padding(
  //                                                   padding: EdgeInsets.all(20.0),
  //                                                   child: Text('Image not uploaded for this fault.'),
  //                                                 );
  //                                               } else if (!snapshot.hasData) {
  //                                                 print('No image data found.');
  //                                                 return const Padding(
  //                                                   padding: EdgeInsets.all(20.0),
  //                                                   child: Text('Image not uploaded for this fault.'),
  //                                                 );
  //                                               } else {
  //                                                 print('Image loaded successfully.');
  //                                                 return Container(
  //                                                   child: snapshot.data!,
  //                                                 );
  //                                               }
  //                                             },
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     ),
  //                                   ),
  //                                 ),
  //
  //                               ],
  //                             ],
  //                           ),
  //                           const SizedBox(height: 0),
  //                           Center(
  //                             child: Column(
  //                               mainAxisAlignment: MainAxisAlignment.center,
  //                               crossAxisAlignment: CrossAxisAlignment.center,
  //                               children: [
  //                                 Row(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   crossAxisAlignment: CrossAxisAlignment.center,
  //                                   children: [
  //                                     BasicIconButtonGreen(
  //                                       onPress: () {
  //                                         accountNumberRep = documentSnapshot['accountNumber'];
  //                                         locationGivenRep = documentSnapshot['address'];
  //
  //                                         Navigator.push(
  //                                           context,
  //                                           MaterialPageRoute(
  //                                             builder: (context) => MapScreenProp(
  //                                               propAddress: locationGivenRep,
  //                                               propAccNumber: accountNumberRep,
  //                                             ),
  //                                           ),
  //                                         );
  //                                       },
  //                                       labelText: 'Location',
  //                                       fSize: 14,
  //                                       faIcon: const FaIcon(Icons.map),
  //                                       fgColor: Colors.purple,
  //                                       btSize: const Size(40, 40),
  //                                     ),
  //                                     BasicIconButtonGreen(
  //                                       onPress: () {
  //                                         locationGivenRep = documentSnapshot['address'];
  //                                         reporterDateGiven = documentSnapshot['dateReported'];
  //                                         Navigator.push(
  //                                           context,
  //                                           MaterialPageRoute(
  //                                             builder: (context) => FaultImageUpload(
  //                                               propertyAddress: locationGivenRep,
  //                                               reportedDate: reporterDateGiven,
  //                                             ),
  //                                           ),
  //                                         );
  //                                       },
  //                                       labelText: 'Image +',
  //                                       fSize: 14,
  //                                       faIcon: const FaIcon(Icons.photo_camera),
  //                                       fgColor: Colors.blueGrey,
  //                                       btSize: const Size(40, 40),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ],
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 } else {
  //                   return const SizedBox();
  //                 }
  //               },
  //             );
  //           }
  //           return const Padding(
  //             padding: EdgeInsets.all(10.0),
  //             child: Center(
  //               child: Card(
  //                 margin: EdgeInsets.all(10),
  //                 child: Center(
  //                   child: Padding(
  //                     padding: EdgeInsets.all(8.0),
  //                     child: Text(
  //                       'No Faults Reported Yet',
  //                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  void setMonthLimits(String currentMonth) {
    String month1 = 'January';
    String month2 = 'February';
    String month3 = 'March';
    String month4 = 'April';
    String month5 = 'May';
    String month6 = 'June';
    String month7 = 'July';
    String month8 = 'August';
    String month9 = 'September';
    String month10 = 'October';
    String month11 = 'November';
    String month12 = 'December';

    if (currentMonth.contains(month1)) {
      dropdownMonths = [
        'Select Month',
        month10,
        month11,
        month12,
        currentMonth,
      ];
    } else if (currentMonth.contains(month2)) {
      dropdownMonths = [
        'Select Month',
        month11,
        month12,
        month1,
        currentMonth,
      ];
    } else if (currentMonth.contains(month3)) {
      dropdownMonths = [
        'Select Month',
        month12,
        month1,
        month2,
        currentMonth,
      ];
    } else if (currentMonth.contains(month4)) {
      dropdownMonths = [
        'Select Month',
        month1,
        month2,
        month3,
        currentMonth,
      ];
    } else if (currentMonth.contains(month5)) {
      dropdownMonths = [
        'Select Month',
        month2,
        month3,
        month4,
        currentMonth,
      ];
    } else if (currentMonth.contains(month6)) {
      dropdownMonths = [
        'Select Month',
        month3,
        month4,
        month5,
        currentMonth,
      ];
    } else if (currentMonth.contains(month7)) {
      dropdownMonths = [
        'Select Month',
        month4,
        month5,
        month6,
        currentMonth,
      ];
    } else if (currentMonth.contains(month8)) {
      dropdownMonths = [
        'Select Month',
        month5,
        month6,
        month7,
        currentMonth,
      ];
    } else if (currentMonth.contains(month9)) {
      dropdownMonths = [
        'Select Month',
        month6,
        month7,
        month8,
        currentMonth,
      ];
    } else if (currentMonth.contains(month10)) {
      dropdownMonths = [
        'Select Month',
        month7,
        month8,
        month9,
        currentMonth,
      ];
    } else if (currentMonth.contains(month11)) {
      dropdownMonths = [
        'Select Month',
        month8,
        month9,
        month10,
        currentMonth,
      ];
    } else if (currentMonth.contains(month12)) {
      dropdownMonths = [
        'Select Month',
        month9,
        month10,
        month11,
        currentMonth,
      ];
    } else {
      dropdownMonths = [
        'Select Month',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
    }
  }

  ///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  void openPDF(BuildContext context, File file) => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
      );
}
