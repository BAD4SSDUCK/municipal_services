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
  String? currentMonthReading;

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
                  if(mounted) {
                    setState(() {
                      propertyAddress = propertyDoc['address']
                          .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
                    });
                  }
              }
            } else {
              print('No property found with the selected account number.');
            }
          } else {
            print('Selected property account number is not available.');
          }
        }
      }
         if(mounted) {
           setState(() {});
         }
    } catch (e) {
      print('Error fetching user details: $e');
      if(mounted) {
        setState(() {});
      }
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
          if(mounted) {
            setState(() {
              propertyAddress =
              propertyData['address']; // Properly format the address
            });
          }
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

  Future<void> _showMeterReadingUpdateUI(BuildContext parentContext) async {
    // Work out previous month (handles Jan -> previous year's Dec)
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    final String prevYear = DateFormat('yyyy').format(prev);
    final String prevMonth = DateFormat.MMMM().format(prev);

    String previousReading = "0"; // default fallback

    try {
      // Pick the correct base path
      CollectionReference<Map<String, dynamic>> monthCollection;
      if (widget.isLocalMunicipality) {
        monthCollection = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('consumption')
            .doc(prevYear)
            .collection(prevMonth);
      } else {
        monthCollection = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('consumption')
            .doc(prevYear)
            .collection(prevMonth);
      }

      // Try reading by document id (address) first (common pattern in your app)
      final byId = await monthCollection.doc(widget.propertyAddress.trim()).get();
      if (byId.exists) {
        final data = byId.data();
        if (data != null) {
          previousReading = (data['water_meter_reading'] ?? "0").toString();
        }
      } else {
        // Fallback: query by 'address' field (covers older data shape)
        final qs = await monthCollection
            .where('address', isEqualTo: widget.propertyAddress)
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) {
          final data = qs.docs.first.data();
          previousReading = (data['water_meter_reading'] ?? "0").toString();
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching previous month's reading: $e");
    }

    // Empty controller (user enters current reading); previous is shown as hint/helper
    final TextEditingController waterMeterReadingController = TextEditingController();

    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: parentContext,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      // Small chip showing which month we’re referencing
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // child: Text(
                        //   'Previous (${prevMonth} ${prevYear}): $previousReading kL',
                        //   style: const TextStyle(fontSize: 12, color: Colors.black87),
                        // ),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        maxLength: 8,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        keyboardType: TextInputType.number,
                        controller: waterMeterReadingController,
                        decoration: InputDecoration(
                          labelText: 'Water Meter Reading',
                          labelStyle: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          hintText: 'Previous: $previousReading', // ← grey hint
                          hintStyle: const TextStyle(color: Colors.grey),
                          helperText: 'Enter the current month reading (kL).',
                          suffixText: 'kL',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.green, width: 2.0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        cursorColor: Colors.green,
                      ),
                      const SizedBox(height: 10),

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
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          isLoadingMeter
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () async {
                              final String waterMeterReading = waterMeterReadingController.text.trim();

                              if (waterMeterReading.isNotEmpty) {
                                if (mounted) setState(() => isLoadingMeter = true);
                                try {
                                  final updatedReading = await _callMeterReadingServiceAfterUpload(waterMeterReading);
                                  if (mounted) setState(() => currentMonthReading = updatedReading);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text("Meter reading updated successfully"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } catch (e) {
                                  debugPrint("Error updating water meter reading: $e");
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(
                                      content: Text("Failed to update meter reading"),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => isLoadingMeter = false);
                                }
                              } else {
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please fill in the meter reading."),
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
  Future<String> _callMeterReadingServiceAfterUpload(String waterMeterReading) async {
    try {
      String currentYear = DateFormat('yyyy').format(DateTime.now());
      String currentMonth = DateFormat.MMMM().format(DateTime.now());

      // ✅ Define Firestore path based on municipality type
      CollectionReference consumptionCollection;
      if (widget.isLocalMunicipality) {
        consumptionCollection = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('consumption')
            .doc(currentYear)
            .collection(currentMonth);
      } else {
        consumptionCollection = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('consumption')
            .doc(currentYear)
            .collection(currentMonth);
      }

      // ✅ Query for the correct document
      QuerySnapshot querySnapshot = await consumptionCollection
          .where('address', isEqualTo: widget.propertyAddress)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // ✅ Update existing document
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        await documentSnapshot.reference.update({
          'water_meter_reading': waterMeterReading,
          'timestamp': Timestamp.now(),
        });
      } else {
        // ✅ If no document exists, create a new one
        await consumptionCollection.doc(widget.propertyAddress).set({
          'address': widget.propertyAddress,
          'water_meter_number': widget.meterNumber,
          'water_meter_reading': waterMeterReading,
          'timestamp': Timestamp.now(),
        });
      }

      print("✅ Meter reading updated successfully!");
      return waterMeterReading;
    } catch (e) {
      print("❌ Error updating meter reading: $e");
      throw e;
    }
  }

  Future<void> imgFromCamera(BuildContext parentContext) async {
    // Get location data
    LocationData? locationData = await _getLocation();

    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (pickedFile != null) {
      final tempFile = File(pickedFile.path);
      if(mounted) {
        setState(() {
          _photo = tempFile;
          _selectedFileBytes = _photo!.readAsBytesSync(); // ✅ Convert to bytes for preview
          _selectedFileName = "${widget.meterNumber}.jpg"; // ✅ Rename file // Set the image without uploading
        });
      }
      print("Camera image selected: $_selectedFileName");

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


  Future<bool> uploadFile(double latitude, double longitude) async {
    if (_photo == null) {
      print('No image selected.');
      Fluttertoast.showToast(msg: "Please select an image first!");
      return false; // ✅ Return false if no image was selected
    }

    final String fileName = '${widget.meterNumber}.jpg';
    final String destination =
        'files/meters/$formattedDate/${widget.userNumber}/${widget.propertyAddress}/water/$fileName';

    try {
      final ref = firebase_storage.FirebaseStorage.instance.ref(destination);
      final mimeType = lookupMimeType(_photo!.path) ?? 'application/octet-stream';
      final metadata = firebase_storage.SettableMetadata(contentType: mimeType);

      await ref.putFile(_photo!, metadata);
      String fileUrl = await ref.getDownloadURL();
      print('Image uploaded successfully to: $destination');
      print('File URL: $fileUrl');

      await logWMeterUploadAction(
        fileUrl,
        "Upload Water Meter Image",
        widget.userNumber,
        widget.propertyAddress,
        widget.municipalityUserEmail,
        latitude,
        longitude,
      );

      if (mounted) {
        setState(() {
          _photo = null;
        });
      }

      // ✅ Return true to indicate successful upload
      return true;
    } catch (e) {
      print('Error uploading image: $e');
      return false; // ✅ Return false if upload failed
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
                  if (_photo != null || (_selectedFileBytes != null && _selectedFileName != null)) {
                    if (mounted) {
                      setState(() {
                        isLoading = true;
                      });
                    }
                    try {
                      bool uploadSuccess = false;

                      if (_selectedFileBytes != null && _selectedFileName != null) {
                        await _uploadFileToFirebase(_selectedFileBytes!, _selectedFileName!);
                        uploadSuccess = true; // ✅ Set to true if upload is successful
                      } else if (_photo != null) {
                        uploadSuccess = await uploadFile(latitude ?? 0.0, longitude ?? 0.0); // ✅ Capture return value
                      }

                      if (uploadSuccess) {
                        // ✅ Fetch document snapshot after successful upload
                        await _fetchDocumentSnapshot();

                        // ✅ Show UI only if document snapshot is available
                        if (documentSnapshot != null) {
                          await _showMeterReadingUpdateUI(context);
                          Navigator.of(context).pop(true); // ✅ Return true to indicate success
                        } else {
                          Fluttertoast.showToast(msg: "Error: Could not fetch property details after upload.");
                        }

                        Fluttertoast.showToast(msg: "Successfully Uploaded!\nWater Meter Image!");
                      }
                    } catch (e) {
                      print("Error uploading image: $e");
                    } finally {
                      if (mounted) {
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
