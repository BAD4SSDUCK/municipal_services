// import 'package:cloud_firestore/cloud_firestore.dart';
//
// import 'package:flutter/material.dart';
//
// class PropertyTrend extends StatelessWidget {
//   PropertyTrend({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(child: Scaffold(body: SfCartesianChart(),));
//   }
//
//   List<PropertyReading> getChartData(){
//     final List<PropertyReading> chartData = [
//       PropertyReading(address, month, meterReading, waterReading)
//     ];
//   }
//
//   List _allPropertyResults = [];
//
//   getPropertyStream() async{
//     var data = await FirebaseFirestore.instance.collection('properties').get();
//
//     setState(() {
//       _allPropertyResults = data.docs;
//     });
//   }
//
// }
//
// class _propertyTrendState
//
//
// class PropertyReading {
//
//   PropertyReading(this.address, this.month, this.meterReading, this.waterReading );
//
//   final String address;
//   final String month;
//   final double meterReading;
//   final double waterReading;
//
// }
