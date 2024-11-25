import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:municipal_services/code/MapTools/map_screen_multi.dart';
import 'package:municipal_services/code/ReportGeneration/display_capture_report.dart';



const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreenMultiInvert extends StatefulWidget {
  const MapScreenMultiInvert({super.key,});

  @override
  State<MapScreenMultiInvert> createState() => _MapScreenMultiInvertState();
}


class _MapScreenMultiInvertState extends State<MapScreenMultiInvert> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = <Marker>{};
  late BitmapDescriptor sourceIcon;
  bool _isLoading = true;
  late CameraPosition _cameraPosition;
  bool isLocalMunicipality = false;
  String districtId = '';
  String municipalityId = '';
  CollectionReference<Map<String, dynamic>>? _propertyCollection;
  Query<Map<String, dynamic>>? _propertyQuery;
  List<String> municipalityOptions = ["All Municipalities"];
  String selectedMunicipality = "All Municipalities";
  MapType _currentMapType = MapType.normal;
  List _allPropResults = [];
  bool isLocalUser = true;
  String? userEmail;
  bool isLoading = false;
  bool adminAcc = false;
  bool visAdmin = false;
  bool visManager = false;
  bool visEmployee = false;
  bool visCapture = false;
  bool visDev = false;
  String userRole = '';
  String userDept = '';
  String location ='Null, Press Button';
  String Address = 'search';

  @override
  void initState() {
    super.initState();
    initializeMapData();
  }

  Future<void> initializeMapData() async {
    await fetchUserDetails();
    await setSourceAndDestinationMarkerIcons();
    await fetchMunicipalities();
    await fetchCompletedCaptures();
    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchUserDetails() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        userEmail = user.email ?? ''; // Ensure userEmail is correctly set
        print("User email initialized: $userEmail");

        // Fetch the user document from Firestore using collectionGroup
        QuerySnapshot userSnapshot = await FirebaseFirestore.instance
            .collectionGroup('users')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          var userDoc = userSnapshot.docs.first;
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          var userPathSegments = userDoc.reference.path.split('/');

          // Determine if the user belongs to a district or local municipality
          if (userPathSegments.contains('districts')) {
            // District-based municipality
            districtId = userPathSegments[1];
            municipalityId = userPathSegments[3];
            isLocalMunicipality = false;
            print("District User Detected");
          } else if (userPathSegments.contains('localMunicipalities')) {
            // Local municipality
            municipalityId = userPathSegments[1];
            districtId = ''; // No district for local municipality
            isLocalMunicipality = true;
            print("Local Municipality User Detected");
          }

          // Safely access the 'isLocalUser' field
          isLocalUser = userData['isLocalUser'] ?? false;

          print("After fetchUserDetails:");
          print("districtId: $districtId");
          print("municipalityId: $municipalityId");
          print("isLocalMunicipality: $isLocalMunicipality");
          print("isLocalUser: $isLocalUser");

          // Fetch properties based on the municipality type
          if (isLocalMunicipality) {
            await fetchPropertiesForLocalMunicipality();
          } else if (!isLocalMunicipality) {
            await fetchPropertiesForAllMunicipalities();
          } else if (municipalityId.isNotEmpty) {
            await fetchPropertiesByMunicipality(municipalityId);
          } else {
            print("Error: municipalityId is empty for the local municipality user.");
          }
        } else {
          print('No user document found.');
        }
      } else {
        print("No current user found.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchMunicipalities() async {
    if (districtId.isNotEmpty) {
      try {
        var municipalitiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .get();

        setState(() {
          municipalityOptions = ["All Municipalities"];
          municipalityOptions.addAll(municipalitiesSnapshot.docs.map((doc) => doc.id).toSet());
          selectedMunicipality = "All Municipalities";
        });
      } catch (e) {
        print('Error fetching municipalities: $e');
      }
    }
  }

  Future<void> fetchPropertiesForAllMunicipalities() async {
    try {
      QuerySnapshot propertiesSnapshot;

      // Check if no specific municipality is selected
      if (selectedMunicipality == null || selectedMunicipality == "All Municipalities") {
        // Fetch properties for all municipalities in the district
        print("Fetching properties for all municipalities under district: $districtId");
        propertiesSnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('districtId', isEqualTo: districtId) // Ensure filtering by district
            .get();

        if (mounted) {
          setState(() {
            _allPropResults = propertiesSnapshot.docs;
            print('Fetched ${_allPropResults.length} properties.');
          });
        }
      } else {
        // Fetch properties for the selected municipality
        print("Fetching properties for municipality: $selectedMunicipality");
        propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(selectedMunicipality)
            .collection('properties')
            .get();

        if (mounted) {
          setState(() {
            _allPropResults = propertiesSnapshot.docs;
            print('Properties fetched for $selectedMunicipality: ${_allPropResults.length}');
          });
        }
      }
    } catch (e) {
      print('Error fetching properties: $e');
    }
  }

  Future<void> fetchPropertiesForLocalMunicipality() async {
    if (municipalityId.isEmpty) {
      print("Error: municipalityId is empty. Cannot fetch properties.");
      return;
    }

    try {
      print("Fetching properties for local municipality: $municipalityId");

      // Fetch properties only for the specific municipality the user belongs to
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId) // The local municipality ID for the user
          .collection('properties')
          .get();

      // Check if any properties were fetched
      if (propertiesSnapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _allPropResults =
                propertiesSnapshot.docs; // Store fetched properties
          });
        }
        print('Properties fetched for local municipality: $municipalityId');
        print(
            'Number of properties fetched: ${propertiesSnapshot.docs.length}');
      } else {
        print("No properties found for local municipality: $municipalityId");
      }
    } catch (e) {
      print('Error fetching properties for local municipality: $e');
    }
  }

  Future<void> fetchPropertiesByMunicipality(String municipality) async {
    try {
      // Fetch properties for the selected municipality
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipality)
          .collection('properties')
          .get();

      // Log the properties fetched
      print(
          'Properties fetched for $municipality: ${propertiesSnapshot.docs.length}');
      if (mounted) {
        setState(() {
          _allPropResults =
              propertiesSnapshot.docs; // Store filtered properties
          print(
              "Number of properties fetched: ${_allPropResults.length}"); // Debugging to ensure properties are set
        });
      }
    } catch (e) {
      print('Error fetching properties for $municipality: $e');
    }
  }

