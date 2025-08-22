import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:municipal_services/code/login/login_page_google.dart';
import 'package:municipal_services/main.dart';
import 'package:municipal_services/code/login/login_page.dart';

import '../DisplayPages/dashboard.dart';
import '../DisplayPages/prop_selection.dart';
import '../Models/property.dart';

///Auth service was made separately from original authpage. This covers authentication for only gmail auth only

class AuthService{

  // handleAuthState(){
  //   return StreamBuilder(
  //       stream: FirebaseAuth.instance.authStateChanges(),
  //       builder: (BuildContext context, snapshot){
  //         if (snapshot.hasData){
  //           return MainMenu();
  //         } else {
  //           return LoginPageG();
  //         }
  //       });
  // }
  // handleAuthState(){
  //   return StreamBuilder(
  //       stream: FirebaseAuth.instance.authStateChanges(),
  //       builder: (BuildContext context, snapshot){
  //         if (snapshot.hasData){
  //           return PropertySelectionScreen(properties: [],); // Navigate to property selection
  //         } else {
  //           return LoginPageG();
  //         }
  //       });
  // }
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


  handleAuthState() {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          // If the user is authenticated, fetch properties
          return FutureBuilder(
            future: fetchUserProperties(FirebaseAuth.instance.currentUser?.phoneNumber),
            builder: (BuildContext context, AsyncSnapshot<List<Property>> propertiesSnapshot) {
              if (propertiesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (propertiesSnapshot.hasError) {
                return Center(child: Text('Error fetching properties: ${propertiesSnapshot.error}'));
              } else if (propertiesSnapshot.hasData) {
                List<Property> properties = propertiesSnapshot.data!;
                if (properties.isEmpty) {
                  return const Center(child: Text('No properties found for the user.'));
                }

                Property firstProp = properties.first;
                bool isLocalMunicipality = firstProp.isLocalMunicipality;

                return FutureBuilder(
                  future: fetchMunicipalityUtilityTypes(
                    firstProp.municipalityId,
                    firstProp.districtId,
                    firstProp.isLocalMunicipality,
                  ),
                  builder: (context, AsyncSnapshot<Map<String, bool>> utilitySnapshot) {
                    if (utilitySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (utilitySnapshot.hasError || !utilitySnapshot.hasData) {
                      return const Center(child: Text('Error loading utility types.'));
                    }

                    final handlesWater = utilitySnapshot.data!['handlesWater']!;
                    final handlesElectricity = utilitySnapshot.data!['handlesElectricity']!;

                    return PropertySelectionScreen(
                      properties: properties,
                      userPhoneNumber: FirebaseAuth.instance.currentUser!.phoneNumber!,
                      isLocalMunicipality: isLocalMunicipality,
                      handlesWater: handlesWater,
                      handlesElectricity: handlesElectricity,
                    );
                  },
                );
              } else {
                return const Center(child: Text('No properties found for the user.'));
              }
            },
          );

        } else {
          // If the user is not authenticated, navigate to the login page
          return LoginPageG();
        }
      },
    );
  }

// Ensure you have this method defined as well:
  Future<List<Property>> fetchUserProperties(String? userPhone) async {
    List<Property> properties = [];

    if (userPhone == null) return properties;

    try {
      // Fetch both district-based and local municipality properties
      final districtsSnapshot = await FirebaseFirestore.instance.collection('districts').get();
      final localMunicipalitiesSnapshot = await FirebaseFirestore.instance.collection('localMunicipalities').get();

      // Fetch properties from district-based municipalities
      for (var districtDoc in districtsSnapshot.docs) {
        final municipalitiesSnapshot = await districtDoc.reference.collection('municipalities').get();

        for (var municipalityDoc in municipalitiesSnapshot.docs) {
          final propertiesSnapshot = await municipalityDoc.reference.collection('properties')
              .where('cellNumber', isEqualTo: userPhone)
              .get();

          for (var propertyDoc in propertiesSnapshot.docs) {
            properties.add(Property.fromSnapshot(propertyDoc));
          }
        }
      }

      // Fetch properties from local municipalities
      for (var localMunicipalityDoc in localMunicipalitiesSnapshot.docs) {
        final propertiesSnapshot = await localMunicipalityDoc.reference.collection('properties')
            .where('cellNumber', isEqualTo: userPhone)
            .get();

        for (var propertyDoc in propertiesSnapshot.docs) {
          properties.add(Property.fromSnapshot(propertyDoc));
        }
      }
    } catch (e) {
      print('Error fetching properties: $e');
    }

    return properties;
  }
  Future<UserCredential> signInWithGoogle() async {
    // Optional: only on very old host platforms this could be false
    if (!await GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In “authenticate()” not supported on this platform.');
    }

    // Launch the Google flow
    final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
    if (account == null) {
      throw Exception('Sign-in aborted by user');
    }

    // Fetch tokens (idToken only in v7)
    final GoogleSignInAuthentication auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

    // Firebase sign-in
    return FirebaseAuth.instance.signInWithCredential(credential);
  }
  // signInWithGoogle() async{
  //   final GoogleSignInAccount? googleUser = await GoogleSignIn(
  //       scopes: <String>["email"]).signIn();
  //
  //   final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  //
  //   final credential = GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );
  //
  //   return await FirebaseAuth.instance.signInWithCredential(credential);
  // }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.disconnect(); // optional: also revoke Google session
  }
}