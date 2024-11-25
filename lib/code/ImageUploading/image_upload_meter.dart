// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
// import 'package:intl/intl.dart';
// import 'package:mime/mime.dart';
// import 'package:path/path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class ImageUploadMeter extends StatefulWidget {
//   const ImageUploadMeter({
//     super.key, required this.userNumber, required this.meterNumber,this.municipalityUserEmail,
//   });
//
//   final String userNumber;
//   final String meterNumber;
//   final String? municipalityUserEmail;
//
//
//   @override
//   _ImageUploadMeterState createState() => _ImageUploadMeterState();
// }
// final FirebaseAuth auth = FirebaseAuth.instance;
// DateTime now = DateTime.now();
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final email = user?.email;
// String userID = uid as String;
// String userEmail = email as String;
//
// class _ImageUploadMeterState extends State<ImageUploadMeter> {
//   String? userEmail;
//   String districtId='';
//   String municipalityId='';
//
//   firebase_storage.FirebaseStorage storage =
//       firebase_storage.FirebaseStorage.instance;
//   @override
//   void initState() {
//     super.initState();
//     fetchUserDetails().then((_) {
//       validateProperty();
//       fetchPropertyDetails();
//     });
//
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   Future<void> fetchUserDetails() async {
//     try {
//       User? user = FirebaseAuth.instance.currentUser;
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
//
//       if (user != null) {
//         if (user.email != null && user.email!.isNotEmpty) {
//           // Municipality user (logged in with email)
//           userEmail = user.email;
//
//           QuerySnapshot userSnapshot = await FirebaseFirestore.instance
//               .collectionGroup('users')
//               .where('email', isEqualTo: userEmail)
//               .limit(1)
//               .get();
//
//           if (userSnapshot.docs.isNotEmpty) {
//             var userDoc = userSnapshot.docs.first;
//
//             districtId = userDoc.reference.parent.parent!.parent.id;
//             municipalityId = userDoc.reference.parent.parent!.id;
//           }
//         } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
//           // Regular user (logged in with phone number)
//           String userPhoneNumber = user.phoneNumber!;
//
//           if (selectedPropertyAccountNumber != null) {
//             QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
//                 .collectionGroup('properties')
//                 .where('cellNumber', isEqualTo: userPhoneNumber)
//                 .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)
//                 .limit(1)
//                 .get();
//
//             if (propertySnapshot.docs.isNotEmpty) {
//               var propertyDoc = propertySnapshot.docs.first;
//
//               // Firestore path traversal to get districtId and municipalityId
//               final propertyRef = propertyDoc.reference;
//               final municipalityRef = propertyRef.parent.parent; // Move two levels up to get the municipality
//               final districtRef = municipalityRef?.parent?.parent; // Move up again to get the district
//
//               if (municipalityRef != null && districtRef != null) {
//                 districtId = districtRef.id;  // Get districtId
//                 municipalityId = municipalityRef.id;  // Get municipalityId
//
//                 setState(() {
//                   propertyAddress = propertyDoc['address'].replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
//                 });
//
//                 print("Regular user: District - $districtId, Municipality - $municipalityId");
//               } else {
//                 print("Error: Unable to determine district or municipality from Firestore references.");
//               }
//             } else {
//               print('No property found with the selected account number.');
//             }
//           } else {
//             print('Selected property account number is not available.');
//           }
//         }
//       }
//       setState(() {
//         // Finalize the loading state
//       });
//     } catch (e) {
//       print('Error fetching user details: $e');
//       setState(() {
//         // Handle error state
//       });
//     }
//   }
//
//
//
//   String formattedDate = DateFormat.MMMM().format(now);
//   String? propertyAddress;
//   String dropdownValue = 'Select Month';
//   List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];
//
//   final GlobalKey<ScaffoldState> _key = GlobalKey();
//   File? _photo;
//   final ImagePicker _picker = ImagePicker();
//
//   Future<bool> validateProperty() async {
//     if (districtId.isEmpty || municipalityId.isEmpty) {
//       print('Validation skipped: districtId or municipalityId is empty.');
//       return false;  // Skip validation if these values are not set
//     }
//
//     try {
//       var propertyQuery = await FirebaseFirestore.instance
//           .collection('districts')
//           .doc(districtId)
//           .collection('municipalities')
//           .doc(municipalityId)
//           .collection('properties')
//           .where('cellNumber', isEqualTo: widget.userNumber)
//           .where('meter_number', isEqualTo: widget.meterNumber)
//           .limit(1)
//           .get();
//
//       return propertyQuery.docs.isNotEmpty;
//     } catch (e) {
//       print('Error validating property: $e');
//       return false;
//     }
//   }
//
//
//
//   Future<void> fetchPropertyDetails() async {
//     try {
//       // Use the selected property account number from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
//
//       // Make sure selectedPropertyAccountNumber is not null
//       if (selectedPropertyAccountNumber != null) {
//         var propertyQuery = await FirebaseFirestore.instance
//             .collectionGroup('properties')
//             .where('accountNumber', isEqualTo: selectedPropertyAccountNumber)  // Filter by account number
//             .where('meter_number', isEqualTo: widget.meterNumber)  // Filter by meter number
//             .limit(1)
//             .get();
//
//         if (propertyQuery.docs.isNotEmpty) {
//           var propertyData = propertyQuery.docs.first.data();
//           setState(() {
//             propertyAddress = propertyData['address']
//                 .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_')
//                 .replaceAll(' ', '_');  // Properly format the address
//           });
//           print("Correct property address fetched: $propertyAddress");
//         } else {
//           print("No property found matching account number: $selectedPropertyAccountNumber and meter number: ${widget.meterNumber}");
//         }
//       } else {
//         print('Selected property account number is not available.');
//       }
//     } catch (e) {
//       print('Error fetching property details: $e');
//     }
//   }
//
//
//   Future imgFromGallery() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60,);
//
//     setState(() {
//       if (pickedFile != null) {
//         _photo = File(pickedFile.path);
//        // uploadFile();
//       } else {
//         print('No image selected.');
//       }
//     });
//   }
//
//   Future imgFromCamera() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 60,);
//
//     setState(() {
//       if (pickedFile != null) {
//         _photo = File(pickedFile.path);
//        // uploadFile();
//       } else {
//         print('No image selected.');
//       }
//     });
//   }
//
//
//   Future<void> ensureDocumentExists(String districtId, String municipalityId, String userNumber, String propertyAddress) async {
//     DocumentReference actionLogRef = FirebaseFirestore.instance
//         .collection('districts')
//         .doc(districtId)
//         .collection('municipalities')
//         .doc(municipalityId)
//         .collection('actionLogs')
//         .doc(userNumber)
//         .collection(propertyAddress)
//         .doc();
//
//     await actionLogRef.set(
//       {'created': FieldValue.serverTimestamp()},
//       SetOptions(merge: true),
//     );
//   }
//
//   Future<void> logEMeterUploadAction(
//       String fileUrl,
//       String actionType,
//       String userNumber,
//       String propertyAddress,
//       String? municipalityUserEmail
//       ) async {
//
//     String uploaderInfo = municipalityUserEmail ?? userNumber;
//
//     await ensureDocumentExists(districtId, municipalityId, userNumber, propertyAddress);
//
//     // Action log reference
//     DocumentReference actionLogRef = FirebaseFirestore.instance
//         .collection('districts')
//         .doc(districtId)
//         .collection('municipalities')
//         .doc(municipalityId)
//         .collection('actionLogs')
//         .doc(userNumber)
//         .collection(propertyAddress)
//         .doc();    // Auto-generate document ID for each action
//
//     // Add the meter image upload action
//     await actionLogRef.set({
//       'actionType': actionType,
//       'uploader': uploaderInfo,
//       'fileUrl': fileUrl,
//       'propertyAddress': propertyAddress,
//       'timestamp': FieldValue.serverTimestamp(),
//       'description': '$uploaderInfo uploaded a new electricity meter image for property $propertyAddress',
//     });
//   }
//
//
//   Future uploadFile() async {
//     if (_photo == null) {
//       print('No image selected.');
//       return;
//     }
//
//     // Ensure the user details (districtId, municipalityId) are fetched before proceeding
//     await fetchUserDetails();
//
//     // Ensure the property details are fetched before proceeding
//     if (propertyAddress == null) {
//       await fetchPropertyDetails();
//     }
//
//     final String fileName = '${widget.meterNumber}.jpg';
//     final String destination = 'files/meters/$formattedDate/${widget.userNumber}/$propertyAddress/electricity/$fileName';
//
//     try {
//       final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
//       final mimeType = lookupMimeType(_photo!.path) ?? 'application/octet-stream';
//       final metadata = firebase_storage.SettableMetadata(contentType: mimeType);
//
//       await ref.putFile(_photo!, metadata);
//       String fileUrl = await ref.getDownloadURL();
//       print('Image uploaded successfully to: $destination');
//       print('File URL: $fileUrl');
//
//       await logEMeterUploadAction(fileUrl, "Upload Electricity Meter Image", widget.userNumber, propertyAddress!, widget.municipalityUserEmail);
//     } catch (e) {
//       print('Error uploading image: $e');
//     }
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Electricity Meter Reading Upload',style: TextStyle(color: Colors.white),),
//         backgroundColor: Colors.green,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             const SizedBox(height: 100,),
//             Center(
//               child: GestureDetector(
//                 onTap: () {
//                   _showPicker(context);
//                 },
//                 child: CircleAvatar(
//                   radius: 180,
//                   backgroundColor: Colors.grey[400],
//                   child: _photo != null ? ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.file(
//                       _photo!,
//                       width: 250,
//                       height: 250,
//                       fit: BoxFit.cover,
//                     ),
//                   )
//                       : Container(
//                     decoration: BoxDecoration(
//                         color: Colors.grey[200],
//                         borderRadius: BorderRadius.circular(10)), width: 250, height: 250,
//                     child: Icon(Icons.camera_alt, color: Colors.grey[800],),
//                   ),
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 100,),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 25.0),
//               child: GestureDetector(
//                 onTap: () {
//                   if (_photo != null) {
//                   //  uploadFile();
//                     uploadFile().then((_) {
//                       Navigator.popUntil(context, (route) => route.isFirst); // Pop to the first screen
//                     });
//
//                     Fluttertoast.showToast(msg: "Successfully Uploaded!\nElectric Meter Image!");
//
//                     // Navigator.of(context).pop(context);
//                     // Navigator.of(context).pop(context);
//                     // Navigator.of(context).pop(context);
//                   } else {
//                     Fluttertoast.showToast(msg: "Please tap on the image area\nand select the image to upload!");
//                   }
//                 },
//
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.green,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Center(
//                     child: Text(
//                       'Upload Image',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10,),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showPicker(context) {
//     showModalBottomSheet(
//         context: context,
//         builder: (BuildContext bc) {
//           return SafeArea(
//             child: Container(
//               child: Wrap(
//                 children: <Widget>[
//                   ListTile(
//                       leading: Icon(Icons.photo_library),
//                       title: Text('Gallery'),
//                       onTap: () {
//                         imgFromGallery();
//                         Navigator.of(context).pop();
//                       }),
//                   ListTile(
//                     leading: Icon(Icons.photo_camera),
//                     title: Text('Camera'),
//                     onTap: () {
//                       imgFromCamera();
//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         });
//   }
// }