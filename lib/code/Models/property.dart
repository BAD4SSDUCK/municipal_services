import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

Property studentFromJson(String str) => Property.fromJson(json.decode(str));

String studentToJson(Property data) => json.encode(data.toJson());

class Property {
  String? documentId;
  String accountNo;
  String address;
  int areaCode;
  String cellNum;
  String eBill;
  String firstName;
  String lastName;
  String id;
  // bool imgStateE;
  bool imgStateW;
  // String meterNum;
  // String meterReading;
  String waterMeterNum;
  String waterMeterReading;
  String uid;
  String districtId; // New field
  String municipalityId; // New field
  bool isLocalMunicipality;

  Property({
    this.documentId,
    required this.accountNo,
    required this.address,
    required this.areaCode,
    required this.cellNum,
    required this.eBill,
    required this.firstName,
    required this.lastName,
    required this.id,
    // required this.imgStateE,
    required this.imgStateW,
    // required this.meterNum,
    // required this.meterReading,
    required this.waterMeterNum,
    required this.waterMeterReading,
    required this.uid,
    required this.districtId, // Initialize new field
    required this.municipalityId, // Initialize new field
    required this.isLocalMunicipality,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
      documentId: json["Document ID"],
      accountNo: json["accountNumber"],
      address: json["address"],
      areaCode: json["areaCode"],
      cellNum: json["cellNumber"],
      eBill: json["eBill"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      id: json["idNumber"],
      // imgStateE: json["imgStateE"],
      imgStateW: json["imgStateW"],
      // meterNum: json["meter_number"],
      // meterReading: json["meter_reading"],
      waterMeterNum: json["water_meter_number"],
      waterMeterReading: json["water_meter_reading"],
      uid: json["userID"],
      districtId: json["districtId"], // Parse new field
      municipalityId: json["municipalityId"],
    isLocalMunicipality: json['isLocalMunicipality'],
  );

  // formatting for upload to Firebase when creating the property
  Map<String, dynamic> toJson() => {
    'Document ID': documentId,
    'accountNumber': accountNo,
    'address': address,
    'areaCode': areaCode,
    'cellNumber': cellNum,
    'eBill': eBill,
    'firstName': firstName,
    'lastName': lastName,
    'idNumber': id,
    // 'imgStateE': imgStateE,
    'imgStateW': imgStateW,
    // 'meter_number': meterNum,
    // 'meter_reading': meterReading,
    'water_meter_number': waterMeterNum,
    'water_meter_reading': waterMeterReading,
    'userID': uid,
    'districtId': districtId, // Add to JSON
    'municipalityId': municipalityId, // Add to JSON
    'isLocalMunicipality': isLocalMunicipality,
  };

  // creating a property object from a firebase snapshot
  Property.fromSnapshot(DocumentSnapshot snapshot) :
        documentId = snapshot.id,
        accountNo = snapshot['accountNumber'],
        address = snapshot['address'],
        areaCode = snapshot['areaCode'],
        cellNum = snapshot['cellNumber'],
        eBill = snapshot['eBill'],
        firstName = snapshot['firstName'],
        lastName = snapshot['lastName'],
        id = snapshot['idNumber'],
        // imgStateE = snapshot['imgStateE'],
        imgStateW = snapshot['imgStateW'],
        // meterNum = snapshot['meter_number'],
        // meterReading = snapshot['meter_reading'],
        waterMeterNum = snapshot['water_meter_number'],
        waterMeterReading = snapshot['water_meter_reading'],
        uid = snapshot['userID'],
        districtId = snapshot['districtId'],// Retrieve from snapshot
        municipalityId = snapshot['municipalityId'],
        isLocalMunicipality = snapshot['isLocalMunicipality'];

  Map<String, Icon> types() => {
    "car": Icon(Icons.directions_car, size: 50),
    "bus": Icon(Icons.directions_bus, size: 50),
    "train": Icon(Icons.train, size: 50),
    "plane": Icon(Icons.airplanemode_active, size: 50),
    "ship": Icon(Icons.directions_boat, size: 50),
    "other": Icon(Icons.directions, size: 50),
  };


}
