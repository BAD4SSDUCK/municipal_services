import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:municipal_services/code/Models/property.dart';
import 'package:shared_preferences/shared_preferences.dart';

  // Import your Property model

class PropertyProvider with ChangeNotifier {
  Property? _selectedProperty;
  String? _districtId;
  String? _municipalityId;
  Property? _managedProperty;

  Property? get selectedProperty => _selectedProperty;
  Property? get managedProperty => _managedProperty;
  String? get districtId => _districtId;
  String? get municipalityId => _municipalityId;

  PropertyProvider() {
    loadSelectedPropertyAccountNo();
  }

  void selectProperty(Property property) {
    _selectedProperty = property;

    // If the property belongs to a local municipality, skip the districtId
    if (property.isLocalMunicipality) {
      _districtId = null;
      _municipalityId = property.municipalityId;
    } else {
      _districtId = property.districtId;
      _municipalityId = property.municipalityId;
    }

    notifyListeners();
    saveSelectedPropertyAccountNo(property.accountNo,property.isLocalMunicipality); // Save the selected property
  }

  void manageProperty(Property property) {
    _managedProperty = property;

    // Handle local vs district municipality logic here as well
    if (property.isLocalMunicipality) {
      _districtId = null;
      _municipalityId = property.municipalityId;
    } else {
      _districtId = property.districtId;
      _municipalityId = property.municipalityId;
    }

    notifyListeners();
  }

  Future<void> saveSelectedPropertyAccountNo(String accountNo, bool isLocalMunicipality) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedPropertyAccountNo', accountNo);
    await prefs.setBool('isLocalMunicipality', isLocalMunicipality); // Save municipality type
    print("Selected property account number and municipality type saved: $accountNo, $isLocalMunicipality");
  }


  Future<void> loadSelectedPropertyAccountNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accountNo = prefs.getString('selectedPropertyAccountNo');
    bool? isLocalMunicipality = prefs.getBool('isLocalMunicipality');

    print("Loaded selected property account number from prefs: $accountNo");
    print("Loaded municipality type from prefs: $isLocalMunicipality");

    if (accountNo != null && isLocalMunicipality != null) {
      await fetchPropertyByAccountNo(accountNo, isLocalMunicipality);
    } else {
      // Handle case when no property is found
      _selectedProperty = null;
      notifyListeners(); // Notify that the property is not available
    }
  }



  Future<void> fetchPropertyByAccountNo(String accountNo, bool isLocalMunicipality) async {
    QuerySnapshot snapshot;

    if (isLocalMunicipality) {
      snapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: accountNo)
          .where('isLocalMunicipality', isEqualTo: true)
          .limit(1)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('accountNumber', isEqualTo: accountNo)
          .where('isLocalMunicipality', isEqualTo: false)
          .limit(1)
          .get();
    }

    print("Firestore query result: ${snapshot.docs.length} documents found.");

    if (snapshot.docs.isNotEmpty) {
      _selectedProperty = Property.fromSnapshot(snapshot.docs.first);

      if (_selectedProperty!.isLocalMunicipality) {
        _districtId = null;
        _municipalityId = _selectedProperty?.municipalityId;
      } else {
        _districtId = _selectedProperty?.districtId;
        _municipalityId = _selectedProperty?.municipalityId;
      }

      notifyListeners();
    } else {
      print("No property found with the provided account number.");
    }
  }



}
