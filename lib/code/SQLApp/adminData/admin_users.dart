import 'package:municipal_services/code/SQLApp/model/admin.dart';
import 'package:municipal_services/code/SQLApp/adminData/admin_preferences.dart';
import 'package:get/get.dart';


///This is the controller using getx for the information on the mySql

class AdminUser extends GetxController {
  Rx<User> _adminUser = User(0,'', '', '', '', '', '','',false).obs;

  User get user => _adminUser.value;

  getAdminUserInfo() async {
    User? getUserInfoFromLocalStorage = await RememberAdminPrefs.readUserInfo();
    _adminUser.value = getUserInfoFromLocalStorage!;
  }
}
