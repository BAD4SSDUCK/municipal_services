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
  String meterNum;
  String meterReading;
  String waterMeterNum;
  String waterMeterReading;
  String uid;

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
    required this.meterNum,
    required this.meterReading,
    required this.waterMeterNum,
    required this.waterMeterReading,
    required this.uid,
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
      documentId: json["Document ID"],
      accountNo: json["account number"],
      address: json["address"],
      areaCode: json["area code"],
      cellNum: json["cell number"],
      eBill: json["eBill"],
      firstName: json["first name"],
      lastName: json["last name"],
      id: json["id number"],
      imgStateE: json["imgStateE"],
      imgStateW: json["imgStateW"],
      meterNum: json["meter number"],
      meterReading: json["meter reading"],
      waterMeterNum: json["water meter number"],
      waterMeterReading: json["water meter reading"],
      uid: json["user id"],
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


}
