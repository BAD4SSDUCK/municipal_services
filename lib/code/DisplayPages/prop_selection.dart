import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';
import 'dashboard.dart';
import 'display_info.dart';
import 'package:provider/provider.dart';

class PropertySelectionScreen extends StatefulWidget {
  final List<Property> properties;
  final String userPhoneNumber;
  final bool isLocalMunicipality;
  final bool handlesWater;
  final bool handlesElectricity;
  const PropertySelectionScreen({super.key, required this.userPhoneNumber, required this.properties, required this.isLocalMunicipality, required this.handlesWater,
    required this.handlesElectricity,});

  @override
  _PropertySelectionScreenState createState() => _PropertySelectionScreenState();
}

class _PropertySelectionScreenState extends State<PropertySelectionScreen> {
  List<Property> properties = [];
  List<Property> filteredProperties = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = true;
  String? districtId;
  String municipalityId = '';
  bool get handlesWater => widget.handlesWater;
  bool get handlesElectricity => widget.handlesElectricity;
  

  @override
  void initState() {
    super.initState();
    print('PropertySelectionScreen initialized.');
    print('User phone number: ${widget.userPhoneNumber}');
    print('Number of properties passed: ${widget.properties.length}');

    // Assign the passed properties to the local properties list
    properties = widget.properties;
    filteredProperties = properties;

    searchController.addListener(() {
      filterProperties();
    });
       if(mounted) {
         setState(() {
           _isLoading = false;
         });
       }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String? userPhoneNumber = user?.phoneNumber;

      if (userPhoneNumber != null) {
        QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('cellNumber', isEqualTo: userPhoneNumber)
            .limit(1)
            .get();

        if (propertySnapshot.docs.isNotEmpty) {
          var propertyDoc = propertySnapshot.docs.first;
          final propertyData = Property.fromSnapshot(propertyDoc);

          if (propertyData.isLocalMunicipality) {
            districtId = null; // No districtId for local municipalities
            municipalityId = propertyData.municipalityId;
          } else {
            final propertyPathSegments = propertyDoc.reference.path.split('/');
            districtId = propertyPathSegments[1]; // Get the district ID
            municipalityId = propertyPathSegments[3]; // Get the municipality ID
          }

          print('District ID: $districtId');
          print('Municipality ID: $municipalityId');

          setState(() {
            // Update state if needed
          });
        } else {
          print('No properties found for this phone number.');
        }
      } else {
        print('User phone number is null.');
      }
    } catch (e) {
      print('Error fetching district and municipality ID: $e');
    }
  }

  Future<LatLng?> generateCoordinatesForAddress(String address) async {
    const apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY';
    final encodedAddress = Uri.encodeComponent(address);
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final location = data['results'][0]['geometry']['location'];
        return LatLng(location['lat'], location['lng']);
      } else {
        print("No coordinates found for address: $address");
        return null;
      }
    } catch (e) {
      print("Error fetching coordinates for $address: $e");
      return null;
    }
  }

  // Method to check and save coordinates for the selected property
  Future<void> checkAndGenerateCoordinates(Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';
    // Define the Firestore query to locate the document by account number
    QuerySnapshot querySnapshot;
    if (property.isLocalMunicipality) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(property.municipalityId)
          .collection('properties')
          .where(accountField, isEqualTo: selectedPropertyAccountNumber)
          .limit(1)
          .get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(property.districtId)
          .collection('municipalities')
          .doc(property.municipalityId)
          .collection('properties')
          .where(accountField, isEqualTo: selectedPropertyAccountNumber)
          .limit(1)
          .get();
    }

    // Ensure we found the document
    if (querySnapshot.docs.isEmpty) {
      print("No property document found for account number: ${property.accountNo}");
      return;
    }

    // Get the first document that matches the account number
    DocumentSnapshot propertyDoc = querySnapshot.docs.first;
    DocumentReference propertyRef = propertyDoc.reference;

    // Check if the coordinates are missing
    Map<String, dynamic>? data = propertyDoc.data() as Map<String, dynamic>?;
    final lat = data?['latitude'];
    final lng = data?['longitude'];

    // Generate and save coordinates if they are missing
    if (lat == null || lng == null) {
      print("Coordinates missing for ${property.address}. Generating...");
      LatLng? coordinates = await generateCoordinatesForAddress(property.address);

      if (coordinates != null) {
        await propertyRef.update({
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        });
        print("Coordinates saved for property: ${property.address}");
      } else {
        print("Failed to generate coordinates for ${property.address}");
      }
    } else {
      print("Coordinates already exist for ${property.address}: ($lat, $lng)");
    }
  }


  Future<void> storeTokenForAccount(String accountNumber, String token, Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';

    try {
      QuerySnapshot querySnapshot;
      if (property.isLocalMunicipality) {
        // Use local municipality path if isLocalMunicipality is true
        querySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      } else {
        // Use district path if isLocalMunicipality is false
        querySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(property.districtId)
            .collection('municipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = querySnapshot.docs.first;
        await propertyDoc.reference.update({
          'token': token,
        });

        print("Token stored successfully for account: $accountNumber");
      } else {
        print("No property found with account number: $accountNumber");
      }
    } catch (e) {
      print('Error storing token for account: $e');
    }
  }

  void filterProperties() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredProperties = properties.where((property) {
        String address = property.address.toLowerCase();
        return address.contains(query);
      }).toList();
    });
  }

  Future<void> saveSelectedPropertyAccountNo(Property property, bool handlesWater, bool handlesElectricity) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      final accountNo = handlesElectricity && !handlesWater
          ? property.electricityAccountNo
          : property.accountNo;

      // Save which field was used for lookup
      final accountField = handlesElectricity && !handlesWater
          ? 'electricityAccountNumber'
          : 'accountNumber';

      await prefs.setString('selectedPropertyAccountNo', accountNo);
      await prefs.setString('selectedPropertyAccountField', accountField);
      await prefs.setBool('isLocalMunicipality', property.isLocalMunicipality);

      if (property.isLocalMunicipality) {
        await prefs.remove('districtId');
      } else {
        await prefs.setString('districtId', property.districtId);
      }

      await prefs.setString('municipalityId', property.municipalityId);

      print("✅ Saved: $accountNo under $accountField (isLocal: ${property.isLocalMunicipality})");
    } catch (e) {
      print("Error saving selected property: $e");
    }
  }



  Future<bool> checkAddressConfirmation(Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';

    try {
      QuerySnapshot querySnapshot;
      if (property.isLocalMunicipality) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(property.districtId)
            .collection('municipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = querySnapshot.docs.first;
        return propertyDoc['isAddressConfirmed'] ?? false;
      } else {
        print("No property document found.");
        return false;
      }
    } catch (e) {
      print("Error checking address confirmation: $e");
      return false;
    }
  }

  Future<void> showAddressConfirmationDialog(
      BuildContext context, Property property, DocumentReference propertyRef) async {
    TextEditingController addressController = TextEditingController(text: property.address);
    bool isEditing = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Confirm Your Address",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      if (isEditing) ...[
                        const Text(
                          "Edit your address below:",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Address",
                            hintText: "Enter your address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "Is this your correct address?",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            addressController.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (isEditing) {
                                // Save the edited address
                                await propertyRef.update({
                                  'address': addressController.text,
                                  'isAddressConfirmed': true,
                                });
                                print("Address updated: ${addressController.text}");
                              } else {
                                // Mark the address as confirmed
                                await propertyRef.update({'isAddressConfirmed': true});
                                print("Address confirmed.");
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              isEditing ? "Save" : "Confirm",
                              style: TextStyle(
                                color: isEditing ? Colors.orange : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!isEditing)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                if(mounted) {
                                  setState(() {
                                    isEditing = true;
                                  });
                                }
                              },
                              child: const Text(
                                "Edit Address",
                                style: TextStyle(color: Colors.blue),
                              ),
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

  Future<void> saveEditedAddress(Property property, String newAddress) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';
    try {
      QuerySnapshot querySnapshot;
      if (property.isLocalMunicipality) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(property.districtId)
            .collection('municipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = querySnapshot.docs.first;
        await propertyDoc.reference.update({
          'address': newAddress,
          'isAddressConfirmed': true,
        });
        print("Address updated and confirmed.");
      } else {
        print("No property document found for account number: ${property.accountNo}");
      }
    } catch (e) {
      print("Error saving edited address: $e");
    }
  }

  Future<void> confirmAddress(Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';
    try {
      QuerySnapshot querySnapshot;
      if (property.isLocalMunicipality) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(property.districtId)
            .collection('municipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot propertyDoc = querySnapshot.docs.first;
        await propertyDoc.reference.update({
          'isAddressConfirmed': true,
        });
        print("Address confirmed.");
      } else {
        print("No property document found for account number: ${property.accountNo}");
      }
    } catch (e) {
      print("Error confirming address: $e");
    }
  }

  Future<DocumentSnapshot?> getPropertyDocument(Property property) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
    String? accountField = prefs.getString('selectedPropertyAccountField') ?? 'accountNumber';
    try {
      if (property.isLocalMunicipality) {
        return await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
      } else {
        return await FirebaseFirestore.instance
            .collection('districts')
            .doc(property.districtId)
            .collection('municipalities')
            .doc(property.municipalityId)
            .collection('properties')
            .where(accountField, isEqualTo: selectedPropertyAccountNumber)
            .limit(1)
            .get()
            .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
      }
    } catch (e) {
      print("Error fetching property document: $e");
      return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyProvider>(
      builder: (context, propertyProvider, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/greyscale.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: const Text(
                'Select Your Property',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 21),
              ),
              backgroundColor: Colors.green,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by address',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProperties.isEmpty
                      ? const Center(child: Text('No properties found.'))
                      : ListView.builder(
                    itemCount: filteredProperties.length,
                    itemBuilder: (context, index) {
                      final property = filteredProperties[index];
                      return Card(
                        color: Colors.white70,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.home, color: Colors.green),
                          title: Text(
                            property.address,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            'Account: ${property.accountNo}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () async {
                            print("Property selected: ${property.address} - Account No: ${property.accountNo}");

                            // Set districtId and municipalityId based on the selected property
                            if (property.isLocalMunicipality) {
                              districtId = null;
                              municipalityId = property.municipalityId;
                            } else {
                              districtId = property.districtId;
                              municipalityId = property.municipalityId;
                            }

                            if (municipalityId.isEmpty) {
                              print("Error: Municipality ID is missing.");
                              return;
                            }

                            DocumentSnapshot? propertyDoc = await getPropertyDocument(property);

                            if (propertyDoc == null) {
                              print("Property document not found.");
                              return;
                            }

                            DocumentReference propertyRef = propertyDoc.reference;
                            Map<String, dynamic>? data = propertyDoc.data() as Map<String, dynamic>?;

                            // Check if the address is already confirmed
                            bool isAddressConfirmed = data?['isAddressConfirmed'] ?? false;

                            if (!isAddressConfirmed) {
                              // Show confirmation dialog
                              await showAddressConfirmationDialog(context, property, propertyRef);
                            } else {
                              print("Address already confirmed.");
                            }


                            await saveSelectedPropertyAccountNo(property, widget.handlesWater, widget.handlesElectricity);
                            await checkAndGenerateCoordinates(property);

                            // ✅ Use Provider safely with proper context
                            if (mounted) {
                              propertyProvider.selectProperty(property, handlesWater: handlesWater, handlesElectricity: handlesElectricity);
                            }

                            // Retrieve the user's token
                            String? token = await FirebaseMessaging.instance.getToken();
                            if (token != null) {
                              print("User's token: $token");
                              // Store the token with the account number
                              await storeTokenForAccount(property.accountNo, token, property);
                            } else {
                              print("Error: Could not retrieve token.");
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainMenu(
                                  property: property,
                                  propertyCount: properties.length,
                                  isLocalMunicipality: widget.isLocalMunicipality,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
