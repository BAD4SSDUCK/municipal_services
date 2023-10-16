// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:municipal_tracker_msunduzi/code/Models/property.dart';
//
// import '../ImageUploading/image_upload_meter.dart';
// import '../ImageUploading/image_upload_water.dart';
// import '../MapTools/map_screen_prop.dart';
// import '../PDFViewer/pdf_api.dart';
// import 'icon_elevated_button.dart';
// import 'nav_drawer.dart';
//
//
// String accountNumberAll = ' ';
// String locationGivenAll = ' ';
// String eMeterNumber = ' ';
// String accountNumberW = ' ';
// String locationGivenW = ' ';
// String wMeterNumber = ' ';
// String propPhoneNum = ' ';
//
//
//
// Widget buildPropertyCard(BuildContext context, CollectionReference<Object?> propertiesDataStream) {
//
//   final property = Property.fromSnapshot(document);
//   final propertyAddress = Property.address();
//
//   return Expanded(
//     child: StreamBuilder<QuerySnapshot>(
//       stream: propertiesDataStream.snapshots(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
//         if (streamSnapshot.hasData) {
//           return ListView.builder(
//             ///this call is to display all details for all users but is only displaying for the current user account.
//             ///it can be changed to display all users for the staff to see if the role is set to all later on.
//             itemCount: streamSnapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final DocumentSnapshot documentSnapshot =
//               streamSnapshot.data!.docs[index];
//
//               eMeterNumber = documentSnapshot['meter number'];
//               wMeterNumber = documentSnapshot['water meter number'];
//               propPhoneNum = documentSnapshot['cell number'];
//
//               String billMessage;///A check for if payment is outstanding or not
//               if(documentSnapshot['eBill'] != '' ||
//                   documentSnapshot['eBill'] != 'R0,000.00' ||
//                   documentSnapshot['eBill'] != 'R0.00' ||
//                   documentSnapshot['eBill'] != 'R0' ||
//                   documentSnapshot['eBill'] != '0'
//               ){
//                 billMessage = 'Utilities bill outstanding: ${documentSnapshot['eBill']}';
//               } else {
//                 billMessage = 'No outstanding payments';
//               }
//
//               if(((documentSnapshot['address'].trim()).toLowerCase()).contains((_searchBarController.text.trim()).toLowerCase())){
//                 return Card(
//                   margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Center(
//                           child: Text(
//                             'Property Information',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                         const SizedBox(height: 10,),
//                         Text(
//                           'Account Number: ${documentSnapshot['account number']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Street Address: ${documentSnapshot['address']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Area Code: ${documentSnapshot['area code']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Meter Number: ${documentSnapshot['meter number']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Meter Reading: ${documentSnapshot['meter reading']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Water Meter Number: ${documentSnapshot['water meter number']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Water Meter Reading: ${documentSnapshot['water meter reading']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Phone Number: ${documentSnapshot['cell number']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'First Name: ${documentSnapshot['first name']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'Surname: ${documentSnapshot['last name']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 5,),
//                         Text(
//                           'ID Number: ${documentSnapshot['id number']}',
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         const SizedBox(height: 20,),
//
//                         const Center(
//                           child: Text(
//                             'Electricity Meter Reading Photo',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                         const SizedBox(height: 5,),
//                         Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     eMeterNumber = documentSnapshot['meter number'];
//                                     propPhoneNum = documentSnapshot['cell number'];
//                                     showDialog(
//                                         barrierDismissible: false,
//                                         context: context,
//                                         builder: (context) {
//                                           return AlertDialog(
//                                             title: const Text("Upload Electricity Meter"),
//                                             content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
//                                             actions: [
//                                               IconButton(
//                                                 onPressed: () {
//                                                   Navigator.pop(context);
//                                                 },
//                                                 icon: const Icon(
//                                                   Icons.cancel,
//                                                   color: Colors.red,
//                                                 ),
//                                               ),
//                                               IconButton(
//                                                 onPressed: () async {
//                                                   Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
//                                                   Navigator.push(context,
//                                                       MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
//                                                 },
//                                                 icon: const Icon(
//                                                   Icons.done,
//                                                   color: Colors.green,
//                                                 ),
//                                               ),
//                                             ],
//                                           );
//                                         });
//                                   },
//                                   labelText: 'Photo',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.camera_alt,),
//                                   fgColor: Colors.black38,
//                                   btSize: const Size(100, 38),
//                                 ),
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     _updateE(documentSnapshot);
//                                   },
//                                   labelText: 'Capture',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.edit,),
//                                   fgColor: Theme.of(context).primaryColor,
//                                   btSize: const Size(100, 38),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                         ///Image display item needs to get the reference from the firestore using the users uploaded meter connection
//                         InkWell(
//                           ///onTap allows to open image upload page if user taps on the image.
//                           ///Can be later changed to display the picture zoomed in if user taps on it.
//                           onTap: () {
//                             eMeterNumber = documentSnapshot['meter number'];
//                             propPhoneNum = documentSnapshot['cell number'];
//                             showDialog(
//                                 barrierDismissible: false,
//                                 context: context,
//                                 builder: (context) {
//                                   return AlertDialog(
//                                     title: const Text("Upload Electricity Meter"),
//                                     content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
//                                     actions: [
//                                       IconButton(
//                                         onPressed: () {
//                                           Navigator.pop(context);
//                                         },
//                                         icon: const Icon(
//                                           Icons.cancel,
//                                           color: Colors.red,
//                                         ),
//                                       ),
//                                       IconButton(
//                                         onPressed: () async {
//                                           Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
//                                           Navigator.push(context,
//                                               MaterialPageRoute(builder: (context) => ImageUploadMeter(userNumber: propPhoneNum, meterNumber: eMeterNumber,)));
//                                         },
//                                         icon: const Icon(
//                                           Icons.done,
//                                           color: Colors.green,
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 });
//                           },
//
//                           child: Center(
//                             child: Container(
//                               margin: const EdgeInsets.only(bottom: 5),
//                               // height: 300,
//                               // width: 300,
//                               child: Center(
//                                 child: Card(
//                                   color: Colors.grey,
//                                   semanticContainer: true,
//                                   clipBehavior: Clip.antiAliasWithSaveLayer,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                   ),
//                                   elevation: 0,
//                                   margin: const EdgeInsets.all(10.0),
//                                   child: FutureBuilder(
//                                       future: _getImage(
//                                         ///Firebase image location must be changed to display image based on the meter number
//                                           context, 'files/meters/$formattedDate/$propPhoneNum/electricity/$eMeterNumber.jpg'),
//                                       builder: (context, snapshot) {
//                                         if (snapshot.hasError) {
//                                           imgUploadCheck = false;
//                                           updateImgCheckE(imgUploadCheck,documentSnapshot);
//                                           return const Padding(
//                                             padding: EdgeInsets.all(20.0),
//                                             child: Column(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Text('Image not yet uploaded.',),
//                                                 SizedBox(height: 10,),
//                                                 FaIcon(Icons.camera_alt,),
//                                               ],
//                                             ),
//                                           );
//                                         }
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.done) {
//                                           // imgUploadCheck = true;
//                                           updateImgCheckE(imgUploadCheck,documentSnapshot);
//                                           return Column(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               SizedBox(
//                                                 height: 300,
//                                                 width: 300,
//                                                 child: snapshot.data,
//                                               ),
//                                             ],
//                                           );
//                                         }
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.waiting) {
//                                           return Container(
//                                             child: const CircularProgressIndicator(),);
//                                         }
//                                         return Container();
//                                       }
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10,),
//
//                         const Center(
//                           child: Text(
//                             'Water Meter Reading Photo',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                         const SizedBox(height: 5,),
//                         Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     wMeterNumber = documentSnapshot['water meter number'];
//                                     propPhoneNum = documentSnapshot['cell number'];
//                                     showDialog(
//                                         barrierDismissible: false,
//                                         context: context,
//                                         builder: (context) {
//                                           return AlertDialog(
//                                             title: const Text("Upload Water Meter"),
//                                             content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
//                                             actions: [
//                                               IconButton(
//                                                 onPressed: () {
//                                                   Navigator.pop(context);
//                                                 },
//                                                 icon: const Icon(
//                                                   Icons.cancel,
//                                                   color: Colors.red,
//                                                 ),
//                                               ),
//                                               IconButton(
//                                                 onPressed: () async {
//                                                   Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
//                                                   Navigator.push(context,
//                                                       MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
//                                                 },
//                                                 icon: const Icon(
//                                                   Icons.done,
//                                                   color: Colors.green,
//                                                 ),
//                                               ),
//                                             ],
//                                           );
//                                         });
//                                   },
//                                   labelText: 'Photo',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.camera_alt,),
//                                   fgColor: Colors.black38,
//                                   btSize: const Size(100, 38),
//                                 ),
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     _updateW(documentSnapshot);
//                                   },
//                                   labelText: 'Capture',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.edit,),
//                                   fgColor: Theme.of(context).primaryColor,
//                                   btSize: const Size(100, 38),
//                                 ),
//                               ],
//                             )
//                           ],
//                         ),
//                         InkWell(
//                           ///onTap allows to open image upload page if user taps on the image.
//                           ///Can be later changed to display the picture zoomed in if user taps on it.
//                           onTap: () {
//                             wMeterNumber = documentSnapshot['water meter number'];
//                             propPhoneNum = documentSnapshot['cell number'];
//                             showDialog(
//                                 barrierDismissible: false,
//                                 context: context,
//                                 builder: (context) {
//                                   return AlertDialog(
//                                     title: const Text("Upload Water Meter"),
//                                     content: const Text("Uploading a new image will replace current image!\n\nAre you sure?"),
//                                     actions: [
//                                       IconButton(
//                                         onPressed: () {
//                                           Navigator.pop(context);
//                                         },
//                                         icon: const Icon(
//                                           Icons.cancel,
//                                           color: Colors.red,
//                                         ),
//                                       ),
//                                       IconButton(
//                                         onPressed: () async {
//                                           Fluttertoast.showToast(msg: "Uploading a new image\nwill replace current image!");
//                                           Navigator.push(context,
//                                               MaterialPageRoute(builder: (context) => ImageUploadWater(userNumber: propPhoneNum, meterNumber: wMeterNumber,)));
//                                         },
//                                         icon: const Icon(
//                                           Icons.done,
//                                           color: Colors.green,
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 });
//                           },
//
//                           child: Center(
//                             child: Container(
//                               margin: const EdgeInsets.only(bottom: 5),
//                               // height: 300,
//                               // width: 300,
//                               child: Center(
//                                 child: Card(
//                                   color: Colors.grey,
//                                   semanticContainer: true,
//                                   clipBehavior: Clip.antiAliasWithSaveLayer,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10.0),
//                                   ),
//                                   elevation: 0,
//                                   margin: const EdgeInsets.all(10.0),
//                                   child: FutureBuilder(
//                                       future: _getImageW(
//                                         ///Firebase image location must be changed to display image based on the meter number
//                                           context, 'files/meters/$formattedDate/$propPhoneNum/water/$wMeterNumber.jpg'),//$meterNumber
//                                       builder: (context, snapshot) {
//                                         if (snapshot.hasError) {
//                                           imgUploadCheck = false;
//                                           updateImgCheckW(imgUploadCheck,documentSnapshot);
//                                           return const Padding(
//                                             padding: EdgeInsets.all(20.0),
//                                             child: Column(
//                                               mainAxisSize: MainAxisSize.min,
//                                               children: [
//                                                 Text('Image not yet uploaded.',),
//                                                 SizedBox(height: 10,),
//                                                 FaIcon(Icons.camera_alt,),
//                                               ],
//                                             ),
//                                           );
//                                         }
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.done) {
//                                           // imgUploadCheck = true;
//                                           updateImgCheckW(imgUploadCheck,documentSnapshot);
//                                           return Container(
//                                             height: 300,
//                                             width: 300,
//                                             child: snapshot.data,
//                                           );
//                                         }
//                                         if (snapshot.connectionState ==
//                                             ConnectionState.waiting) {
//                                           return Container(
//                                             child: const CircularProgressIndicator(),);
//                                         }
//                                         return Container();
//                                       }
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10,),
//                         Text(
//                           billMessage,
//                           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//
//                         const SizedBox(height: 10,),
//                         Column(
//                           children: [
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     Fluttertoast.showToast(
//                                         msg: "Now downloading your statement!\nPlease wait a few seconds!");
//
//                                     String accountNumberPDF = documentSnapshot['account number'];
//                                     print('The acc number is ::: $accountNumberPDF');
//
//                                     final storageRef = FirebaseStorage.instance.ref().child("pdfs/$formattedDate");
//                                     final listResult = await storageRef.listAll();
//                                     for (var prefix in listResult.prefixes) {
//                                       print('The ref is ::: $prefix');
//                                       // The prefixes under storageRef.
//                                       // You can call listAll() recursively on them.
//                                     }
//                                     for (var item in listResult.items) {
//                                       print('The item is ::: $item');
//                                       // The items under storageRef.
//                                       if (item.toString().contains(accountNumberPDF)) {
//                                         final url = item.fullPath;
//                                         print('The url is ::: $url');
//                                         final file = await PDFApi.loadFirebase(url);
//                                         try {
//                                           if(context.mounted)openPDF(context, file);
//                                           Fluttertoast.showToast(
//                                               msg: "Download Successful!");
//                                         } catch (e) {
//                                           Fluttertoast.showToast(msg: "Unable to download statement.");
//                                         }
//                                       } else {
//                                         Fluttertoast.showToast(msg: "Unable to download statement.");
//                                       }
//                                     }
//                                   },
//                                   labelText: 'Invoice',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.picture_as_pdf,),
//                                   fgColor: Colors.orangeAccent,
//                                   btSize: const Size(100, 38),
//                                 ),
//                                 BasicIconButtonGrey(
//                                   onPress: () async {
//                                     accountNumberAll = documentSnapshot['account number'];
//                                     locationGivenAll = documentSnapshot['address'];
//
//                                     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                                     //     content: Text('$accountNumber $locationGiven ')));
//
//                                     Navigator.push(context,
//                                         MaterialPageRoute(builder: (context) => MapScreenProp(propAddress: locationGivenAll, propAccNumber: accountNumberAll,)
//                                           //MapPage()
//                                         ));
//                                   },
//                                   labelText: 'Map',
//                                   fSize: 16,
//                                   faIcon: const FaIcon(Icons.map,),
//                                   fgColor: Colors.green,
//                                   btSize: const Size(100, 38),
//                                 ),
//                                 const SizedBox(width: 5,),
//                               ],
//                             ),
//                             const SizedBox(height: 5,),
//                             // Column(
//                             //   children: [
//                             //     Row(
//                             //       mainAxisAlignment: MainAxisAlignment.center,
//                             //       crossAxisAlignment: CrossAxisAlignment.center,
//                             //       children: [
//                             //         BasicIconButtonGrey(
//                             //           onPress: () async {
//                             //             String cell = documentSnapshot['cell number'];
//                             //
//                             //             Fluttertoast.showToast(msg: "The owner must be given a notification",);
//                             //
//                             //             Navigator.push(context,
//                             //                 MaterialPageRoute(builder: (context) => NoticeConfigScreen(userNumber: cell,)));
//                             //
//                             //             // showDialog(
//                             //             //     barrierDismissible: false,
//                             //             //     context: context,
//                             //             //     builder: (context) {
//                             //             //       return AlertDialog(
//                             //             //         title: const Text("Notify Utilities Disconnection"),
//                             //             //         content: const Text("This will notify the owner of the property of their water or electricity being disconnection in 14 days!\n\nAre you sure?"),
//                             //             //         actions: [
//                             //             //           IconButton(
//                             //             //             onPressed: () {
//                             //             //               Navigator.pop(context);
//                             //             //             },
//                             //             //             icon: const Icon(
//                             //             //               Icons.cancel,
//                             //             //               color: Colors.red,
//                             //             //             ),
//                             //             //           ),
//                             //             //           IconButton(
//                             //             //             onPressed: () async {
//                             //             //               String cell = documentSnapshot['cell number'];
//                             //             //
//                             //             //               Fluttertoast.showToast(msg: "The owner has been notified!!",);
//                             //             //
//                             //             //               Navigator.push(context,
//                             //             //                   MaterialPageRoute(builder: (context) => NoticeConfigScreen(userNumber: cell,)));
//                             //             //
//                             //             //               Navigator.pop(context);
//                             //             //               },
//                             //             //             icon: const Icon(
//                             //             //               Icons.done,
//                             //             //               color: Colors.green,
//                             //             //             ),
//                             //             //           ),
//                             //             //         ],
//                             //             //       );
//                             //             //     });
//                             //           },
//                             //           labelText: 'Disconnection',
//                             //           fSize: 16,
//                             //           faIcon: const FaIcon(Icons.warning_amber,),
//                             //           fgColor: Colors.amber,
//                             //           btSize: const Size(100, 38),
//                             //         ),
//                             //       ],
//                             //     ),
//                             //   ],
//                             // ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//               return null;
//             },
//           );
//         }
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     ),
//   );
// }