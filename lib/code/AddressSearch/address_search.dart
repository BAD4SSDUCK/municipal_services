// import 'package:flutter/material.dart';
// import 'package:municipal_track/code/AddressSearch/place_service.dart';
//
// class AddressSearch extends SearchDelegate<Suggestion> {
//   AddressSearch(this.sessionToken) {
//     apiClient = PlaceApiProvider(sessionToken);
//   }
//
//   final sessionToken;
//   PlaceApiProvider apiClient;
//
//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       IconButton(
//         tooltip: 'Clear',
//         icon: Icon(Icons.clear),
//         onPressed: () {
//           query = '';
//         },
//       )
//     ];
//   }
//
//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       tooltip: 'Back',
//       icon: Icon(Icons.arrow_back),
//       onPressed: () {
//         Navigator.pop(context, true);
//       },
//     );
//   }
//
//   @override
//   Widget buildResults(BuildContext context) {
//     return null;
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) {
//     return FutureBuilder(
//       future: query == ""
//           ? null
//           : apiClient.fetchSuggestions(
//           query, Localizations.localeOf(context).languageCode),
//       builder: (context, snapshot) => query == ''
//           ? Container(
//         padding: EdgeInsets.all(16.0),
//         child: Text('Enter your address'),
//       )
//           : snapshot.hasData
//           ? ListView.builder(
//         itemBuilder: (context, index) => ListTile(
//           title:
//           Text((snapshot.data![index] as Suggestion).description),
//           onTap: () {
//             close(context, snapshot.data![index] as Suggestion);
//           },
//         ),
//         itemCount: snapshot.data?.length,
//       )
//           : Container(child: Text('Loading...')),
//     );
//   }
// }
//
// class AddressInput extends StatelessWidget {
//   final IconData iconData;
//   final TextEditingController controller;
//   final String hintText;
//   final Function onTap;
//   final bool enabled;
//
//   const AddressInput({
//     super.key,
//     this.iconData,
//     this.controller,
//     this.hintText,
//     this.onTap,
//     this.enabled}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }
