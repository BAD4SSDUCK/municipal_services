import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_user_badge.dart';


const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreen extends StatefulWidget {
  const MapScreen({
    Key? key,
    required this.isLocalMunicipality, // Added this parameter
    required this.districtId,          // Added districtId
    required this.municipalityId       // Added municipalityId
  }) : super(key: key);

  final bool isLocalMunicipality; // Local municipality flag
  final String districtId;        // District ID
  final String municipalityId;    // Municipality ID

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late CameraPosition _cameraPosition;
  late LatLng currentLocation;
  late LatLng addressLocation;
  late bool _isLoading;

  String location = 'Null, Press Button';
  String address = 'search';

  @override
  void initState() {
    _isLoading = true;
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isLoading = false;
      });
    });

    locationAllow(); // Capture user's location
    super.initState();

    addressConvert(); // Convert address to LatLng coordinates
    setInitialLocation(); // Set initial location
    setSourceAndDestinationMarkerIcons(); // Set marker icons
  }

  late GoogleMapController _mapController;
  late BitmapDescriptor sourceIcon;
  final Set<Marker> _markers = <Marker>{};

  /// Check current user's location
  Future<void> locationAllow() async {
    Position position = await _getGeoLocationPosition();
    location = 'Lat: ${position.latitude} , Long: ${position.longitude}';
    GetAddressFromLatLong(position);
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> GetAddressFromLatLong(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    address = '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
  }

  /// Set source and destination marker icons
  void setSourceAndDestinationMarkerIcons() async {
    sourceIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(devicePixelRatio: 2.0),
        'assets/images/location/source_pin_android.png');
  }

  /// Convert the given address to LatLng
  void addressConvert() async {
    String address = locationGiven;

    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        double latitude = location.latitude;
        double longitude = location.longitude;

        currentLocation = LatLng(latitude, longitude);
        showPinOnMap();
      }

      _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);

    } catch (e) {
      currentLocation = LatLng(-29.601505328570788, 30.379442518631805);
      _cameraPosition = CameraPosition(target: currentLocation, zoom: 16);
      showPinOnMap();
      Fluttertoast.showToast(msg: "Address not found! Default map location City Hall!", gravity: ToastGravity.CENTER);
    }
  }

  void setInitialLocation() async {
    currentLocation = LatLng(
        SOURCE_LOCATION.latitude,
        SOURCE_LOCATION.longitude
    );
  }

  var mapType = MapType.normal;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Map View', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green[700],
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Stack(
            children: <Widget>[
              _isLoading
                  ? const Center(child: CircularProgressIndicator(),)
                  : Expanded(
                child: GoogleMap(
                  myLocationEnabled: true,
                  compassEnabled: false,
                  tiltGesturesEnabled: false,
                  markers: _markers,
                  mapType: mapType,

                  onMapCreated: (GoogleMapController mapController) {
                    addressConvert();
                    setState(() {
                      _mapController = mapController;
                    });
                    Fluttertoast.showToast(msg: "Tap on the pin and access directions to the property.", gravity: ToastGravity.CENTER);
                  },
                  initialCameraPosition: _cameraPosition,
                ),
              ),
              Positioned(
                top: 10, left: 0, right: 0,
                child: MapUserBadge(locationGivenGet: locationGiven, accountNumberGet: accountNumber),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.small(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            child: const Icon(Icons.map),
            onPressed: () {
              setState(() {
                if (mapType == MapType.normal) {
                  mapType = MapType.satellite;
                } else if (mapType == MapType.satellite) {
                  mapType = MapType.terrain;
                } else if (mapType == MapType.terrain) {
                  mapType = MapType.hybrid;
                } else if (mapType == MapType.hybrid) {
                  mapType = MapType.normal;
                }
              });
            },
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }

  void showPinOnMap() {
    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('sourcePin'),
        position: currentLocation,
        icon: sourceIcon,
      ));
    });
  }
}

