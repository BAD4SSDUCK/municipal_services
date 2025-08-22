import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:municipal_services/code/Auth/auth_page.dart';
import 'package:municipal_services/code/AuthGoogle/auth_page_google.dart';
import 'package:municipal_services/code/DisplayPages/dashboard_official.dart';
import 'package:municipal_services/code/login/login_page.dart';
import 'package:municipal_services/code/DisplayPages/dashboard.dart';
import 'package:municipal_services/code/DisplayPages/dashboard_of_fragments.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'DisplayPages/prop_selection.dart';
import 'Models/property.dart';
import 'Models/property_service.dart';

///this page is for login check on users and will return the user to the main menu or a login page if they are logged in or not.

// class MainPage extends StatelessWidget {
//   const MainPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//
//     ///code for sign in using user created email and password
//     ///AuthPage determines the login type between email or phone number otp
//     return Scaffold(
//       body: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot){
//           if (snapshot.hasData){
//             final FirebaseAuth auth = FirebaseAuth.instance;
//             final User? user = auth.currentUser;
//             final uid = user?.uid;
//             String userID = uid as String;
//             if(user?.email?.isEmpty == false){
//               return const HomeManagerScreen();
//             } else {
//               return const MainMenu();
//             }
//           } else {
//             return const AuthPage();
//           }
//         },
//       ),
//     );
//
//     ///code for signing with users device google account with gmail
//     // return MaterialApp(
//     //   themeMode: ThemeMode.system,
//     //   debugShowCheckedModeBanner: false,
//     //   home: AuthService().handleAuthState(),
//     // );
//
//   }
// }
class MainPage extends StatelessWidget {
  MainPage({Key? key}) : super(key: key);

  final PropertyService _propertyService = PropertyService();

  Future<Property?> _loadSelectedProperty() async {
    final prefs = await SharedPreferences.getInstance();
    final accountNo = prefs.getString('selectedPropertyAccountNo');
    final isLocalMunicipality = prefs.getBool('isLocalMunicipality');

    if (accountNo != null && isLocalMunicipality != null) {
      final result = await _propertyService.fetchPropertyByAccountNo(accountNo, isLocalMunicipality);

      if (result != null) {
        final Property property = result['property'] as Property;
        final String matchedField = result['matchedField'] as String;

        // Save the matched field in SharedPreferences
        await prefs.setString('matchedAccountField', matchedField);

        print("✅ Loaded selected property account number: $accountNo");
        print("📌 Matched account field: $matchedField");
        print("🏘️ Loaded property address: ${property.address}");
        print("🌍 isLocalMunicipality: $isLocalMunicipality");

        return property;
      } else {
        print("❌ Main Page:No property matched the account number: $accountNo");
      }
    } else {
      print("Main Page⚠️ SharedPreferences values are missing. accountNo: $accountNo, isLocalMunicipality: $isLocalMunicipality");
    }

    return null;
  }

  Future<String?> getMatchedAccountField() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('matchedAccountField');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If no user is logged in, redirect to the authentication page
          if (!snapshot.hasData) return const AuthPage();

          final User? user = snapshot.data;
          final String? phoneNumber = user?.phoneNumber;
          bool isEmailUser = user?.email?.isNotEmpty ?? false;

          if (isEmailUser) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collectionGroup('users')
                  .where('email', isEqualTo: user!.email)
                  .limit(1)
                  .get()
                  .then((value) => value.docs.first),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text("Error loading user data: ${snapshot.error}");
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("No user data found.");
                }

                final bool isLocalMunicipality =
                    snapshot.data!.get('isLocalMunicipality') ?? false;

                // 🔑 Now fetch claims to get `superadmin`
                return FutureBuilder<IdTokenResult>(
                  future: FirebaseAuth.instance.currentUser!.getIdTokenResult(true),
                  builder: (context, tokenSnap) {
                    if (tokenSnap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (tokenSnap.hasError) {
                      return Text("Error loading claims: ${tokenSnap.error}");
                    }
                    final isSuperadmin =
                        tokenSnap.data?.claims?['superadmin'] == true;

                    return HomeManagerScreen(
                      isLocalMunicipality: isLocalMunicipality,
                      isSuperadmin: isSuperadmin,
                    );
                  },
                );
              },
            );
          }

          else if (phoneNumber != null) {
            return FutureBuilder<Property?>(
              future: _loadSelectedProperty(),
              builder: (context, propertySnapshot) {
                if (propertySnapshot.connectionState == ConnectionState.done) {
                  if (propertySnapshot.hasError) {
                    return Text("Error loading property: ${propertySnapshot.error}");
                  }

                  // If a property is already selected, navigate to MainMenu
                  if (propertySnapshot.data != null) {
                    final Property selectedProperty = propertySnapshot.data!;
                    return MainMenu(
                      property: selectedProperty,
                      propertyCount: 1,
                      isLocalMunicipality: selectedProperty.isLocalMunicipality,  // Pass isLocalMunicipality
                    );
                  }

                  // If no property is selected, fetch all properties
                  else {
                    return FutureBuilder<List<Property>>(
                      future: fetchProperties(phoneNumber),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Text("Error fetching properties: ${snapshot.error}");
                          }

                          List<Property>? properties = snapshot.data;
                          if (properties != null && properties.isNotEmpty) {
                            // Pass the isLocalMunicipality flag from the fetched properties
                            bool isLocalMunicipality = properties.any((property) => property.isLocalMunicipality);
                            Property firstProp = properties.first;
                            return FutureBuilder<Map<String, bool>>(
                              future: fetchMunicipalityUtilityTypes(
                                firstProp.municipalityId,
                                firstProp.districtId,
                                firstProp.isLocalMunicipality,
                              ),
                              builder: (context, utilitySnapshot) {
                                if (utilitySnapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (utilitySnapshot.hasError || !utilitySnapshot.hasData) {
                                  return const Text("Error fetching utility types.");
                                }

                                final handlesWater = utilitySnapshot.data!['handlesWater']!;
                                final handlesElectricity = utilitySnapshot.data!['handlesElectricity']!;

                                return PropertySelectionScreen(
                                  properties: properties,
                                  userPhoneNumber: phoneNumber,
                                  isLocalMunicipality: isLocalMunicipality,
                                  handlesWater: handlesWater,
                                  handlesElectricity: handlesElectricity,
                                );
                              },
                            );

                          }

                          return const Text("No properties found for this number.");
                        }

                        return const CircularProgressIndicator();
                      },
                    );
                  }
                }

                return const CircularProgressIndicator();
              },
            );
          } else {
            return const Text("No phone number available for this account.");
          }
        },
      ),
    );
  }
}

