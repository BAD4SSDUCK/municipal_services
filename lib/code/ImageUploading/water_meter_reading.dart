import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/src/context.dart';


class WaterMeterReadingService {
  // This method doesn't need BuildContext since it's only updating Firestore
  static Future<void> updateWaterMeterData({
    required DocumentSnapshot documentSnapshot,
    required CollectionReference propList,
    String? municipalityUserEmail,
    String districtId = '',
    String municipalityId = '',
    bool isLocalMunicipality = false,
  }) async {
    try {
     // String meterReading = documentSnapshot['meter_reading'];
      String waterMeterReading = documentSnapshot['water_meter_reading'];
      String address = documentSnapshot['address'];
      // Prepare the data to be updated
      final Map<String, dynamic> updateDetails = {
        "accountNumber": documentSnapshot['accountNumber'],
        "address": documentSnapshot['address'],
        "areaCode": documentSnapshot['areaCode'],
        "water_meter_number": documentSnapshot['water_meter_number'],
        "water_meter_reading": documentSnapshot['water_meter_reading'],
        "cellNumber": documentSnapshot['cellNumber'],
        "firstName": documentSnapshot['firstName'],
        "lastName": documentSnapshot['lastName'],
        "idNumber": documentSnapshot['idNumber'],
      };
      print("Updating document with details: $updateDetails");
      // Update Firestore with the new meter reading
      await documentSnapshot.reference.update(updateDetails);

      await addMeterReadingToConsumption(
        districtId: districtId,
        municipalityId: municipalityId,
        address: address,
      //  meterReading: meterReading,
        waterMeterReading: waterMeterReading,
        isLocalMunicipality: isLocalMunicipality,
      );
      // Log the update action if `municipalityUserEmail` is provided

        await _logWMeterReadingUpdate(
          documentSnapshot['cellNumber'],
          documentSnapshot['address'],
          municipalityUserEmail,
          districtId,
          municipalityId,
          updateDetails,
          isLocalMunicipality,
        );


      print("Water meter reading updated successfully.");
    } catch (e) {
      print('Error updating water meter data: $e');
      throw e;
    }
  }

  static Future<void> addMeterReadingToConsumption({
    required String districtId,
    required String municipalityId,
    required String address,
    required String waterMeterReading,
    required bool isLocalMunicipality,
  }) async {
    try {
      // Get the current month to format the path
      String formattedMonth = DateFormat('MMMM').format(DateTime.now());

      // Ensure waterMeterReading is not null or empty
      if (waterMeterReading.isEmpty) {
        throw Exception("Water meter reading is missing.");
      }

      // Dynamically set the collection path based on whether it's a local municipality or district
      if (isLocalMunicipality) {
        // Set the timestamp at the month document level
        await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('consumption')
            .doc(formattedMonth)
            .set({
          "timestamp": FieldValue.serverTimestamp() // Add timestamp to the document representing the month
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data

        // Set the data at the property level
        await FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId)
            .collection('consumption')
            .doc(formattedMonth)
            .collection('address')
            .doc(address)
            .set({
          "address": address,
          "water_meter_reading": waterMeterReading,
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
      } else {
        // Set the timestamp at the month document level for district-based municipalities
        await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('consumption')
            .doc(formattedMonth)
            .set({
          "timestamp": FieldValue.serverTimestamp() // Add timestamp to the document representing the month
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data

        // Set the data at the property level
        await FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('consumption')
            .doc(formattedMonth)
            .collection('address')
            .doc(address)
            .set({
          "address": address,
          "water_meter_reading": waterMeterReading,
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing data
      }

      print("Meter reading added to consumption for $address in $formattedMonth");
    } catch (e) {
      print("Error adding meter reading to consumption: $e");
    }
  }



  static Future<void> _logWMeterReadingUpdate(
      String cellNumber,
      String propertyAddress,
      String? municipalityUserEmail,
      String districtId,
      String municipalityId,
      Map<String, dynamic> details,
      bool isLocalMunicipality,
      ) async {
    print("Logging Water Meter Reading Update");
    print("Municipality User Email: $municipalityUserEmail");
    DocumentReference actionLogRef;

    // Choose the correct Firestore path based on the municipality type
    if (isLocalMunicipality) {
      actionLogRef = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc();
    } else {
      actionLogRef = FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .collection('actionLogs')
          .doc(cellNumber)
          .collection(propertyAddress)
          .doc();
    }

    // Determine the uploader: municipality email or phone number (regular user)
    String uploader = municipalityUserEmail?.isNotEmpty ?? false
        ? municipalityUserEmail!
        : cellNumber;

    try {
      // Log the water meter reading update
      await actionLogRef.set({
        'actionType': 'Water Meter Reading Update',
        'uploader': uploader, // Use municipality email if available, otherwise phone number
        'details': details,
        'address': propertyAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'description': '$uploader updated water meter readings for property at $propertyAddress',
      });

      print("Water meter reading update logged successfully.");
    } catch (e) {
      print('Error logging water meter reading update: $e');
      throw e;
    }
  }


}
