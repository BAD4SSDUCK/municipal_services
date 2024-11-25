import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:municipal_services/code/Chat/chat_screen.dart';
import 'package:municipal_services/code/DisplayPages/dashboard.dart';
import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/PDFViewer/view_pdf.dart';
import 'package:provider/provider.dart';
import '../Models/prop_provider.dart';
import '../Models/property.dart';
import '../Models/property_service.dart';

///This dashboard is only for testing and will in the future use the firebase dashboard already built but with the sql connection instead
///I may use this dashboard if the design is better but input all the build pages in the fragment screens
class DashboardFragments extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;

  Future<int> getPropertyCount(BuildContext context) async {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final String cellNumber = propertyProvider.selectedProperty?.cellNum ?? user.phoneNumber!;
    final String districtId = propertyProvider.districtId ?? '';
    final String municipalityId = propertyProvider.municipalityId ?? '';
    return await PropertyService().countPropertiesForUser( cellNumber);
  }

  List<Widget> fragmentScreens(BuildContext context, int propertyCount) {
    final PropertyProvider propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    final Property? selectedProperty = propertyProvider.selectedProperty;
    final String districtId = propertyProvider.districtId ?? '';
    final String municipalityId = propertyProvider.municipalityId ?? '';
    final bool isLocalMunicipality = selectedProperty?.isLocalMunicipality ?? false;

    return [
      if (selectedProperty != null)
        MainMenu(
          property: selectedProperty,
          propertyCount: propertyCount,
          isLocalMunicipality: isLocalMunicipality,
        )
      else
        NoPropertySelectedScreen(),
      if (selectedProperty != null)
        UsersTableViewPage(
          property: selectedProperty,
          userNumber: '',
          propertyAddress: '',
          accountNumber: '',
          districtId: districtId, // Pass districtId
          municipalityId: municipalityId,
          isLocalMunicipality: isLocalMunicipality, // Pass municipalityId
        )
      else
        NoPropertySelectedScreen(),
    ];
  }

  List navigationButtonsProperties = [
    {
      "active_icon": Icons.info,
      "non_active_icon": Icons.info_outline,
      "label": "Home"
    },
    {
      "active_icon": Icons.home,
      "non_active_icon": Icons.home_outlined,
      "label": "Properties"
    },
    {
      "active_icon": Icons.chat_bubble,
      "non_active_icon": Icons.chat_bubble_outline,
      "label": "Chat"
    },
    {
      "active_icon": Icons.person,
      "non_active_icon": Icons.person_outline,
      "label": "Profile"
    },
  ];

  RxInt indexNumber = 0.obs;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      builder: (controller) {
        return FutureBuilder<int>(
          future: getPropertyCount(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text("Error: ${snapshot.error}")),
              );
            } else {
              int propertyCount = snapshot.data ?? 0;
              return Scaffold(
                body: SafeArea(
                  child: Obx(() => fragmentScreens(context, propertyCount)[indexNumber.value]),
                ),
                bottomNavigationBar: Obx(
                      () => BottomNavigationBar(
                    currentIndex: indexNumber.value,
                    onTap: (value) {
                      indexNumber.value = value;
                    },
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedItemColor: Colors.white,
                    unselectedItemColor: Colors.white24,
                    items: List.generate(navigationButtonsProperties.length, (index) {
                      var navBtnProperty = navigationButtonsProperties[index];
                      return BottomNavigationBarItem(
                        backgroundColor: Colors.black45,
                        icon: Icon(navBtnProperty["non_active_icon"]),
                        activeIcon: Icon(navBtnProperty["active_icon"]),
                        label: navBtnProperty["label"],
                      );
                    }),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class NoPropertySelectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("No property selected."),
    );
  }
}




// class DashboardFragments extends StatelessWidget {
//
//
//   final user = FirebaseAuth.instance.currentUser!;
//
//
//   List<Widget> fragmentScreens =[
//     MainMenu(),
//     UsersTableViewPage(),
//     //PhotoFragmentScreen(),
//
//   ];
//
//   List navigationButtonsProperties =[
//     {
//       "active_icon": Icons.info,
//       "non_active_icon": Icons.info_outline,
//       "label": "Home",
//     },
//     {
//       "active_icon": Icons.home,
//       "non_active_icon": Icons.home_outlined,
//       "label": "Properties",
//     },
//     // {
//     //   "active_icon": Icons.camera_alt,
//     //   "non_active_icon": Icons.camera_alt_outlined,
//     //   "label": "Upload",
//     // },
//     {
//       "active_icon": Icons.chat_bubble,
//       "non_active_icon": Icons.chat_bubble_outline,
//       "label": "Chat",
//     },
//     {
//       "active_icon": Icons.person,
//       "non_active_icon": Icons.person_outline,
//       "label": "Profile",
//     },
//   ];
//
//   RxInt indexNumber = 0.obs;
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder(
//
//       builder: (controller) {
//         return Scaffold(
//           //backgroundColor: Colors.grey,
//           body: SafeArea(
//             child: Obx(
//                 ()=> fragmentScreens[indexNumber.value],
//
//             ),
//           ),
//           bottomNavigationBar: Obx(
//               ()=> BottomNavigationBar(
//                   currentIndex: indexNumber.value,
//                 onTap: (value){
//                     indexNumber.value = value;
//                 },
//                 showSelectedLabels: true,
//                 showUnselectedLabels: true,
//                 selectedItemColor: Colors.white,
//                 unselectedItemColor: Colors.white24,
//                 items: List.generate(2, (index) {
//                   var navBtnProperty = navigationButtonsProperties[index];
//                   return BottomNavigationBarItem(
//                       backgroundColor: Colors.black45,
//                       icon: Icon(navBtnProperty["non_active_icon"]),
//                       activeIcon: Icon(navBtnProperty["active_icon"]),
//                       label: navBtnProperty["label"],
//                   );
//                 }),
//               ),
//           ),
//
//         );
//       },
//     );
//   }
//
//   ///pdf view loader getting file name onPress/onTap that passes filename to this class
//   void openPDF(BuildContext context, File file) => Navigator.of(context).push(
//     MaterialPageRoute(builder: (context) => PDFViewerPage(file: file)),
//   );
//
// }
