import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../Models/prop_provider.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  const EmployeeDirectoryScreen({super.key, });

  @override
  State<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}
final FirebaseAuth auth = FirebaseAuth.instance;
DateTime now = DateTime.now();
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  String? userEmail;
   String districtId='';
   String municipalityId='';
  bool isLocalMunicipality = false;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchUserDetails() async {
    final currentProperty =
        Provider.of<PropertyProvider>(context, listen: false).selectedProperty;

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String userPhoneNumber = user.phoneNumber!;
        String? accountNumber = currentProperty?.accountNo;

        print('User Phone Number: $userPhoneNumber');
        print('Account Number: $accountNumber');

        QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
            .collectionGroup('properties')
            .where('cellNumber', isEqualTo: userPhoneNumber)
            .where('accountNumber', isEqualTo: accountNumber)
            .limit(1)
            .get();

        if (propertySnapshot.docs.isNotEmpty) {
          var propertyDoc = propertySnapshot.docs.first;
          var propertyData = propertyDoc.data() as Map<String, dynamic>;

          districtId = propertyData['districtId'];
          municipalityId = propertyData['municipalityId'];
          isLocalMunicipality = districtId == null || districtId.isEmpty;
            if(mounted){
          setState(() {});} // Update UI after fetching details
        } else {
          print('No matching property found for the user.');
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }


  Future<String> _getImageUrl(String districtId, String municipalityId, String imageName) async {
  try {
    return await FirebaseStorage.instance
        .ref('files/$districtId/$municipalityId/employees/$imageName.jpg')
        .getDownloadURL();
  } catch (e) {
    // Return default image URL if the specific image is not found
    return await FirebaseStorage.instance
        .ref('files/$districtId/$municipalityId/employees/no-image-icon-23494.png')
        .getDownloadURL();
  }
}

  Future<void> _launchDialer(String number) async {
    final Uri telUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw 'Could not launch $telUri';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch $emailUri';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Municipal Directory'),
        backgroundColor: Colors.green,
      ),
      body: districtId == null || municipalityId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection(isLocalMunicipality ? 'localMunicipalities' : 'districts')
            .doc(isLocalMunicipality ? municipalityId : districtId)
            .collection('municipalities')
            .doc(municipalityId)
            .collection('employees')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error fetching employee data'),
            );
          }
          final employeeDocs = snapshot.data?.docs ?? [];
          if (employeeDocs.isEmpty) {
            return const Center(
              child: Text('No employees found'),
            );
          }
          return ListView.builder(
            itemCount: employeeDocs.length,
            itemBuilder: (context, index) {
              final employee = employeeDocs[index];
              return FutureBuilder(
                future: _getImageUrl(districtId!, municipalityId!, employee['name']),
                builder: (context, AsyncSnapshot<String> imageSnapshot) {
                  if (imageSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final imageUrl = imageSnapshot.data;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: imageUrl != null
                                ? NetworkImage(imageUrl)
                                : const AssetImage('assets/images/no-image-icon.png')
                            as ImageProvider,
                            onBackgroundImageError: (_, __) => const Icon(Icons.error),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            employee['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Position: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: employee['position'],
                                  style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _launchDialer(employee['number']),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Number: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: employee['number'],
                                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _launchDialer(employee['alternate_number']),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Alternate Number: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: employee['alternate_number'],
                                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _launchEmail(employee['email']),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Email: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: employee['email'],
                                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}