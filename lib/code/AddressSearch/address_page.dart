// import 'package:flutter/material.dart';
// import 'package:municipal_track/code/AddressSearch/address_search.dart';
// import 'package:municipal_track/code/AddressSearch/place_service.dart';
// import 'package:uuid/uuid.dart';
//
// class AddPage extends StatelessWidget {
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Google Places Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.amber,
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//       ),
//
//     );
//   }
// }
//
// class AddressPage extends StatefulWidget {
//   AddressPage({required Key key, required this.title}) : super(key: key);
//
//   final String title;
//
//   @override
//   _AddressPageState createState() => _AddressPageState();
// }
//
// class _AddressPageState extends State<AddressPage> {
//   final _controller = TextEditingController();
//   String _streetNumber = '';
//   String _street = '';
//   String _city = '';
//   String _zipCode = '';
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Container(
//         margin: EdgeInsets.only(left: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             TextField(
//               controller: _controller,
//               readOnly: true,
//               onTap: () async {
//                 // generate a new token here
//                 final sessionToken = Uuid().v4();
//                 final Suggestion? result = await showSearch(
//                   context: context,
//                   delegate: AddressSearch(sessionToken),
//                 );
//                 // This will change the text displayed in the TextField
//                 if (result != null) {
//                   final placeDetails = await PlaceApiProvider(sessionToken)
//                       .getPlaceDetailFromId(result.placeId);
//                   setState(() {
//                     _controller.text = result.description;
//                     _streetNumber = placeDetails.streetNumber;
//                     _street = placeDetails.street;
//                     _city = placeDetails.city;
//                     _zipCode = placeDetails.zipCode;
//                   });
//                 }
//               },
//               decoration: InputDecoration(
//                 icon: Container(
//                   width: 10,
//                   height: 10,
//                   child: Icon(
//                     Icons.home,
//                     color: Colors.black,
//                   ),
//                 ),
//                 hintText: "Enter your shipping address",
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.only(left: 8.0, top: 16.0),
//               ),
//             ),
//             SizedBox(height: 20.0),
//             Text('Street Number: $_streetNumber'),
//             Text('Street: $_street'),
//             Text('City: $_city'),
//             Text('ZIP Code: $_zipCode'),
//           ],
//         ),
//       ),
//     );
//   }
// }