//   Future<void> fetchCompletedCaptures() async {
//     _markers.clear();
//
//     try {
//       print("Determining query type based on selectedMunicipality: $selectedMunicipality");
//
//       // Set up the query for district-level users when "All Municipalities" is selected
//       if (!isLocalMunicipality && selectedMunicipality == "All Municipalities") {
//         print("Setting up collectionGroup query for all properties under district: $districtId");
//
//         // Initialize _propertyQuery for all municipalities under the district
//         _propertyQuery = FirebaseFirestore.instance
//             .collectionGroup('properties')
//             .where('districtId', isEqualTo: districtId)
//             .where('imgStateW', isEqualTo: true); // Filter only outstanding captures
//
//         print("CollectionGroup query initialized for all municipalities under district.");
//       }
//
//       // Set up query for a specific municipality
//       if (!isLocalMunicipality && selectedMunicipality != "All Municipalities") {
//         print("Setting up query for a specific municipality: $selectedMunicipality");
//
//         // Query properties for the selected municipality only
//         _propertyQuery = FirebaseFirestore.instance
//             .collection('districts')
//             .doc(districtId)
//             .collection('municipalities')
//             .doc(selectedMunicipality)
//             .collection('properties')
//             .where('imgStateW', isEqualTo: false); // Filter only outstanding captures
//
//         print("Query initialized for municipality: $selectedMunicipality.");
//       }
//
//       // Check if _propertyQuery is still null before proceeding
//       if (_propertyQuery == null) {
//         print("Error: _propertyQuery remains null, cannot proceed with collectionGroup query.");
//         return;
//       }
//
//       // Fetch properties from the query
//       QuerySnapshot propertiesSnapshot = await _propertyQuery!.get();
//       print("Fetched ${propertiesSnapshot.docs.length} properties across all municipalities.");
//
//       for (var doc in propertiesSnapshot.docs) {
//         try {
//           // Document data
//           final propertyData = doc.data() as Map<String, dynamic>;
//
//           // Check for outstanding capture (imgStateW == false)
//           bool? imgStateW = propertyData['imgStateW'];
//           if (imgStateW == false) {
//             final String? address = propertyData['address'] as String?;
//
//             if (address != null && address.isNotEmpty) {
//               print("Processing property with address: $address");
//
//               // Use the same address conversion logic as in `MapScreenProp`
//               await addressConvertAndAddMarker(address, doc.id);
//             } else {
//               print("Address is null or empty for document ID: ${doc.id}, skipping.");
//             }
//           } else {
//             print("Property ${doc.id} does not have outstanding captures.");
//           }
//         } catch (e) {
//           print("Error processing document ID: ${doc.id} - Error: $e");
//         }
//       }
//
//       if (mounted) {
//         setState(() {}); // Refresh map with markers
//       }
//     } catch (e) {
//       print("Error fetching outstanding captures: $e");
//     }
//   }
//   Future<void> addressConvertAndAddMarker(String address, String docId) async {
//     await googleMapsAddressConversion(address, docId);
//   }
//
// // Google Maps API Address Conversion Function
//   Future<void> googleMapsAddressConversion(String address, String docId) async {
//     final apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY'; // Use your actual API key here
//     final encodedAddress = Uri.encodeComponent(address);
//     final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//         final location = data['results'][0]['geometry']['location'];
//         LatLng coordinates = LatLng(location['lat'], location['lng']);
//
//         if (mounted) {
//           setState(() {
//             _markers.add(Marker(
//               markerId: MarkerId(docId),
//               position: coordinates,
//               icon: sourceIcon,
//               infoWindow: InfoWindow(
//                 title: address,
//                 snippet: 'Outstanding Capture',
//               ),
//             ));
//           });
//         }
//         print("Marker added via Google Maps API for address: $address at coordinates: $coordinates");
//       } else {
//         print("Google Maps API returned no results for address: $address");
//         addDefaultMarker(address, docId);
//       }
//     } catch (e) {
//       print("Google Maps API error for address $address: $e");
//       addDefaultMarker(address, docId);
//     }
//   }
//
// // Default Marker Function (for unfound addresses)
//   void addDefaultMarker(String address, String docId) {
//     LatLng defaultLocation = LatLng(-29.601505328570788, 30.379442518631805);
//
//     if (mounted) {
//       setState(() {
//         _markers.add(Marker(
//           markerId: MarkerId(docId),
//           position: defaultLocation,
//           icon: sourceIcon,
//           infoWindow: InfoWindow(
//             title: address,
//             snippet: 'Default Location (Address not found)',
//           ),
//         ));
//       });
//     }
//     print("Default marker added for address: $address at coordinates: $defaultLocation");
//   }
//
//   // Consolidated locateAndMarkAddress function
//   Future<void> locateAndMarkAddress(String address, String docId) async {
//     try {
//       print("Attempting to locate address: $address");
//
//       List<Location> locations = await locationFromAddress(address);
//
//       if (locations.isEmpty) {
//         print("No locations found for address: $address, skipping.");
//         return;
//       }
//
//       Location location = locations.first;
//       LatLng coordinates = LatLng(location.latitude, location.longitude);
//
//       if (mounted) {
//         setState(() {
//           _markers.add(Marker(
//             markerId: MarkerId(docId),
//             position: coordinates,
//             icon: sourceIcon,
//             infoWindow: InfoWindow(
//               title: address,
//               snippet: 'Completed Capture',
//             ),
//           ));
//         });
//       }
//       print("Marker added for address: $address at coordinates: $coordinates");
//     } catch (e) {
//       print("Error locating address $address: $e");
//     }
//   }
//
// // The setSourceAndDestinationMarkerIcons method and sourceIcon initialization should match the successful implementation in MapScreenProp
//   Future<void> setSourceAndDestinationMarkerIcons() async {
//     if (defaultTargetPlatform == TargetPlatform.android) {
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(devicePixelRatio: 2.0),
//         'assets/images/location/source_pin_android.png',
//       );
//     } else {
//       sourceIcon = await BitmapDescriptor.fromAssetImage(
//         const ImageConfiguration(devicePixelRatio: 0.5, size: Size(35, 50)),
//         'assets/images/location/source_pin_android.png',
//       );
//     }
//   }
//   Future<void> generateCoordinatesForProperties(List<QueryDocumentSnapshot<Object?>> properties) async {
//     for (var property in properties) {
//       var propertyData = property.data() as Map<String, dynamic>;
//       String address = propertyData['address'] ?? '';
//
//       // Check if coordinates are missing
//       if (propertyData['latitude'] == null || propertyData['longitude'] == null) {
//         print('Coordinates missing for $address. Generating...');
//
//         // Attempt to fetch and save coordinates
//         LatLng? coordinates = await generateCoordinatesForAddress(address);
//
//         if (coordinates != null) {
//           // Update Firestore document with generated coordinates
//           await property.reference.update({
//             'latitude': coordinates.latitude,
//             'longitude': coordinates.longitude,
//           });
//           print('Coordinates for $address written to Firestore: $coordinates');
//         } else {
//           print('Failed to get updated coordinates for $address.');
//         }
//       }
//     }
//   }
//   Future<LatLng?> generateCoordinatesForAddress(String address) async {
//     const apiKey = 'AIzaSyCsOGfD-agV8u68pCfeCManNNoSs4csIbY'; // Replace with your actual API key
//     final encodedAddress = Uri.encodeComponent(address);
//     final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';
//
//     try {
//       final response = await http.get(Uri.parse(url));
//       final data = json.decode(response.body);
//
//       if (data['status'] == 'OK' && data['results'].isNotEmpty) {
//         final location = data['results'][0]['geometry']['location'];
//         LatLng coordinates = LatLng(location['lat'], location['lng']);
//         print("Generated coordinates for $address: $coordinates");
//         return coordinates;
//       } else {
//         print("Google Maps API returned no results for address: $address");
//       }
//     } catch (e) {
//       print("Google Maps API error for address $address: $e");
//     }
//     return null; // Return null if no coordinates found or an error occurred
//   }
//
//
//
//
//   Future<void> fetchCompletedCaptures() async {
//     _markers.clear();
//
//     try {
//       print("Determining query type based on selectedMunicipality: $selectedMunicipality");
//
//       // Set up the query for district-level users when "All Municipalities" is selected
//       if (!isLocalMunicipality && selectedMunicipality == "All Municipalities") {
//         print("Setting up collectionGroup query for all properties under district: $districtId");
//
//         _propertyQuery = FirebaseFirestore.instance
//             .collectionGroup('properties')
//             .where('districtId', isEqualTo: districtId)
//             .where('imgStateW', isEqualTo: false); // Filter only outstanding captures
//
//         print("CollectionGroup query initialized for all municipalities under district.");
//       }
//
//       // Set up query for a specific municipality
//       if (!isLocalMunicipality && selectedMunicipality != "All Municipalities") {
//         print("Setting up query for a specific municipality: $selectedMunicipality");
//
//         _propertyQuery = FirebaseFirestore.instance
//             .collection('districts')
//             .doc(districtId)
//             .collection('municipalities')
//             .doc(selectedMunicipality)
//             .collection('properties')
//             .where('imgStateW', isEqualTo: true); // Filter only outstanding captures
//
//         print("Query initialized for municipality: $selectedMunicipality.");
//       }
//
//       if (_propertyQuery == null) {
//         print("Error: _propertyQuery remains null, cannot proceed with collectionGroup query.");
//         return;
//       }
//
//       QuerySnapshot propertiesSnapshot = await _propertyQuery!.get();
//       print("Fetched ${propertiesSnapshot.docs.length} properties across all municipalities.");
//
//       for (var doc in propertiesSnapshot.docs) {
//         var propertyData = doc.data() as Map<String, dynamic>;
//         final String address = propertyData['address'] ?? '';
//         final lat = propertyData['latitude'];
//         final lng = propertyData['longitude'];
//
//         if (lat == null || lng == null) {
//           print("Coordinates missing for $address. Generating...");
//
//           // Generate coordinates for the address
//           final coordinates = await generateCoordinatesForAddress(address);
//
//           if (coordinates != null) {
//             final latitude = coordinates.latitude;
//             final longitude = coordinates.longitude;
//
//             // Update Firestore document with the new coordinates
//             await doc.reference.update({
//               'latitude': latitude,
//               'longitude': longitude,
//             });
//
//             print("Coordinates saved for property: $address");
//
//             // Add marker with the new coordinates
//             addMarker(latitude, longitude, doc.id, address);
//           } else {
//             print("Failed to get updated coordinates for $address.");
//           }
//         } else {
//           // Add marker directly if coordinates are available
//           addMarker(lat, lng, doc.id, address);
//         }
//       }
//
//       if (mounted) {
//         setState(() {}); // Refresh map with markers
//       }
//     } catch (e) {
//       print("Error fetching outstanding captures: $e");
//     }
//   }

  Future<void> fetchCompletedCaptures() async {
    _markers.clear();

    try {
      if (selectedMunicipality == 'All Municipalities') {
        // Fetch for all municipalities
        await fetchAllMunicipalitiesOutstandingCaptures();
      } else {
        // Fetch for a single municipality
        await fetchSingleMunicipalityOutstandingCaptures(selectedMunicipality);
      }
      if(mounted){
        setState(() {});} // Refresh map with markers
    } catch (e) {
      print("Error fetching outstanding captures: $e");
    }
  }

