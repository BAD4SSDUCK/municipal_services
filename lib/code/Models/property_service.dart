import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:municipal_services/code/Models/property.dart';

class PropertyService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Fetch a specific property by account number
  Future<Map<String, dynamic>?> fetchPropertyByAccountNo(
      String accountNo, bool isLocalMunicipality) async {
    try {
      if (!isLocalMunicipality) {
        final districtSnapshot =
        await FirebaseFirestore.instance.collection('districts').get();

        for (var districtDoc in districtSnapshot.docs) {
          final municipalitySnapshot =
          await districtDoc.reference.collection('municipalities').get();

          for (var municipalityDoc in municipalitySnapshot.docs) {
            final data = municipalityDoc.data();
            final utilityTypes = List<String>.from(data['utilityType'] ?? []);
            final propertyCollection =
            municipalityDoc.reference.collection('properties');

            // Determine which field to search based on utility type
            if (utilityTypes.contains('electricity') &&
                !utilityTypes.contains('water')) {
              // Electricity only
              var query = await propertyCollection
                  .where('electricityAccountNumber', isEqualTo: accountNo)
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                print('Matched electricity account number.');
                return {
                  'property': Property.fromSnapshot(query.docs.first),
                  'matchedField': 'electricityAccountNumber',
                };
              }
            } else {
              // Water only or both
              var query = await propertyCollection
                  .where('accountNumber', isEqualTo: accountNo)
                  .limit(1)
                  .get();

              if (query.docs.isNotEmpty) {
                print('Matched water account number.');
                return {
                  'property': Property.fromSnapshot(query.docs.first),
                  'matchedField': 'accountNumber',
                };
              }
            }
          }
        }
      } else {
        final localSnapshot =
        await FirebaseFirestore.instance.collection('localMunicipalities').get();

        for (var localMunicipalityDoc in localSnapshot.docs) {
          final data = localMunicipalityDoc.data();
          final utilityTypes = List<String>.from(data['utilityType'] ?? []);
          final propertyCollection =
          localMunicipalityDoc.reference.collection('properties');

          if (utilityTypes.contains('electricity') &&
              !utilityTypes.contains('water')) {
            var query = await propertyCollection
                .where('electricityAccountNumber', isEqualTo: accountNo)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              print('Matched electricity account number.');
              return {
                'property': Property.fromSnapshot(query.docs.first),
                'matchedField': 'electricityAccountNumber',
              };
            }
          } else {
            var query = await propertyCollection
                .where('accountNumber', isEqualTo: accountNo)
                .limit(1)
                .get();

            if (query.docs.isNotEmpty) {
              print('Matched water account number.');
              return {
                'property': Property.fromSnapshot(query.docs.first),
                'matchedField': 'accountNumber',
              };
            }
          }
        }
      }

      print('❌ No property found via accountNo: $accountNo');
      return null;
    } catch (e) {
      print('Error in fetchPropertyByAccountNo: $e');
      return null;
    }
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

  Future<Property?> fetchPropertyByDynamicField({
    required String accountField,
    required String accountNumber,
    required bool isLocalMunicipality,
  }) async {
    try {
      QuerySnapshot snapshot = await firestore
          .collectionGroup('properties')
          .where(accountField, isEqualTo: accountNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        Property property = Property.fromSnapshot(snapshot.docs.first);
        print("✅ Property found via $accountField: ${property.address}");
        return property;
      } else {
        print("⚠️ No property found via $accountField: $accountNumber");
      }
    } catch (e) {
      print("Error fetching property by $accountField: $e");
    }
    return null;
  }
}
