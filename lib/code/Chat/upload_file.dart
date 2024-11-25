// import 'dart:io';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
//
// import '../DisplayPages/add_details.dart';
//
// class FileUploadChat {
//   final String chatRoomId;
//
//   FileUploadChat(this.chatRoomId);
//
//   Future<String?> pickAndUploadFile() async {
//     if (auth.currentUser != null) {
//       print("User is logged in with UID: ${auth.currentUser!.uid}");
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.any,
//       allowMultiple: false,
//     );
//
//     if (result != null) {
//       PlatformFile file = result.files.first;
//       File fileData = File(file.path!);
//
//       // Define the storage path
//       String filePath = 'chat_files/${this.chatRoomId}/${file.name}';
//
//       try {
//         // Upload file to Firebase Storage
//         TaskSnapshot snapshot = await FirebaseStorage.instance
//             .ref(filePath)
//             .putFile(fileData);
//
//         // Get download URL
//         String downloadUrl = await snapshot.ref.getDownloadURL();
//         return downloadUrl;
//       } catch (e) {
//         print('Upload error: $e');
//         return null;
//       }
//     }
//     return null;
//     } else {
//       print("User is not authenticated.");
//     }
//     return null;
//   }
//
// }