Future<List<Property>> fetchProperties(String phoneNumber) async {
  List<Property> properties = [];

  // Fetch from district-based municipalities
  final districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();
  for (var districtDoc in districtsSnapshot.docs) {
    final municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();
    for (var municipalityDoc in municipalitiesSnapshot.docs) {
      final propertiesSnapshot = await municipalityDoc.reference
          .collection('properties')
          .where('cellNumber', isEqualTo: phoneNumber)
          .get();
      for (var propertyDoc in propertiesSnapshot.docs) {
        properties.add(Property.fromSnapshot(propertyDoc));
      }
    }
  }

  // Fetch from local municipalities
  final localMunicipalitiesSnapshot = await FirebaseFirestore.instance.collection('localMunicipalities').get();
  for (var localMunicipalityDoc in localMunicipalitiesSnapshot.docs) {
    final propertiesSnapshot = await localMunicipalityDoc.reference
        .collection('properties')
        .where('cellNumber', isEqualTo: phoneNumber)
        .get();
    for (var propertyDoc in propertiesSnapshot.docs) {
      properties.add(Property.fromSnapshot(propertyDoc));
    }
  }

  return properties;
}

Future<Map<String, bool>> fetchMunicipalityUtilityTypes(
    String municipalityId, String? districtId, bool isLocalMunicipality) async {
  bool handlesWater = false;
  bool handlesElectricity = false;

  try {
    if (isLocalMunicipality) {
      final snapshot = await FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(municipalityId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final utilityTypes = List<String>.from(data['utilityType'] ?? []);
        handlesWater = utilityTypes.contains('water');
        handlesElectricity = utilityTypes.contains('electricity');
      }
    } else if (districtId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(districtId)
          .collection('municipalities')
          .doc(municipalityId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final utilityTypes = List<String>.from(data['utilityType'] ?? []);
        handlesWater = utilityTypes.contains('water');
        handlesElectricity = utilityTypes.contains('electricity');
      }
    }
  } catch (e) {
    print('Error fetching utility types: $e');
  }

  return {
    'handlesWater': handlesWater,
    'handlesElectricity': handlesElectricity,
  };
}


// Fetch the total count of properties linked to the user's phone number
Future<int> fetchPropertyCount(String phoneNumber) async {
  QuerySnapshot propertiesSnapshot = await FirebaseFirestore.instance
      .collectionGroup('properties')
      .where('cellNumber', isEqualTo: phoneNumber)
      .get();
  return propertiesSnapshot.docs.length;
}

class _EmailLoginInfo {
  final bool isLocalMunicipality;
  final bool isSuperadmin;
  _EmailLoginInfo({
    required this.isLocalMunicipality,
    required this.isSuperadmin,
  });
}

Future<_EmailLoginInfo> _fetchEmailLoginInfo(User user) async {
  // Refresh so the latest custom claims are available
  final token = await user.getIdTokenResult(true);
  final claims = token.claims ?? {};
  final isSuperadmin = claims['superadmin'] == true;

  // Discover whether this email user belongs to a local municipality
  final q = await FirebaseFirestore.instance
      .collectionGroup('users')
      .where('email', isEqualTo: user.email)
      .limit(1)
      .get();

  final bool isLocalMunicipality = q.docs.isNotEmpty
      ? (q.docs.first.data()['isLocalMunicipality'] ?? false)
      : false;

  return _EmailLoginInfo(
    isLocalMunicipality: isLocalMunicipality,
    isSuperadmin: isSuperadmin,
  );
}
