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
  bool imgStateE;
  bool imgStateW;
  String electricityMeterNum;
  String meterReading;
  String waterMeterNum;
  String waterMeterReading;
  String uid;
  String districtId; // New field
  String municipalityId; // New field
  bool isLocalMunicipality;
  String electricityAccountNo;

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
    required this.imgStateE,
    required this.imgStateW,
    required this.electricityMeterNum,
    required this.meterReading,
    required this.waterMeterNum,
    required this.waterMeterReading,
    required this.uid,
    required this.districtId, // Initialize new field
    required this.municipalityId, // Initialize new field
    required this.isLocalMunicipality,
    required this. electricityAccountNo,

  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
      documentId: json["Document ID"],
      accountNo: json["accountNumber"],
      electricityAccountNo: json["electricityAccountNumber"] ?? '',
      address: json["address"],
      areaCode: json["areaCode"],
      cellNum: json["cellNumber"],
      eBill: json["eBill"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      id: json["idNumber"],
      imgStateE: json["imgStateE"],
      imgStateW: json["imgStateW"],
      electricityMeterNum: json["meter_number"],
      meterReading: json["meter_reading"],
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
    'electricityAccountNumber': electricityAccountNo,
    'address': address,
    'areaCode': areaCode,
    'cellNumber': cellNum,
    'eBill': eBill,
    'firstName': firstName,
    'lastName': lastName,
    'idNumber': id,
     'imgStateE': imgStateE,
    'imgStateW': imgStateW,
    'meter_number': electricityMeterNum,
    'meter_reading': meterReading,
    'water_meter_number': waterMeterNum,
    'water_meter_reading': waterMeterReading,
    'userID': uid,
    'districtId': districtId, // Add to JSON
    'municipalityId': municipalityId, // Add to JSON
    'isLocalMunicipality': isLocalMunicipality,
  };

  // creating a property object from a firebase snapshot
  factory Property.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    return Property(
      documentId: snapshot.id,
      accountNo: data['accountNumber'] ?? '',
      electricityAccountNo: data.containsKey('electricityAccountNumber') ? data['electricityAccountNumber'] ?? '' : '',
      address: data['address'] ?? '',
      areaCode: data['areaCode'] ?? '',
      cellNum: data['cellNumber'] ?? '',
      eBill: data['eBill'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      id: data['idNumber'] ?? '',
      imgStateE: data['imgStateE'] ?? '',
      imgStateW: data['imgStateW'] ?? '',
      electricityMeterNum: data['meter_number'] ?? '',
      meterReading: data['meter_reading'] ?? '',
      waterMeterNum: data['water_meter_number'] ?? '',
      waterMeterReading: data['water_meter_reading'] ?? '',
      uid: data['userID'] ?? '',
      districtId: data.containsKey('districtId') ? data['districtId'] ?? '' : '',
      municipalityId: data['municipalityId'] ?? '',
      isLocalMunicipality: data['isLocalMunicipality'] ?? false,
    );
  }


  Map<String, Icon> types() => {
    "car": Icon(Icons.directions_car, size: 50),
    "bus": Icon(Icons.directions_bus, size: 50),
    "train": Icon(Icons.train, size: 50),
    "plane": Icon(Icons.airplanemode_active, size: 50),
    "ship": Icon(Icons.directions_boat, size: 50),
    "other": Icon(Icons.directions, size: 50),
  };


}