// Function to fetch outstanding captures for all municipalities under the district
  Future<void> fetchAllMunicipalitiesOutstandingCaptures() async {
    try {
      // Fetch the list of municipalities for the district
      List<String> municipalityIds = await fetchMunicipalitiesUnderDistrict(districtId);

      List<Map<String, dynamic>> allProperties = [];

      // Fetch properties with imgStateW == false for each municipality separately
      for (String municipalityId in municipalityIds) {
        QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('properties')
            .where('imgStateW', isEqualTo: true)
            .get();

        // Add each property's data to the aggregate list if coordinates are valid
        for (var doc in propertiesSnapshot.docs) {
          var propertyData = doc.data() as Map<String, dynamic>;
          double? lat = propertyData['latitude'];
          double? lng = propertyData['longitude'];

          if (lat != null && lng != null) {
            allProperties.add({...propertyData, 'docId': doc.id});
          }
        }
      }

      // Now add markers for all fetched properties
      for (var propertyData in allProperties) {
        double lat = propertyData['latitude'];
        double lng = propertyData['longitude'];
        String docId = propertyData['docId'];
        String address = propertyData['address'];

        addMarker(lat, lng, docId, address);
      }
    } catch (e) {
      print("Error fetching outstanding captures for all municipalities: $e");
    }
  }

