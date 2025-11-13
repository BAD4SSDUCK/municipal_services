import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/MapTools/location_controller.dart';
import 'package:municipal_services/code/MapTools/map_user_badge.dart';
import 'package:http/http.dart' as http;

const LatLng SOURCE_LOCATION = LatLng(-29.601505328570788, 30.379442518631805);


class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.isLocalMunicipality, // Added this parameter
    required this.districtId,          // Added districtId
    required this.municipalityId,
    required this.propAddress,// Added municipalityId
    this.propAccNumber,
  });

  final bool isLocalMunicipality; // Local municipality flag
  final String districtId;        // District ID
  final String municipalityId;    // Municipality ID
  final String propAddress;
  final String? propAccNumber;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _fallback = LatLng(-29.601505328570788, 30.379442518631805);
  late final CameraPosition _cameraPosition = const CameraPosition(target: _fallback, zoom: 16);
  late LatLng addressLocation = _fallback;
   bool _isLoading=true;
  GoogleMapController? _mapController;
  BitmapDescriptor? _pinIcon;
  final Set<Marker> _markers = <Marker>{};
  String location = 'Null, Press Button';
  String address = 'search';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // spinner safety timeout
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isLoading = false);
    });

    await _loadPin();
    await _addressConvert(); // same logic as MapScreenProp
  }

  Future<void> _loadPin() async {
    _pinIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.0),
      'assets/images/location/source_pin_android.png',
    );
  }

  String get _targetAddress {
    final a = (widget.propAddress ?? '').trim();
    if (a.isNotEmpty) return a;
    // fall back to your old global if it still exists
    return (locationGiven).trim();
  }

  Future<void> _addressConvert() async {
    final address = _targetAddress;
    if (address.isEmpty) {
      _fallbackCamera("Empty address");
      return;
    }

    if (!kIsWeb) {
      // MOBILE: local geocoding
      try {
        final locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final loc = locations.first;
          addressLocation = LatLng(loc.latitude, loc.longitude);
          _showPin();
          await _animateTo(addressLocation);
          return;
        }
        _fallbackCamera("No locations from geocoder");
      } catch (e) {
        _fallbackCamera("Mobile geocoder error: $e");
      }
      return;
    }

    // WEB: use your Cloud Function with server key
    try {
      final encoded = Uri.encodeComponent(address);
      const base = 'https://europe-west1-municipal-tracker-msunduzi.cloudfunctions.net';
      final url = '$base/geocodeAddress?address=$encoded';

      final resp = await http.get(Uri.parse(url));
      final body = jsonDecode(resp.body);
      final status = (body['status'] ?? '').toString();
      final results = body['results'] as List<dynamic>?;

      if (resp.statusCode == 200 && status == 'OK' && results != null && results.isNotEmpty) {
        final loc = results[0]['geometry']['location'];
        addressLocation = LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
        _showPin();
        await _animateTo(addressLocation);
      } else {
        final err = (body['error_message'] ?? '').toString();
        _fallbackCamera("Geocode $status ${err.isNotEmpty ? '($err)' : ''}");
      }
    } catch (e) {
      _fallbackCamera("geocodeAddress exception: $e");
    }
  }

  Future<void> _animateTo(LatLng target) async {
    final c = _mapController;
    if (c != null) {
      await c.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
      );
    }
  }

  void _fallbackCamera(String reason) {
    debugPrint("ℹ️ Fallback camera: $reason");
    addressLocation = _fallback;
    _showPin();
    _animateTo(_fallback);
    Fluttertoast.showToast(
      msg: "Address not found! Default map location City Hall!",
      gravity: ToastGravity.CENTER,
    );
  }

  void _showPin() {
    if (!mounted) return;
    setState(() {
      _markers
        ..removeWhere((m) => m.markerId.value == 'sourcePin')
        ..add(Marker(
          markerId: const MarkerId('sourcePin'),
          position: addressLocation,
          icon: _pinIcon ?? BitmapDescriptor.defaultMarker,
        ));
    });
  }

  MapType _mapType = MapType.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        myLocationEnabled: true,
        compassEnabled: false,
        tiltGesturesEnabled: false,
        markers: _markers,
        mapType: _mapType,
        initialCameraPosition: _cameraPosition,
        onMapCreated: (controller) {
          _mapController = controller;
          // If geocoding finished before map was ready, ensure camera aligns:
          _animateTo(addressLocation);
        },
      ),
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.map),
        onPressed: () {
          setState(() {
            _mapType = _mapType == MapType.normal
                ? MapType.satellite
                : _mapType == MapType.satellite
                ? MapType.terrain
                : _mapType == MapType.terrain
                ? MapType.hybrid
                : MapType.normal;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

