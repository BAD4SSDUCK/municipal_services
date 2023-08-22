import 'package:municipal_tracker_msunduzi/code/SQLApp/model/property.dart';
import 'package:municipal_tracker_msunduzi/code/SQLApp/propertiesData/property_storage.dart';

import 'package:municipal_tracker_msunduzi/code/SQLApp/model/user.dart';
import 'package:municipal_tracker_msunduzi/code/SQLApp/userPreferences/user_preferences.dart';

import 'package:get/get.dart';


///This is the controller using getx for the information on the mySql

class PropertiesData extends GetxController {

  Rx<Property> _propertiesData = Property(0,'', '', 0, '', 0, '', '', '', '', '', '', 0, 0, '', '').obs;
  Property get properties => _propertiesData.value;

  Rx<User> _currentUser = User(0,'', '', '', '', '', '','',false).obs;
  User get user => _currentUser.value;
  getUserInfo() async {
    User? getUserInfoFromLocalStorage = await RememberUserPrefs.readUserInfo();
    _currentUser.value = getUserInfoFromLocalStorage!;
  }

  getPropertyInfo() async {
    if(_currentUser.value.uid == _propertiesData.value.uid) {
      Property? getPropertyInfoFromLocalStorage = await RememberPropertyInfo
          .readPropertyInfo();
      _propertiesData.value = getPropertyInfoFromLocalStorage!;
    }
  }

  getAllPropertiesInfo() async{
    Property? getPropertyInfoFromLocalStorage = await RememberPropertyInfo
        .readPropertyInfo();
    _propertiesData.value = getPropertyInfoFromLocalStorage!;
  }


}
