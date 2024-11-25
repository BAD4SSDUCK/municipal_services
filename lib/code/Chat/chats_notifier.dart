import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> isUserCouncillor(
    String phoneNumber,
    String municipalityId,
    String districtId,
    bool isLocalMunicipality,
    ) async {
  try {
    print("Checking if user is a councillor for phone: $phoneNumber");
    QuerySnapshot councillorCheck = isLocalMunicipality
        ? await FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(municipalityId)
        .collection('councillors')
        .where('councillorPhone', isEqualTo: phoneNumber)
        .limit(1)
        .get()
        : await FirebaseFirestore.instance
        .collection('districts')
        .doc(districtId)
        .collection('municipalities')
        .doc(municipalityId)
        .collection('councillors')
        .where('councillorPhone', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (councillorCheck.docs.isNotEmpty) {
      print("Councillor found.");
      return true;
    } else {
      print("User is not a councillor.");
      return false;
    }
  } catch (e) {
    print("Error checking councillor status: $e");
    return false;
  }
}
