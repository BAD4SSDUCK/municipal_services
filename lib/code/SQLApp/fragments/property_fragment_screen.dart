import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:municipal_track/code/ImageUploading/image_upload_meter.dart';
import 'package:municipal_track/code/ImageUploading/image_upload_water.dart';

import 'package:municipal_track/code/SQLApp/propertiesData/properties_data.dart';
import 'package:municipal_track/code/SQLApp/userPreferences/current_user.dart';

class PropertyFragmentScreen extends StatelessWidget{

  final CurrentUser _currentUser = Get.put(CurrentUser());
  final PropertiesData _propertiesData = Get.put(PropertiesData());

  bool buttonVis1 = true;
  bool buttonVis2 = false;

  //this widget is for displaying a property field of information with an icon next to it, NB. the icon is to make it look good
  //it is called within a listview page widget
  Widget propertyItemField(IconData iconData, String userData){
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


  int propertyListLength = 0;
  Future<int> findListItemLength() async{
    while(_propertiesData.properties.uid == _currentUser.user.uid){
      propertyListLength + 1;
    }

    return propertyListLength;

  }

//   @override
//   Widget build(BuildContext context){
//     return Scaffold(
//       body: Center(
//         child: Text(
//             "Property Fragment Screen."
//         ),
//       ),
//     );
//   }
// }

  @override
  Widget build(BuildContext context) {
    ///I will be putting an if statement that only matches the users uid to the uid saved in the properties table so the user only sees
    ///a list of his property information and images, I will also have to make a modal that allows updating the electricity and water readings
    ///I will have to make a dropdown button that inputs the year and month so that the user can only update for the current month or view other months
    ///The image upload will have to be worked on with the same month system ie. only current moth upload or overwrite and previous months viewing only

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: Colors.green,
      ),
      body:
      Column(
        children: [

          ///will have to create a ListView.builder
          ///which needs itemCount: and itemBuilder: (context, index){ } for documentation go to https://docs.flutter.dev/cookbook/lists/mixed-list

          ListView(
              padding: const EdgeInsets.all(32),
              children: [

                const SizedBox(height: 20,),

                propertyItemField(Icons.numbers, "Account Number: ${_propertiesData.properties.accountNumber}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.house, "Address: ${_propertiesData.properties.address}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.map, "Area Code: ${_propertiesData.properties.areaCode}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.wallet, "Current bill: R${_propertiesData.properties.eBill}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.power, "Electric Meter Number: ${_propertiesData.properties.electricityMeterNumber}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.power_input, "Electric Meter Reading: ${_propertiesData.properties.electricityMeterReading}"),
                ///add text input to make tappable to edit and save changes for only the current months meter reading

                const SizedBox(height: 10,),

                propertyItemField(Icons.water_drop, "Water Meter Number: ${_propertiesData.properties.waterMeterNumber}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.power_input, "Water Meter Reading: ${_propertiesData.properties.waterMeterReading}"),
                ///add text input to make tappable to edit and save changes for only the current months meter reading

                const SizedBox(height: 10,),

                propertyItemField(Icons.person, "First Name: ${_propertiesData.properties.firstName}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.person, "Last Name: ${_propertiesData.properties.lastName}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.folder_shared, "ID Number: ${_propertiesData.properties.idNumber}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.phone, "Contact Number: ${_propertiesData.properties.cellNumber}"),

                const SizedBox(height: 10,),

                propertyItemField(Icons.email, _currentUser.user.email),

                const SizedBox(height: 20,),

                Center(
                    child: Image.asset(
                      "assets/images/users/man.png",
                      width: 240,
                    )
                ),

                Visibility(visible: buttonVis1, child: const SizedBox(height: 20,)),

                ///button visibility only when the current month is selected
                Visibility(
                  visible: buttonVis1,
                  child: Center(
                      child: Material(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: (){
                            ImageUploadMeter();
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Text(
                              "E-Meter Image Upload",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      )
                  ),
                ),

                const SizedBox(height: 20,),

                Center(
                    child: Image.asset(
                      "assets/images/users/man.png",
                      width: 240,
                    )
                ),

                Visibility(visible: buttonVis1, child: const SizedBox(height: 20,)),

                Visibility(
                  visible: buttonVis1,
                  child: Center(
                      child: Material(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: (){
                            ImageUploadWater();
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Text(
                              "W-Meter Image Upload",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      )
                  ),
                ),

                const SizedBox(height: 20,),

                ///Save changed button
                Visibility(
                  visible: buttonVis1,
                  child: Center(
                      child: Material(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: (){
                            ///This will contain the function that edits the table data of meter readings for the current month only
                          },
                          borderRadius: BorderRadius.circular(32),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 12,
                            ),
                            child: Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                      )
                  ),
                ),

                const SizedBox(height: 50,),

              ]
          ),
        ],
      ),
    );
  }
}