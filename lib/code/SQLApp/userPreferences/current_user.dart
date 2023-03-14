import 'package:municipal_track/code/SQLApp/model/user.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/user_preferences.dart';
import 'package:get/get.dart';


///This is the controller using getx for the information on the mySql

class CurrentUser extends GetxController {
  Rx<User> _currentUser = User(0,'', '', '', '', '', '',false).obs;

  User get user => _currentUser.value;

  getUserInfo() async {
    User? getUserInfoFromLocalStorage = await RememberUserPrefs.readUserInfo();
    _currentUser.value = getUserInfoFromLocalStorage!;
  }
}
