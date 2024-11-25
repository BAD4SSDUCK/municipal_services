import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:municipal_services/code/Models/property.dart';

class PropertyService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fetch a specific property by account number
  Future<Property?> fetchPropertyByAccountNo(String accountNo, bool isLocalMunicipality) async {
    try {
      QuerySnapshot snapshot = await firestore
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: accountNo)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Property property = Property.fromSnapshot(snapshot.docs.first);

        // Handle property differently if it is a local municipality
        if (property.isLocalMunicipality) {
          print("Property belongs to a local municipality.");
        } else {
          print("Property belongs to a district municipality.");
        }

        return property;
      }
    } catch (e) {
      print("Error fetching property by account number: $e");
    }
    return null;
  }

  // Fetch all properties for a user across all municipalities (local and district)
  Future<List<Property>> fetchPropertiesForUser(String cellNumber) async {
    try {
      // Search all properties collections based on cellNumber
      QuerySnapshot querySnapshot = await firestore
          .collectionGroup('properties')
          .where('cellNumber', isEqualTo: cellNumber)
          .get();

      List<Property> properties = querySnapshot.docs.map((doc) => Property.fromSnapshot(doc)).toList();

      // Check if properties belong to local or district municipalities
      for (var property in properties) {
        if (property.isLocalMunicipality) {
          print("Found local municipality property: ${property.address}");
        } else {
          print("Found district municipality property: ${property.address}");
        }
      }

      return properties;
    } catch (e) {
      print("Error fetching properties for user: $e");
      return [];
    }
  }

  // Count properties for a user across all municipalities
  Future<int> countPropertiesForUser(String cellNumber) async {
    try {
      // Count properties based on cellNumber
      QuerySnapshot querySnapshot = await firestore
          .collectionGroup('properties')
          .where('cellNumber', isEqualTo: cellNumber)
          .get();

      return querySnapshot.size;
    } catch (e) {
      print("Error counting properties for user: $e");
      return 0;
    }
  }
}
