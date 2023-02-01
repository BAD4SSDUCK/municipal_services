import 'package:municipal_track/code/SQLApp/model/property.dart';
import 'package:municipal_track/code/SQLApp/propertiesData/property_preferences.dart';
import 'package:get/get.dart';


///This is the controller using getx for the information on the mySql

class PropertiesData extends GetxController {
  Rx<Property> _propertiesData = Property(0,'', '', 0, '', 0, '', '', '', '', '', '', 0, 0, '', '').obs;

  Property get properties => _propertiesData.value;

  getPropertyInfo() async {
    Property? getPropertyInfoFromLocalStorage = await RememberPropertyInfo.readPropertyInfo();
    _propertiesData.value = getPropertyInfoFromLocalStorage!;
  }
}
