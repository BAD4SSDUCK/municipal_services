import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:municipal_services/code/ImageUploading/water_meter_reading.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUploadWater extends StatefulWidget {
  const ImageUploadWater({
    super.key,
    required this.userNumber,
    required this.meterNumber,
    this.municipalityUserEmail,
    required this.propertyAddress,
    required this.districtId,
    required this.municipalityId,
    required this.isLocalMunicipality,
    this.isLocalUser=false,
  });

  final String userNumber;
  final String meterNumber;
  final String? municipalityUserEmail;
  final String propertyAddress; // Property address passed from UsersPropsAll
  final String districtId; // District ID passed from UsersPropsAll
  final String municipalityId;
  final bool isLocalMunicipality;
  final bool isLocalUser;

  @override
  _ImageUploadWaterState createState() => _ImageUploadWaterState();
}

final FirebaseAuth auth = FirebaseAuth.instance;

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
String userID = uid as String;
String phoneNum = phone as String;

DateTime now = DateTime.now();

class _ImageUploadWaterState extends State<ImageUploadWater> {
  String? userEmail;
  String districtId = '';
  String municipalityId = '';
  Location location = Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;
  bool isLocalMunicipality=false;
  bool isLoading=false;
  bool isLoadingMeter=false;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  String formattedDate = DateFormat.MMMM().format(now);
  String? propertyAddress;
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

  File? _photo;
  final ImagePicker _picker = ImagePicker();
  double? latitude; // Define latitude
  double? longitude; // Define longitude
  DocumentSnapshot? documentSnapshot;

