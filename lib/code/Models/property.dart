// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
//
// class Property {
//   String title;
//   DateTime startDate;
//   DateTime endDate;
//   double budget;
//   Map budgetTypes;
//   String travelType;
//   String photoReference;
//   String notes;
//   String documentId;
//   double saved;
//
//
//   Property(
//       this.documentId,
//       this.title,
//       this.startDate,
//       this.endDate,
//       this.budget,
//       this.budgetTypes,
//       this.travelType
//       );
//
//   // formatting for upload to Firbase when creating the trip
//   Map<String, dynamic> toJson() => {
//     'title': title,
//     'startDate': startDate,
//     'endDate': endDate,
//     'budget': budget,
//     'budgetTypes': budgetTypes,
//     'travelType': travelType,
//     'photoReference': photoReference,
//   };
//
//   // creating a Trip object from a firebase snapshot
//   Property.fromSnapshot(DocumentSnapshot snapshot) :
//         title = snapshot['title'],
//         startDate = snapshot['startDate'].toDate(),
//         endDate = snapshot['endDate'].toDate(),
//         budget = snapshot['budget'],
//         budgetTypes = snapshot['budgetTypes'],
//         travelType = snapshot['travelType'],
//         photoReference = snapshot['photoReference'],
//         notes = snapshot['notes'],
//         documentId = snapshot.id,
//         saved = snapshot['saved'];
//
//
//
//   Map<String, Icon> types() => {
//     "car": Icon(Icons.directions_car, size: 50),
//     "bus": Icon(Icons.directions_bus, size: 50),
//     "train": Icon(Icons.train, size: 50),
//     "plane": Icon(Icons.airplanemode_active, size: 50),
//     "ship": Icon(Icons.directions_boat, size: 50),
//     "other": Icon(Icons.directions, size: 50),
//   };
//
//   // return the google places image
//   Image getLocationImage() {
//     final baseUrl = "https://maps.googleapis.com/maps/api/place/photo";
//     final maxWidth = "1000";
//     final url = "$baseUrl?maxwidth=$maxWidth&photoreference=$photoReference&key=$PLACES_API_KEY";
//     return Image.network(url, fit: BoxFit.cover);
//   }
//
//   int getTotalTripDays() {
//     return endDate.difference(startDate).inDays;
//   }
//
//   int getDaysUntilTrip() {
//     int diff = startDate.difference(DateTime.now()).inDays;
//     if (diff < 0) {
//       diff = 0;
//     }
//     return diff;
//   }
// }
