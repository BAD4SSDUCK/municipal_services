import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:municipal_services/code/login/login_page_google.dart';
import 'package:municipal_services/main.dart';

import '../DisplayPages/dashboard.dart';
import '../DisplayPages/prop_selection.dart';
import '../Models/property.dart';


///Auth service was made separately from original authpage. This covers authentication for only gmail auth only

// class AuthService{
//   handleAuthState(){
//     return StreamBuilder(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (BuildContext context, snapshot){
//           if (snapshot.hasData){
//             return PropertySelectionScreen(properties: [],);
//           } else {
//             return LoginPageG();
//           }
//         });
//   }
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
              return Center(child: CircularProgressIndicator());
            } else if (propertiesSnapshot.hasError) {
              return Center(child: Text('Error fetching properties: ${propertiesSnapshot.error}'));
            } else if (propertiesSnapshot.hasData) {
              List<Property> properties = propertiesSnapshot.data!;
              bool isLocalMunicipality = properties.any((property) => property.isLocalMunicipality);
              return PropertySelectionScreen(properties: propertiesSnapshot.data!,userPhoneNumber:  FirebaseAuth.instance.currentUser!.phoneNumber!, isLocalMunicipality: isLocalMunicipality,);
            } else {
              return Center(child: Text('No properties found for the user.'));
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

  signInWithGoogle() async{
    final GoogleSignInAccount? googleUser = await GoogleSignIn(
        scopes: <String>["email"]).signIn();

    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  signOut(){
    FirebaseAuth.instance.signOut();
  }