  @override
  void initState() {
    super.initState();
    userEmail = widget.municipalityUserEmail; // Assign the email from the widget to userEmail.
    districtId = widget.districtId;
    municipalityId = widget.municipalityId;

    print("ImageUploadWater Init: User Email - $userEmail");
    print("ImageUploadWater Init: District ID - $districtId");
    print("ImageUploadWater Init: Municipality ID - $municipalityId");

    fetchUserDetails().then((_) {
      validateProperty();
      fetchPropertyDetails();
    });
    print("User Number Passed: ${widget.userNumber}");
    print("Meter Number Passed: ${widget.meterNumber}");
    // Additional initialization code can be placed here
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber =
          prefs.getString('selectedPropertyAccountNo');

      if (user != null) {
        if (user.email != null && user.email!.isNotEmpty) {
          // Municipal user (logged in with email)
          userEmail = user.email;

          QuerySnapshot userSnapshot = await FirebaseFirestore.instance
              .collectionGroup('users')
              .where('email', isEqualTo: userEmail)
              .limit(1)
              .get();

          if (userSnapshot.docs.isNotEmpty) {
            var userDoc = userSnapshot.docs.first;
            districtId = userDoc.reference.parent.parent!.parent.id;
            municipalityId = userDoc.reference.parent.parent!.id;
          }
        } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
          // Regular user (logged in with phone number)
          String userPhoneNumber = user.phoneNumber!;

          if (selectedPropertyAccountNumber != null) {
            QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
                .collectionGroup('properties')
                .where('cellNumber', isEqualTo: userPhoneNumber)
                .where('accountNumber',
                    isEqualTo: selectedPropertyAccountNumber)
                .limit(1)
                .get();

            if (propertySnapshot.docs.isNotEmpty) {
              var propertyDoc = propertySnapshot.docs.first;

              // Firestore path traversal to get districtId and municipalityId
              final propertyRef = propertyDoc.reference;
              final municipalityRef = propertyRef.parent.parent;
              final districtRef = municipalityRef?.parent.parent;

              if (municipalityRef != null && districtRef != null) {
                districtId = districtRef.id;
                municipalityId = municipalityRef.id;

                setState(() {
                  propertyAddress = propertyDoc['address']
                      .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
                });
              }
            } else {
              print('No property found with the selected account number.');
            }
          } else {
            print('Selected property account number is not available.');
          }
        }
      }
      setState(() {});
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {});
    }
  }

  Future<LocationData?> _getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    _locationData = await location.getLocation();
    return _locationData;
  }

  Future<void> imgFromGallery() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      final tempFile = File(pickedFile.path); // ✅ Create a new file reference
        if(mounted) {
          setState(() {
            _photo = tempFile; // ✅ Ensure _photo updates correctly
            _selectedFileBytes =
                _photo!.readAsBytesSync(); // ✅ Convert to bytes for preview
            _selectedFileName = "${widget.meterNumber}.jpg"; // ✅ Rename file
          });
        }
      print("Gallery image selected: $_selectedFileName");
    } else {
      print('No image selected.');
    }
  }




  Future<bool> validateProperty() async {
    if (widget.isLocalMunicipality) {
      var propertyQuery = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: widget.userNumber)
          .where('address', isEqualTo: widget.propertyAddress)
          //.where('meter_number', isEqualTo: widget.meterNumber)
          .limit(1)
          .get();
      return propertyQuery.docs.isNotEmpty;
    } else {
      var propertyQuery = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: widget.userNumber)
          .where('address', isEqualTo: widget.propertyAddress)
          //.where('meter_number', isEqualTo: widget.meterNumber)
          .limit(1)
          .get();

      return propertyQuery.docs.isNotEmpty;
    }
  }

  Future<void> fetchPropertyDetails() async {
    try {
      // Use the selected property account number from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? selectedPropertyAccountNumber =
          prefs.getString('selectedPropertyAccountNo');

      // Make sure selectedPropertyAccountNumber is not null
      if (selectedPropertyAccountNumber != null) {
        var propertyQuery = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('address', isEqualTo: widget.propertyAddress)
            .where('accountNumber',
                isEqualTo:
                    selectedPropertyAccountNumber) // Filter by account number
            // .where('water_meter_number', isEqualTo: widget.meterNumber)  // Filter by meter number
            .limit(1)
            .get();

        if (propertyQuery.docs.isNotEmpty) {
          var propertyData = propertyQuery.docs.first.data();
          setState(() {
            propertyAddress =
                propertyData['address']; // Properly format the address
          });
          print("Correct property address fetched: $propertyAddress");
        } else {
          print(
              "No property found matching account number: $selectedPropertyAccountNumber");
        }
      } else {
        print('Selected property account number is not available.');
      }
    } catch (e) {
      print('Error fetching property details: $e');
    }
  }

  Future<void> _fetchDocumentSnapshot() async {
    // Assuming you need to fetch the property based on some criteria
    try {
      QuerySnapshot propertySnapshot;
      if (widget.isLocalMunicipality) {
        propertySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('properties')
            .where('cellNumber', isEqualTo: widget.userNumber)
            .where('address', isEqualTo: widget.propertyAddress)
            .limit(1)
            .get();
      } else {
        propertySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('properties')
            .where('cellNumber', isEqualTo: widget.userNumber)
            .where('address', isEqualTo: widget.propertyAddress)
            .limit(1)
            .get();
      }

      if (propertySnapshot.docs.isNotEmpty) {
        if(mounted) {
          setState(() {
            documentSnapshot = propertySnapshot.docs.first;
          });
        }
      } else {
        Fluttertoast.showToast(msg: "Error: Property not found.");
      }
    } catch (e) {
      print("Error fetching document snapshot: $e");
      Fluttertoast.showToast(msg: "Error: Could not fetch property details.");
    }
  }

  Future<void> _showMeterReadingUpdateUI(BuildContext parentContext, DocumentSnapshot documentSnapshot) async {
    final TextEditingController waterMeterReadingController =
    TextEditingController(text: documentSnapshot['water_meter_reading']);

    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Make the background transparent
      context: parentContext,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white, // Match the background color to a dialog
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Water Meter Reading',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        maxLength: 8,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        keyboardType: TextInputType.number,
                        controller: waterMeterReadingController,
                        decoration: InputDecoration(
                          labelText: 'Water Meter Reading',
                          labelStyle: const TextStyle(
                            color: Colors.blue, // Change the labelText color here
                            fontSize: 16, // Adjust the font size
                            fontWeight: FontWeight.bold, // Make the label bold
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green, width: 2.0), // Change color here
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        cursorColor: Colors.green, // Change cursor color
                      ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the bottom sheet
                            },
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          isLoadingMeter // Display CircularProgressIndicator when loading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            onPressed: () async {
                              final String waterMeterReading =
                                  waterMeterReadingController.text;

                              if (waterMeterReading.isNotEmpty) {
                                if(mounted) {
                                  setState(() {
                                    isLoadingMeter = true; // Set loading state
                                  });
                                }
                                try {
                                  await documentSnapshot.reference.update({
                                    'water_meter_reading': waterMeterReading,
                                  });

                                  // Call the service to handle backend updates
                                  await _callMeterReadingServiceAfterUpload();

                                  Navigator.pop(ctx); // Close the bottom sheet
                                  ScaffoldMessenger.of(parentContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Meter readings updated successfully"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  print(
                                      "Error updating water meter reading in UI: $e");
                                  ScaffoldMessenger.of(parentContext)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Failed to update meter reading"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } finally {
                                  if(mounted) {
                                    setState(() {
                                      isLoadingMeter =
                                      false; // Reset loading state
                                    });
                                  }
                                }
                              } else {
                                ScaffoldMessenger.of(parentContext)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Please fill in the meter reading."),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Text('Update'),
                          ),
                        ],
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


  // Updated method to call the meter reading service
  Future<void> _callMeterReadingServiceAfterUpload() async {
    QuerySnapshot propertySnapshot;
    if (widget.isLocalMunicipality) {
      propertySnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: widget.userNumber)
          .where('address', isEqualTo: widget.propertyAddress)
          .limit(1)
          .get();
    } else {
      propertySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('properties')
          .where('cellNumber', isEqualTo: widget.userNumber)
          .where('address', isEqualTo: widget.propertyAddress)
          .limit(1)
          .get();
    }

    if (propertySnapshot.docs.isNotEmpty) {
      DocumentSnapshot documentSnapshot = propertySnapshot.docs.first;

      CollectionReference propList = documentSnapshot.reference.parent;

      await WaterMeterReadingService.updateWaterMeterData(
        documentSnapshot: documentSnapshot,
        propList: propList,
        municipalityUserEmail: widget.municipalityUserEmail,
        districtId: widget.districtId,
        municipalityId: widget.municipalityId,
        isLocalMunicipality: widget.isLocalMunicipality,
      );
    } else {
      Fluttertoast.showToast(
          msg: "Error: Property not found. Cannot update meter reading.");
      print(
          'Error: Property not found for user number ${widget.userNumber} and address ${widget.propertyAddress}.');
    }
  }

  Future imgFromCamera(BuildContext parentContext) async {
    // Get location data
    LocationData? locationData = await _getLocation();

    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      setState(() {
        _photo = File(pickedFile.path); // Set the image without uploading
      });

      if (locationData != null) {
        latitude = locationData.latitude!; // Store latitude
        longitude = locationData.longitude!; // Store longitude

        print('Image taken at Latitude: $latitude, Longitude: $longitude');

        // Show the dialog to confirm quality and proceed with the upload
        _showQualityConfirmationDialog(parentContext, latitude!, longitude!);
      } else {
        print('Location data not available');
      }
    } else {
      print('No image selected.');
    }
  }

  Future<void> _showQualityConfirmationDialog(
      BuildContext context, double latitude, double longitude) async {
    print("Quality confirmation dialog opened");

    return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you happy with the picture quality?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // Customize title text color
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // Text color
                          backgroundColor: Colors.orange, // Button background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          imgFromCamera(ctx); // Retake picture
                        },
                        child: const Text('Retake'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // Text color
                          backgroundColor: Colors.green, // Button background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          // uploadFile(latitude, longitude);  // Trigger upload here
                        },
                        child: const Text('Proceed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> ensureDocumentExists(
      String userNumber,
      String districtId,
      String municipalityId,
      String propertyAddress,
      bool isLocalMunicipality) async {
    DocumentReference userDocRef;

    if (isLocalMunicipality) {
      userDocRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userNumber);
    } else {
      userDocRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(userNumber);
    }

    try {
      // Set the "created" field with a server timestamp if the document doesn't already exist
      await userDocRef.set(
        {
          'created': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true), // Use merge to avoid overwriting existing data
      );
      print(
          'User root document created/updated successfully in ensureDocumentExists.');
    } catch (e) {
      print('Error ensuring user document exists: $e');
    }
  }

  Future<void> logWMeterUploadAction(
      String fileUrl,
      String actionType,
      String userNumber,
      String propertyAddress,
      String? municipalityUserEmail,
      double latitude,
      double longitude,
      ) async {
    print('Logging action for Water Meter Upload...');
    print('District ID: ${widget.districtId}');
    print('Municipality ID: ${widget.municipalityId}');
    print('User Number: $userNumber');
    print('Property Address: $propertyAddress');
    print('Municipality User Email: ${widget.municipalityUserEmail}');
    print('File URL: $fileUrl');
    print('Latitude: $latitude, Longitude: $longitude');

    DocumentReference actionLogRef;

    if (widget.isLocalMunicipality) {
      // Ensure the user's root document exists
      await ensureDocumentExists(
          userNumber, '', widget.municipalityId, propertyAddress, true);

      // Reference for the specific action log document (auto-generated ID)
      actionLogRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(userNumber)
          .collection(propertyAddress)
          .doc(); // Auto-generate document ID for the action
    } else {
      // Ensure the user's root document exists
      await ensureDocumentExists(userNumber, widget.districtId,
          widget.municipalityId, propertyAddress, false);

      // Reference for the specific action log document (auto-generated ID)
      actionLogRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(userNumber)
          .collection(propertyAddress)
          .doc(); // Auto-generate document ID for the action
    }

    try {
      await actionLogRef.set({
        'actionType': actionType,
        'uploader': municipalityUserEmail ?? userNumber, // Properly use municipalityUserEmail
        'fileUrl': fileUrl,
        'propertyAddress': propertyAddress,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'description':
        '${municipalityUserEmail ?? userNumber} uploaded a new water meter image for property $propertyAddress at these coordinates: $latitude, $longitude',
      });
      print('Action log entry created successfully');
    } catch (e) {
      print('Error creating action log entry: $e');
    }
  }


  Future uploadFile(double latitude, double longitude) async {
    if (_photo == null) {
      print('No image selected.');
      return;
    }

    final String fileName = '${widget.meterNumber}.jpg';
    final String destination =
        'files/meters/$formattedDate/${widget.userNumber}/${widget.propertyAddress}/water/$fileName';

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
      final mimeType =
          lookupMimeType(_photo!.path) ?? 'application/octet-stream';
      final metadata = firebase_storage.SettableMetadata(contentType: mimeType);

      // Upload the image
      await ref.putFile(_photo!, metadata);
      String fileUrl = await ref.getDownloadURL();
      print('Image uploaded successfully to: $destination');
      print('File URL: $fileUrl');
      print(
          'Calling logWMeterUploadAction with details: fileUrl=$fileUrl, userNumber=${widget.userNumber}, propertyAddress=${widget.propertyAddress}, municipalityUserEmail=${widget.municipalityUserEmail}, latitude=$latitude, longitude=$longitude');

      // Log the upload and include the location data
      await logWMeterUploadAction(
        fileUrl,
        "Upload Water Meter Image",
        widget.userNumber,
        widget.propertyAddress,
        widget.municipalityUserEmail,
        latitude,
        longitude,
      );

      if(mounted) {
        setState(() {
          _photo = null;
        });
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
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
                    if (kIsWeb) {
                      pickFileFromPC();  // 🔹 New method for Web
                    } else {
                      imgFromGallery();  // 🔹 Mobile users
                    }
                    Navigator.of(context).pop();
                  },
                ),
                if (!kIsWeb)  // 🔹 Camera option only for mobile users
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Camera'),
                    onTap: () {
                      imgFromCamera(context);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Uint8List? _selectedFileBytes; // Store selected file bytes
  String? _selectedFileName; // Store selected file name

  Future<void> pickFileFromPC() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // Store file bytes instead of path
    );

    if (result != null) {
      if(mounted) {
        setState(() {
          _selectedFileBytes = result.files.first.bytes; // Store file bytes
          _selectedFileName = "${widget.meterNumber}.jpg"; // Rename file
        });
      }
      print("File selected and renamed to: $_selectedFileName");
    } else {
      print('No file selected.');
    }
  }




  Future<void> _uploadFileToFirebase(Uint8List fileBytes, String fileName) async {
    final String destination =
        'files/meters/$formattedDate/${widget.userNumber}/${widget.propertyAddress}/water/$fileName';

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
      final metadata = firebase_storage.SettableMetadata(contentType: "image/jpeg");

      await ref.putData(fileBytes, metadata); // Upload bytes instead of file
      String fileUrl = await ref.getDownloadURL();

      print("Image uploaded successfully as: $fileName");
      print("File URL: $fileUrl");

      // Log the upload action
      await logWMeterUploadAction(
        fileUrl,
        "Upload Water Meter Image",
        widget.userNumber,
        widget.propertyAddress,
        widget.municipalityUserEmail,
        latitude ?? 0.0,
        longitude ?? 0.0,
      );

    } catch (e) {
      print('Error uploading image: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Water Meter Reading Upload',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(
              height: 100,
            ),
            Center(
              child: GestureDetector(
                onTap: () {
                  _showPicker(context);
                },
                child: CircleAvatar(
                  radius: 180,
                  backgroundColor: Colors.grey[400],
                  child: _selectedFileBytes != null // ✅ Show preview for web & mobile gallery
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory( // ✅ Display image from Uint8List
                      _selectedFileBytes!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  )
                      : _photo != null // ✅ Show preview for camera images
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _photo!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Container(
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10)),
                          width: 250,
                          height: 250,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.grey[800],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: GestureDetector(
                onTap: isLoading
                    ? null // Disable button when loading
                    : () async {
                  if (_selectedFileBytes != null && _selectedFileName != null) {
                    if(mounted) {
                      setState(() {
                        isLoading = true;
                      });
                    }
                    try {
                      await _uploadFileToFirebase(_selectedFileBytes!, _selectedFileName!).then((_) async {
                        // Fetch document snapshot after successful upload
                        await _fetchDocumentSnapshot();

                        // Show UI only if document snapshot is available
                        if (documentSnapshot != null) {
                          await _showMeterReadingUpdateUI(context, documentSnapshot!);
                          Navigator.of(context).pop();
                        } else {
                          Fluttertoast.showToast(msg: "Error: Could not fetch property details after upload.");
                        }
                      });

                      Fluttertoast.showToast(msg: "Successfully Uploaded!\nWater Meter Image!");
                    } finally {
                      if(mounted) {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  } else {
                    Fluttertoast.showToast(msg: "Please select an image first!");
                  }
                },
                child: isLoading
                    ? const CircularProgressIndicator()
                    : Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Upload Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
