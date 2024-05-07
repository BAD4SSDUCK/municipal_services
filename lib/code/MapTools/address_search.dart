import 'package:flutter/material.dart';
import 'package:municipal_services/code/MapTools/place_service.dart';

class AddressSearch extends SearchDelegate<Suggestion> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        tooltip: 'Clear',
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        if (query.isEmpty) {
          close(context, Suggestion('','')); // or close the search without passing a value
        } else {
          // Close with a default suggestion or a specific behavior
          close(context, Suggestion('ID','Default Suggestion'));
        }
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: PlaceApiProvider.getSuggestions(query), // Replace null with your actual method
      builder: (context, snapshot) {
        if (query.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            child: const Text('Enter Address...'),
          );
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemBuilder: (context, index) => ListTile(
              title: Text(snapshot.data![index].description),
              onTap: () {
                close(context, snapshot.data![index]);
              },
            ),
            itemCount: snapshot.data?.length,
          );
        } else {
          return Container(child: const Text('Loading...'));
        }
      },
    );
  }
}
