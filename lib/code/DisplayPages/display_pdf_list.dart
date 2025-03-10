import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:municipal_services/code/PDFViewer/pdf_api.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:municipal_services/code/Chat/chat_screen_finance.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';
import 'display_property_trend.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;


//View Invoice
class UsersPdfListViewPage extends StatefulWidget {
  final String userNumber;
  final String propertyAddress;
  final String accountNumber;
  final bool isLocalMunicipality;
  final String municipalityId;
  final String? districtId;

  const UsersPdfListViewPage(
      {super.key,
      required this.userNumber,
      required this.propertyAddress,
      required this.accountNumber,required this.isLocalMunicipality,
        required this.municipalityId,
        this.districtId,});

  @override
  _UsersPdfListViewPageState createState() => _UsersPdfListViewPageState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

DateTime now = DateTime.now();

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
final email = user?.email;
String userID = uid as String;
String userPhone = phone as String;
String userEmail = email as String;

String locationGiven = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;

final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _UsersPdfListViewPageState extends State<UsersPdfListViewPage> {
  final user = FirebaseAuth.instance.currentUser!;
  CollectionReference? _propList;
  // final CollectionReference _propList =
  //     FirebaseFirestore.instance.collection('properties');

  String formattedDate = DateFormat.MMMM().format(now);
  String districtId = '';
  String municipalityId = '';
  bool isLocalMunicipality=false;
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

  Timer? timer;
  var _isLoading = false;

  void _onSubmit() {
    setState(() => _isLoading = true);
    Future.delayed(
      const Duration(seconds: 5),
      () => setState(() => _isLoading = false),
    );
  }

  @override
  void initState() {
    dropdownValue = formattedDate;
    setMonthLimits();
    _initializeFirestoreReference();
    super.initState();
  }


@override
  void dispose()
{
  super.dispose();
}

  void _initializeFirestoreReference() {
    if (widget.isLocalMunicipality) {
      _propList = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('properties');
    } else if (widget.districtId != null) {
      _propList = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('properties');
    }
  }

  // Future<void> fetchUserDetails() async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       String userPhoneNumber = user.phoneNumber!;
  //       String accountNumber = widget.accountNumber;
  //
  //       // Print statements to debug
  //       print('User Phone Number: $userPhoneNumber');
  //       print('Account Number: $accountNumber');
  //
  //       QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
  //           .collectionGroup('properties')
  //           .where('cellNumber', isEqualTo: userPhoneNumber)
  //           .where('accountNumber', isEqualTo: accountNumber)
  //           .limit(1)
  //           .get();
  //
  //       if (propertySnapshot.docs.isNotEmpty) {
  //         var propertyDoc = propertySnapshot.docs.first;
  //
  //         // Assuming the path structure is: districts/{districtId}/municipalities/{municipalityId}/properties/{propertyId}
  //         var pathSegments = propertyDoc.reference.path.split('/');
  //         if (pathSegments.length >= 4) {
  //           districtId = pathSegments[1];
  //           municipalityId = pathSegments[3];
  //         }
  //
  //         print('District ID: $districtId');
  //         print('Municipality ID: $municipalityId');
  //
  //         setState(() {
  //           _propList = FirebaseFirestore.instance
  //               .collection('districts')
  //               .doc(districtId)
  //               .collection('municipalities')
  //               .doc(municipalityId)
  //               .collection('properties');
  //         });
  //       } else {
  //         print('No matching property found for the user.');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching user details: $e');
  //     setState(() {
  //       // Handle the error state appropriately
  //     });
  //   }
  // }


  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      var result = await Permission.storage.request();
      return result.isGranted;
    }
    return true;
  }

  // Future<void> downloadPDF(String url, String fileName) async {
  //   try {
  //     // Get the external storage directory
  //     final directory = await getExternalStorageDirectory();
  //     final filePath = '${directory?.path}/$fileName';
  //
  //     // Use Dio to download the file
  //     final response = await Dio().download(url, filePath);
  //     if (response.statusCode == 200) {
  //       print("Downloaded the file at $filePath");
  //       // Optionally open or share the file here
  //       Fluttertoast.showToast(msg: "Download Successful!");
  //     } else {
  //       throw Exception("Failed to download file with status code: ${response.statusCode}");
  //     }
  //   } catch (e) {
  //     print("Error downloading file: $e");
  //     Fluttertoast.showToast(msg: "Unable to download statement.");
  //     throw Exception("Error in downloading file: $e"); // Properly throwing an exception with a message
  //   }
  // }

  Widget firebasePDFCard(CollectionReference<Object?> pdfDataStream) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: pdfDataStream.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            // Filter to get only the property that matches the selected account number and address.
            List<QueryDocumentSnapshot<Object?>> filteredProperties = streamSnapshot.data!.docs.where(
                  (documentSnapshot) =>
              documentSnapshot['accountNumber'] == widget.accountNumber &&
                  documentSnapshot['address'] == widget.propertyAddress,
            ).toList();

            if (filteredProperties.isNotEmpty) {
              var filteredProperty = filteredProperties.first;
              return SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Property Data',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Account Number: ${filteredProperty['accountNumber']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Street Address: ${filteredProperty['address']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Area Code: ${filteredProperty['areaCode']}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            BasicIconButtonGrey(
                              onPress: () async {
                                try {
                                  // Step 1: Fetch the user's property details based on accountNumber
                                  QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
                                      .collectionGroup('properties')
                                      .where('accountNumber', isEqualTo: widget.accountNumber)
                                      .limit(1)
                                      .get();

                                  if (propertySnapshot.docs.isNotEmpty) {
                                    var propertyDoc = propertySnapshot.docs.first;
                                    String userPhoneNumber = propertyDoc.get('cellNumber'); // Get user's phone number
                                    String accountNumber = propertyDoc.get('accountNumber'); // Get account number

                                    print('Phone number: $userPhoneNumber');
                                    print('Account number: $accountNumber');

                                    // Step 2: Prepare the Firestore path for finance chat
                                    CollectionReference chatFinCollectionRef;

                                    if (widget.isLocalMunicipality) {
                                      chatFinCollectionRef = FirebaseFirestore.instance
                                          .collection('localMunicipalities')
                                          .doc(widget.municipalityId)
                                          .collection('chatRoomFinance');
                                    } else if (widget.districtId != null) {
                                      chatFinCollectionRef = FirebaseFirestore.instance
                                          .collection('districts')
                                          .doc(widget.districtId)
                                          .collection('municipalities')
                                          .doc(widget.municipalityId)
                                          .collection('chatRoomFinance');
                                    } else {
                                      print('Error: districtId is null.');
                                      return;
                                    }

                                    // Step 3: Navigate to the ChatFinance screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatFinance(
                                          chatRoomId: userPhoneNumber,  // Pass the user's phone number as chatRoomId
                                          userName: accountNumber,  // Pass the account number
                                          chatFinCollectionRef: chatFinCollectionRef,  // Pass the Firestore reference
                                          refreshChatList: () {},
                                          isLocalMunicipality: widget.isLocalMunicipality,
                                          municipalityId: widget.municipalityId,
                                          districtId: widget.districtId ?? '',
                                        ),
                                      ),
                                    );
                                  } else {
                                    print('Error: No property found for account number ${widget.accountNumber}.');
                                  }
                                } catch (e) {
                                  print('Error fetching property details: $e');
                                }
                              },
                              labelText: 'Dispute',
                              fSize: 16,
                              faIcon: const FaIcon(Icons.error_outline),
                              fgColor: Colors.red,
                              btSize: const Size(100, 38),
                            ),

                            const SizedBox(width: 5),
                            BasicIconButtonGrey(
                              onPress: () async {
                                _onSubmit();
                                // String accountNumberPDF = filteredProperty['accountNumber'];
                                // String monthToUse = dropdownValue == 'Select Month' ? formattedDate : dropdownValue;
                                // getPDFByAccMon(accountNumberPDF, monthToUse);
                                String accountNumberPDF = widget.accountNumber;
                                String monthToUse = dropdownValue == 'Select Month' ? formattedDate : dropdownValue;
                                getPDFByAccMon(accountNumberPDF, monthToUse);
                              },
                              labelText: 'Invoice',
                              fSize: 16,
                              faIcon: const FaIcon(Icons.download),
                              fgColor: Colors.green,
                              btSize: const Size(100, 38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return const Center(child: Text('No property data found.'));
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Widget firebasePDFCard() {
  //   print("Fetching PDFs from Firebase Storage at path: /pdfs/${dropdownValue}/${widget.userNumber}/${widget.propertyAddress}/");
  //
  //   return Expanded(
  //     child: FutureBuilder<ListResult>(
  //       future: FirebaseStorage.instance
  //           .ref('pdfs/$dropdownValue/${widget.userNumber}/${widget.propertyAddress}')
  //           .listAll(),
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return const Center(child: CircularProgressIndicator());
  //         }
  //
  //         if (snapshot.hasError) {
  //           print("Error fetching PDFs: ${snapshot.error}");
  //           return Text("Error fetching PDFs: ${snapshot.error}");
  //         }
  //
  //         if (snapshot.hasData && snapshot.data!.items.isNotEmpty) {
  //           print("Fetched ${snapshot.data!.items.length} PDFs");
  //           return ListView.builder(
  //             itemCount: snapshot.data!.items.length,
  //             itemBuilder: (context, index) {
  //               var fileRef = snapshot.data!.items[index];
  //               var accountNumberPDF = fileRef.name;
  //               return Card(
  //                 margin: const EdgeInsets.all(10),
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(20.0),
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         'Document: ${fileRef.name}',
  //                         style: const TextStyle(
  //                             fontSize: 18, fontWeight: FontWeight.bold),
  //                       ),
  //                       const SizedBox(height: 10),
  //                       Text(
  //                         'Account Number: ${widget.accountNumber}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       Text(
  //                         'Address: ${widget.propertyAddress}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                       const SizedBox(height: 20),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                         children: [
  //                           ElevatedButton.icon(
  //                             icon: const Icon(
  //                               Icons.error_outline,
  //                               color: Colors.red,
  //                             ),
  //                             label:  const Text('Dispute',style: TextStyle(color: Colors.black),),
  //                             onPressed: () {
  //                               String financeID = 'finance@msunduzi.gov.za';
  //
  //                               String passedID = user.phoneNumber!;
  //                               String? userName = FirebaseAuth
  //                                   .instance.currentUser!.phoneNumber;
  //                               print(
  //                                   'The user name of the logged in person is $userName}');
  //                               String id = passedID;
  //
  //                               Navigator.push(
  //                                   context,
  //                                   MaterialPageRoute(
  //                                       builder: (context) => ChatFinance(
  //                                             chatRoomId: id,
  //                                             userName: null,
  //                                           ))); // Navigate to dispute screen or handle dispute
  //                             },
  //                             style: ElevatedButton.styleFrom(
  //                               backgroundColor: Colors.white,
  //                             ),
  //                           ),
  //                           ElevatedButton.icon(
  //                             icon: const Icon(Icons.download,color: Colors.green,),
  //                             label: const Text('Invoice',style: TextStyle(color: Colors.black)),
  //                             onPressed: () async {
  //                               Fluttertoast.showToast(
  //                                   msg: "Preparing your statement for download..."
  //                               );
  //
  //                               _onSubmit(); // Ensure any necessary updates
  //
  //                              // String accountNumberPDF = documentSnapshot['account number'];
  //                               print('The account number is ::: $accountNumberPDF');
  //
  //                               final storageRef = FirebaseStorage.instance.ref().child(
  //                                   "pdfs/$formattedMonth/${widget.userNumber}/${widget.propertyAddress}");
  //                               final listResult = await storageRef.listAll();
  //
  //                               bool found = false;
  //                               for (var item in listResult.items) {
  //                                 if (item.name.contains(accountNumberPDF)) {
  //                                   found = true;
  //                                   String url = await item.getDownloadURL();
  //                                   print('The URL for download is ::: $url');
  //
  //                                   // Open the URL in the device's browser
  //                                   if (await canLaunch(url)) {
  //                                     await launch(url);
  //                                     Fluttertoast.showToast(msg: "Redirecting to browser for download...");
  //                                   } else {
  //                                     print("Could not launch $url");
  //                                     Fluttertoast.showToast(msg: "Unable to open the document.");
  //                                   }
  //                                   break; // Exit loop after successful operation
  //                                 }
  //                               }
  //                               if (!found) {
  //                                 Fluttertoast.showToast(msg: "No matching document found.");
  //                               }
  //                             },
  //                           ),
  //                         ],
  //                       )
  //                     ],
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         } else {
  //           print("No PDFs found at the path.");
  //           return const Center(child: Text("No invoices available."));
  //         }
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    setMonthLimits();
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text(
          'Account Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 0.0, horizontal: 15.0),
            child: Column(children: [
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        fillColor: Colors.white,
                        filled: true,
                        suffixIcon: DropdownButtonFormField<String>(
                          value: dropdownValue, // Ensure this value is valid
                          items: dropdownMonths.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                                child: Text(value, style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (mounted && newValue != null) {
                              setState(() {
                                dropdownValue = newValue;
                              });
                            }
                          },
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: Icon(Icons.arrow_circle_down_sharp),
                          ),
                          iconEnabledColor: Colors.green,
                          style: const TextStyle(color: Colors.black, fontSize: 18),
                          dropdownColor: Colors.grey[50],
                          isExpanded: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          if (_propList != null)
            firebasePDFCard(_propList!)
          else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  // void getPDFByAccMon(String accNum, String month) async {
  //   Fluttertoast.showToast(
  //       msg: "Now downloading your statement!\nPlease wait a few seconds!"
  //   );
  //
  //   // Ensure the address is trimmed and formatted consistently
  //   String formattedAddress = widget.propertyAddress.trim(); // Trim any extra spaces
  //
  //   // Print statements to debug the exact path being used
  //   print('Attempting to list files in path: pdfs/$month/${widget.userNumber}/$formattedAddress/');
  //
  //   // Reference the storage path based on the formatted address
  //   final storageRef = FirebaseStorage.instance.ref().child("pdfs/$month/${widget.userNumber}/$formattedAddress");
  //
  //   try {
  //     final listResult = await storageRef.listAll();
  //
  //     print('List of files found at path: pdfs/$month/${widget.userNumber}/$formattedAddress/');
  //     if (listResult.items.isEmpty) {
  //       print('No files found at this path.');
  //     }
  //
  //     for (var item in listResult.items) {
  //       print('File found: ${item.name}');
  //
  //       // Check if the file name contains the selected account number
  //       if (item.name.contains(accNum)) {
  //         print('Found a matching file: ${item.name}');
  //
  //         final url = await item.getDownloadURL(); // Get the download URL
  //         print('Download URL: $url');
  //
  //
  //         if (kIsWeb) {
  //           // **📌 For Web: Open in New Tab**
  //           html.window.open(url, "_blank");
  //           Fluttertoast.showToast(msg: "Statement opened in a new tab.");
  //         } else {
  //           // **📌 For Mobile: Use Download Manager**
  //           await downloadFileUsingDownloadManager(url, 'statement_$accNum.pdf');
  //           Fluttertoast.showToast(msg: "Download started.");
  //         }
  //         break; // Exit loop after starting the download
  //       } else {
  //         print('File does not match account number: ${item.name}');
  //       }
  //     }
  //   } catch (e) {
  //     print('Error during file listing or download process: $e');
  //     Fluttertoast.showToast(msg: "Unable to download statement.");
  //   }
  // }

  void getPDFByAccMon(String accNum, String month) async {
    Fluttertoast.showToast(msg: "Now downloading your statement!\nPlease wait a few seconds!");

    // Trim spaces to avoid incorrect Firebase pathing
    String formattedAddress = widget.propertyAddress.trim();

    print('📂 Attempting to list files in path: pdfs/$month/${widget.userNumber}/$formattedAddress/');

    final storageRef = FirebaseStorage.instance.ref()
        .child("pdfs/$month/${widget.userNumber}/$formattedAddress");

    try {
      final listResult = await storageRef.listAll();

      if (listResult.items.isEmpty) {
        print('❌ No files found at this path.');
        Fluttertoast.showToast(msg: "No statement found for this property.");
        return;
      }

      for (var item in listResult.items) {
        print('📄 Found File: ${item.name}');

        if (item.name.contains(accNum)) {
          print('✅ Matching statement found: ${item.name}');

          final url = await item.getDownloadURL();
          print('🔗 Download URL: $url');

          if (kIsWeb) {
            html.window.open(url, "_blank");
            Fluttertoast.showToast(msg: "Statement opened in a new tab.");
          } else {
            openURL(url);
            Fluttertoast.showToast(msg: "Opening statement in browser...");
          }

          return;
        }
      }

      print('❌ No matching statement found.');
      Fluttertoast.showToast(msg: "No matching statement found for this account.");

    } catch (e) {
      print('🚨 Error downloading statement: $e');
      Fluttertoast.showToast(msg: "Error downloading statement.");
    }
  }



  Future<void> downloadFileUsingDownloadManager(String url, String fileName) async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: '/storage/emulated/0/Download', // This saves the file to the Downloads directory
        fileName: fileName,
        showNotification: true, // show download progress in status bar (for Android)
        openFileFromNotification: true, // click on notification to open downloaded file (for Android)
      );
      print('Download started with taskId: $taskId');
    } else {
      print('Permission denied to access storage');
      Fluttertoast.showToast(msg: "Permission denied to access storage.");
    }
  }

  Future<File?> _downloadFile(String url, String filename) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final localFile = File('${appDocDir.path}/$filename');

      final response = await Dio().download(url, localFile.path);
      if (response.statusCode == 200) {
        print("✅ File downloaded to ${localFile.path}");
        return localFile;
      } else {
        throw Exception("Failed to download file with status code: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 Error downloading file: $e");
      Fluttertoast.showToast(msg: "Unable to download statement.");
      return null;
    }
  }


  void setMonthLimits() {
    DateTime now = DateTime.now();
    DateTime previousMonthDate = now.subtract(Duration(days: 30)); // Previous month
    String previousMonth = DateFormat('MMMM').format(previousMonthDate); // Format as full month name

    // Generate the last 3 months before the previous month
    String month1 = DateFormat('MMMM').format(previousMonthDate.subtract(Duration(days: 30)));
    String month2 = DateFormat('MMMM').format(previousMonthDate.subtract(Duration(days: 60)));
    String month3 = DateFormat('MMMM').format(previousMonthDate.subtract(Duration(days: 90)));

    dropdownMonths = [
      'Select Month',
      month3,
      month2,
      month1,
      previousMonth, // The most recent available statement
    ];

    // ✅ Ensure dropdownValue is in the list to prevent assertion errors
    if (!dropdownMonths.contains(dropdownValue)) {
      dropdownValue = previousMonth; // Set default to previous month
    }
  }


  void openPDF(BuildContext context, File? file, String? webUrl) async {
    if (kIsWeb) {
      // ✅ Web: Open PDF in a new tab
      if (webUrl != null && webUrl.isNotEmpty) {
        html.window.open(webUrl, "_blank");
      } else {
        Fluttertoast.showToast(msg: "Failed to open PDF: No URL available.");
      }
    } else {
      // ✅ Mobile: Open URL in Browser Instead of Downloading Manually
      if (webUrl != null && webUrl.isNotEmpty) {
        openURL(webUrl); // ✅ Open in browser
      } else {
        Fluttertoast.showToast(msg: "Error: Unable to open statement.");
      }
    }
  }

  /// ✅ Method to open the URL in the device's default browser
  void openURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('🚨 Could not launch $url');
      Fluttertoast.showToast(msg: "Error: Unable to open statement.");
    }
  }



///pdf view loader getting file name onPress/onTap that passes pdf filename to this class.
  // void openPDF(BuildContext context, File file) => Navigator.of(context).push(
  //   MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
  // );

}
