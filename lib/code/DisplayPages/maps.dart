import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:municipal_track/code/MapTools/location_controller.dart';
import 'package:municipal_track/code/MapTools/location_search_dialogue.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

class MapView extends StatefulWidget {
  const MapView({Key? key}) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late CameraPosition _cameraPosition;
  @override
  void initState(){
    super.initState();
    _cameraPosition= CameraPosition(target: LatLng(
        -29.601505328570788, 30.379442518631805
    ), zoom: 17);
  }

  late GoogleMapController _mapController;
  @override
  Widget build(BuildContext context) {

    return GetBuilder<LocationController>(builder: (locationController){
      return Scaffold(
          appBar: AppBar(
            title: const Text('Maps Location View'),
            backgroundColor: Colors.green[700],
          ),
          body: Stack(
            children: <Widget>[

              GoogleMap(
                  onMapCreated: (GoogleMapController mapController) {
                    _mapController = mapController;
                    //locationController.setMapController(mapController);
                  },
                  initialCameraPosition: _cameraPosition
              ),
              Positioned(
                top: 100,
                left: 10, right: 20,
                child: GestureDetector(
                  onTap:() => Get.dialog(LocationSearchDialog(mapController: _mapController)),

                  child: Container(
                    height: 50,
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      Icon(Icons.location_on, size: 25, color: Theme.of(context).primaryColor),
                      SizedBox(width: 5),
                      //here we show the address on the top
                      Expanded(
                        child: Text(
                          '${locationController.pickPlaceMark.name ?? ''} ${locationController.pickPlaceMark.locality ?? ''} '
                              '${locationController.pickPlaceMark.postalCode ?? ''} ${locationController.pickPlaceMark.country ?? ''}',
                          style: TextStyle(fontSize: 20),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.search, size: 25, color: Theme.of(context).textTheme.bodyText1!.color),
                    ]),
                  ),
                ),
              ),
            ],
          )
      );
    },);
  }
}