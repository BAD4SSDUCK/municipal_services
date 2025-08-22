import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:municipal_services/code/Models/property.dart';
import 'package:municipal_services/code/Models/property_service.dart';
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

  Future<void> selectProperty(Property property, {required bool handlesWater, required bool handlesElectricity}) async {
    _selectedProperty = property;

    if (property.isLocalMunicipality) {
      _districtId = null;
      _municipalityId = property.municipalityId;
    } else {
      _districtId = property.districtId;
      _municipalityId = property.municipalityId;
    }

    notifyListeners();

    await saveSelectedPropertyAccountNo(
      property: property,
      handlesWater: handlesWater,
      handlesElectricity: handlesElectricity,
    );
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

  Future<void> saveSelectedPropertyAccountNo({
    required Property property,
    required bool handlesWater,
    required bool handlesElectricity,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Determine which account number to save
    final accountToSave = (handlesElectricity && !handlesWater)
        ? property.electricityAccountNo
        : property.accountNo;

    await prefs.setString('selectedPropertyAccountNo', accountToSave);
    await prefs.setBool('isLocalMunicipality', property.isLocalMunicipality);

    print("✅ Saved selected accountNo: $accountToSave under ${(handlesElectricity && !handlesWater) ? 'electricityAccountNumber' : 'accountNumber'}");
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
    final PropertyService propertyService = PropertyService();
    final result = await propertyService.fetchPropertyByAccountNo(accountNo, isLocalMunicipality);

    if (result != null) {
      _selectedProperty = result['property'] as Property;

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
