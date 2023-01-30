import 'dart:convert';

import 'package:municipal_track/code/Users/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RememberUserPrefs{

  //save-remember User-info
  static Future<void> storeUserInfo(User userInfo) async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String userJsonData = jsonEncode(userInfo.toJson());
    await preferences.setString("currentUser", userJsonData);
  }

  //This keeps the local data of the logged in user locally so that a user does not have to re-login everytime they open the app

  //get-read user-info
  static Future<User?> readUserInfo() async{
    User? currentUserInfo;
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? userInfo = preferences.getString("currentUser");
    if(userInfo != null){
      Map<String, dynamic> userDataMap = jsonDecode(userInfo);
      currentUserInfo = User.fromJson(userDataMap);
    }
    return currentUserInfo;
  }

}
