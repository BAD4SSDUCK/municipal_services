import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../Models/prop_provider.dart';
import '../widgets/avatar_image.dart';

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
final Map<String, String?> _imageUrlCache = {};
const _GLOBAL_EMP_DIR = 'files/employees';

String _employeesFolder({
  required bool isLocal,
  String? districtId,
  required String municipalityId,
}) {
  // Try the old per-municipality layout first in case some places still use it.
  // If you KNOW you only use the global folder, you can just return _GLOBAL_EMP_DIR.
  if (!isLocal && districtId != null && districtId.isNotEmpty) {
    return 'files/$districtId/$municipalityId/employees';
  }
  // Local layout (if you ever used it):
  // return 'files/$municipalityId/employees';

  // Default/global
  return _GLOBAL_EMP_DIR;
}

String _normalizeName(String name) {
  final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
}

List<String> _candidateFileNames(String name) {
  final n  = _normalizeName(name);
  final u  = n.replaceAll(' ', '_');
  final lc = n.toLowerCase();
  final lu = u.toLowerCase();

  final bases = {n, u, lc, lu}.toList();
  const exts = ['png', 'jpg', 'jpeg', 'PNG', 'JPG', 'JPEG'];

  return [
    for (final b in bases)
      for (final e in exts) '$b.$e',
  ];
}

Future<String?> _tryFolder(String folder, String employeeName) async {
  final storage = FirebaseStorage.instance;

  // 1) Direct file guesses (fast)
  for (final file in _candidateFileNames(employeeName)) {
    final ref = storage.ref('$folder/$file');
    try {
      final url = await ref.getDownloadURL();
      // debugPrint('✓ Found $file in $folder');
      return url;
    } catch (_) {/* keep trying */}
  }

  // 2) Fallback: list & match by basename (case-insensitive, ignore spaces/_)
  try {
    final list = await storage.ref(folder).listAll();
    final wanted = _normalizeName(employeeName).toLowerCase().replaceAll(' ', '');
    for (final item in list.items) {
      final full = item.name;               // e.g., "Cllr Sibongile Mabaso.png"
      final dot  = full.lastIndexOf('.');
      final base = (dot > 0 ? full.substring(0, dot) : full)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(' ', '')
          .replaceAll('_', '');
      if (base == wanted) {
        final url = await item.getDownloadURL();
        // debugPrint('✓ Matched via listAll: ${item.name} in $folder');
        return url;
      }
    }
  } catch (e) {
    // debugPrint('listAll failed for $folder: $e');
  }

  return null;
}

Future<String?> _resolveEmployeeImageUrl({
  required bool isLocal,
  required String? districtId,
  required String municipalityId,
  required String employeeName,
}) async {
  final cacheKey = '$districtId|$municipalityId|$employeeName|$isLocal';
  if (_imageUrlCache.containsKey(cacheKey)) return _imageUrlCache[cacheKey];

  // Try specific folder (old layout), then the global folder you actually use.
  final specificFolder = _employeesFolder(
    isLocal: isLocal,
    districtId: districtId,
    municipalityId: municipalityId,
  );

  String? url = await _tryFolder(specificFolder, employeeName);
  url ??= await _tryFolder(_GLOBAL_EMP_DIR, employeeName);

  // Final fallback: placeholder in global folder (if you keep it there)
  url ??= await () async {
    try {
      return await FirebaseStorage.instance
          .ref('$_GLOBAL_EMP_DIR/no-image-icon-23494.png')
          .getDownloadURL();
    } catch (_) {
      return null;
    }
  }();

  _imageUrlCache[cacheKey] = url;
  return url;
}
class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  String? userEmail;
   String? districtId;
   String? municipalityId;
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentProperty =
          Provider.of<PropertyProvider>(context, listen: false).selectedProperty;
      final userPhoneNumber = user.phoneNumber ?? '';
      final accountNumber   = currentProperty?.accountNo ?? '';

      final snap = await FirebaseFirestore.instance
          .collectionGroup('properties')
          .where('cellNumber', isEqualTo: userPhoneNumber)
          .where('accountNumber', isEqualTo: accountNumber)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        debugPrint('No matching property found for the user.');
        return;
      }

      final data = snap.docs.first.data();
      final dId  = (data['districtId'] ?? '').toString();
      final mId  = (data['municipalityId'] ?? '').toString();

      setState(() {
        districtId = dId.isEmpty ? null : dId;
        municipalityId = mId.isEmpty ? null : mId;
        isLocalMunicipality = districtId == null; // local if no district id
      });
    } catch (e) {
      debugPrint('Error fetching user details: $e');
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
        stream: isLocalMunicipality
            ? FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(municipalityId!) // ✅ Only use municipalityId for local municipalities
            .collection('employees')
            .snapshots()
            : FirebaseFirestore.instance
            .collection('districts')
            .doc(districtId!) // ✅ Use districtId for district-level queries
            .collection('municipalities')
            .doc(municipalityId!)
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
                future: _resolveEmployeeImageUrl(
                  isLocal: isLocalMunicipality,
                  districtId: districtId,
                  municipalityId: municipalityId!,
                  employeeName: (employee['name'] ?? '').toString(),
                ),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final imageUrl = (imageSnapshot.hasData && imageSnapshot.data!.isNotEmpty)
                      ? imageSnapshot.data!
                      : '';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (imageUrl.isNotEmpty)
                          // ✅ Web-safe image loader (Storage match)
                            avatarImage(url: imageUrl, diameter: 80)
                          else
                          // ✅ Fallback asset if no image found
                            const CircleAvatar(
                              radius: 40,
                              backgroundImage: AssetImage('assets/images/no-image-icon.png'),
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