// Function to fetch outstanding captures for a single municipality
  Future<void> fetchSingleMunicipalityOutstandingCaptures(String municipalityId) async {
    try {
      QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('properties')
          .where('imgStateW', isEqualTo: true)
          .get();

      for (var doc in propertiesSnapshot.docs) {
        var propertyData = doc.data() as Map<String, dynamic>;
        double? lat = propertyData['latitude'];
        double? lng = propertyData['longitude'];

        if (lat != null && lng != null) {
          String docId = doc.id;
          String address = propertyData['address'];
          addMarker(lat, lng, docId, address);
        }
      }
    } catch (e) {
      print("Error fetching outstanding captures for municipality $municipalityId: $e");
    }
  }

// Helper function to fetch municipalities under a district
  Future<List<String>> fetchMunicipalitiesUnderDistrict(String districtId) async {
    QuerySnapshot municipalitiesSnapshot = await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .get();
    return municipalitiesSnapshot.docs.map((doc) => doc.id).toList();
  }

  LatLng _getOffsetLatLng(LatLng originalLatLng, int offsetIndex) {
    const double offsetFactor = 0.00005; // Change this value to adjust how far apart the markers are
    return LatLng(
      originalLatLng.latitude + (offsetIndex * offsetFactor),
      originalLatLng.longitude + (offsetIndex * offsetFactor),
    );
  }


  /// Keep track of existing marker positions to handle overlaps
  Map<String, int> _markerOverlapCounter = {};

  void addMarker(double lat, double lng, String docId, String address) {
    if (mounted) {
      LatLng position = LatLng(lat, lng);
      String positionKey = '${position.latitude},${position.longitude}';

      // Check for overlaps at this position and apply offset if needed
      int offsetIndex = _markerOverlapCounter[positionKey] ?? 0;
      if (offsetIndex > 0) {
        // Apply an offset to prevent overlap
        position = _getOffsetLatLng(position, offsetIndex);
      }
      if(mounted) {
        setState(() {
          _markers.add(Marker(
            markerId: MarkerId(docId),
            position: position,
            icon: sourceIcon,
            infoWindow: InfoWindow(
              title: address,
              snippet: 'Outstanding Capture',
            ),
          ));
        });
      }

      // Increment the overlap counter for this position
      _markerOverlapCounter[positionKey] = offsetIndex + 1;

      print("Marker added for $address at LatLng(${position.latitude}, ${position.longitude})");
    } else {
      print("Marker not added for $address: Invalid criteria.");
    }
  }


  Future<void> setSourceAndDestinationMarkerIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 1.0),
      'assets/images/location/marker_green.png',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submitted Captures', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        actions: [
          // Reports section
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 16), // Add spacing between Reports and Submitted Captures
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportBuilderCaptured(
                          isLocalMunicipality: isLocalMunicipality,
                          isLocalUser: isLocalUser,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Reports',
                    style: GoogleFonts.jacquesFrancois(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportBuilderCaptured(
                          isLocalMunicipality: isLocalMunicipality,
                          isLocalUser: isLocalUser,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_copy_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          // Submitted Captures section
          Row(
            children: [
              Text(
                'Outstanding Captures',
                style: GoogleFonts.jacquesFrancois(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const MapScreenMulti()));
                },
                icon: const Icon(Icons.credit_card_off_outlined, color: Colors.white),
              ),
            ],
          ),
        ],
      ),

      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            myLocationEnabled: true,
            markers: _markers,
            mapType: _currentMapType,
            initialCameraPosition: const CameraPosition(
              target: LatLng(-29.601505328570788, 30.379442518631805),
              zoom: 10,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
          Positioned(
            top: 20,
            left: 10,
            right: 10,
            child: DropdownButton<String>(
              value: municipalityOptions.contains(selectedMunicipality)
                  ? selectedMunicipality
                  : "All Municipalities",
              onChanged: (String? newValue) async {
                setState(() {
                  selectedMunicipality = newValue!;
                });
                await fetchPropertiesForAllMunicipalities();
                await fetchCompletedCaptures();
              },
              items: municipalityOptions.map((String municipality) {
                return DropdownMenuItem<String>(
                  value: municipality,
                  child: Text(municipality),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom:40,
            left: 10,
            child: FloatingActionButton(
              heroTag: "map_type_button",
              onPressed: () {
                setState(() {
                  _currentMapType = _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
                });
              },
              child: const Icon(Icons.map),
            ),
          ),
        ],
      ),
    );
  }

}