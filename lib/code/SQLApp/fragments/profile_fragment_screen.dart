import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:municipal_track/code/SQLApp/auth/login_screen.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/property_preferences.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/image_preferences.dart';

class ProfileFragmentScreen extends StatelessWidget {

  ///this final works as a reference to get the current user class _currentUser."user"."userItem" is how to use the reference to display the mySql data in widgets
  final CurrentUser _currentUser = Get.put(CurrentUser());
  
  signOutUser() async {
    var resultResponse = await Get.dialog(
        AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius:
          BorderRadius.all(Radius.circular(16))),
          title: const Text("Logout!"),
          content: const Text(
              "Are you sure you would like to Logout?"),
          actions: [
            IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(
                Icons.cancel,
                color: Colors.red,
              ),
            ),
            IconButton(
              onPressed: () async {
                FirebaseAuth.instance.signOut();
                Get.back(result: "loggedOut");
              },
              icon: const Icon(
                Icons.done,
                color: Colors.green,
              ),
            ),
          ],
        ),
    );

    if(resultResponse == "loggedOut"){
      //remove user data and properties data from phone local storage
      RememberPropertyInfo.removePropertyInfo();
      RememberImageInfo.removeImageInfo();
      RememberUserPrefs.removeUserInfo().then((value){Get.off(LoginScreen());});
    }

  }

  //this widget is for displaying a field of user information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget userInfoItemProfile(IconData iconData, String userData){
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8,),
      child: Row(
        children: [
          Icon(
            iconData,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(width: 16,),
          Text(
            userData,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage("assets/images/greybg.gif"),
            fit: BoxFit.cover),
      ),
      child: ListView(
        padding: const EdgeInsets.all(32),
          children: [
            //const SizedBox(height: 5,),

            Center(
                child: Image.asset(
                  "assets/images/users/man.png",
                  width: 240,
                )
            ),

            const SizedBox(height: 20,),

            userInfoItemProfile(Icons.account_box, "Username: ${_currentUser.user.userName}"),

            const SizedBox(height: 10,),

            userInfoItemProfile(Icons.person, "First Name: ${_currentUser.user.firstName}"),

            const SizedBox(height: 10,),

            userInfoItemProfile(Icons.person, "Last Name: ${_currentUser.user.lastName}"),

            const SizedBox(height: 10,),

            userInfoItemProfile(Icons.phone, _currentUser.user.cellNumber),

            const SizedBox(height: 10,),

            userInfoItemProfile(Icons.email, _currentUser.user.email),

            const SizedBox(height: 20,),

            Center(
              child: Material(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: (){
                    signOutUser();
                  },
                  borderRadius: BorderRadius.circular(32),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    child: Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

              )
            ),

          ]
      ),
    );
  }
}