import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Property {
  String documentId;
  String accountNo;
  String address;
  int areaCode;
  String cellNum;
  String eBill;
  String firstName;
  String lastName;
  String id;
  bool imgStateE;
  bool imgStateW;
  String meterNum;
  String meterReading;
  String waterMeterNum;
  String waterMeterReading;
  String uid;


  Property(
      this.documentId,
      this.accountNo,
      this.address,
      this.areaCode,
      this.cellNum,
      this.eBill,
      this.firstName,
      this.lastName,
      this.id,
      this.imgStateE,
      this.imgStateW,
      this.meterNum,
      this.meterReading,
      this.waterMeterNum,
      this.waterMeterReading,
      this.uid,
      );

  // formatting for upload to Firebase when creating the property
  Map<String, dynamic> toJson() => {
    'Document ID': documentId,
    'account number': accountNo,
    'address': address,
    'area code': areaCode,
    'cell number': cellNum,
    'eBill': eBill,
    'first name': firstName,
    'last name': lastName,
    'id number': id,
    'imgStateE': imgStateE,
    'imgStateW': imgStateW,
    'meter number': meterNum,
    'meter reading': meterReading,
    'water meter number': waterMeterNum,
    'water meter reading': waterMeterReading,
    'user id': uid,
  };

  // creating a property object from a firebase snapshot
  Property.fromSnapshot(DocumentSnapshot snapshot) :
        documentId = snapshot.id,
        accountNo = snapshot['account number'],
        address = snapshot['address'],
        areaCode = snapshot['area code'],
        cellNum = snapshot['cell number'],
        eBill = snapshot['eBill'],
        firstName = snapshot['first name'],
        lastName = snapshot['last name'],
        id = snapshot['id number'],
        imgStateE = snapshot['imgStateE'],
        imgStateW = snapshot['imgStateW'],
        meterNum = snapshot['meter number'],
        meterReading = snapshot['meter reading'],
        waterMeterNum = snapshot['water meter number'],
        waterMeterReading = snapshot['water meter reading'],
        uid = snapshot['user id'];


  Map<String, Icon> types() => {
    "car": Icon(Icons.directions_car, size: 50),
    "bus": Icon(Icons.directions_bus, size: 50),
    "train": Icon(Icons.train, size: 50),
    "plane": Icon(Icons.airplanemode_active, size: 50),
    "ship": Icon(Icons.directions_boat, size: 50),
    "other": Icon(Icons.directions, size: 50),
  };

  /// return the google places image
  // Image getLocationImage() {
  //   final baseUrl = "https://maps.googleapis.com/maps/api/place/photo";
  //   final maxWidth = "1000";
  //   final url = "$baseUrl?maxwidth=$maxWidth&photoreference=$photoReference&key=$PLACES_API_KEY";
  //   return Image.network(url, fit: BoxFit.cover);
  // }


}
