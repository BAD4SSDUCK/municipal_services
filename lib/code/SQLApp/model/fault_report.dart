import 'dart:ffi';

///This is the map api for the structure of the data passed from mySql

///Important to check how to format fields monthUpdated and year

class Fault{

  int id;
  int uid;
  String accountNumber;
  String propertyAddress;
  String electricFaultDes;
  String waterFaultDes;
  String depAllocation;
  bool faultResolved;
  String dateReported; ///format to be changed from string to datetime with formatting to only month matching the mySql db format

  Fault(
      this.id,
      this.uid,
      this.accountNumber,
      this.propertyAddress,
      this.electricFaultDes,
      this.waterFaultDes,
      this.depAllocation,
      this.faultResolved,
      this.dateReported,
      );

  factory Fault.fromJson(Map<String, dynamic> json) => Fault(
    int.parse(json["id"]),
    int.parse(json["uid"]),
    json["accountNumber"],
    json["propertyAddress"],
    json["electricFaultDes"],
    json["waterFaultDes"],
    json["depAllocation"],
    json["faultResolved"],
    json["dateReported"],///format to be changed from string to datetime with formatting to only month matching the mySql db format
  );

  Map<String, dynamic> toJson() =>
      {
        'id': id.toString(),
        'uid': uid.toString(),
        'accountNumber': accountNumber,
        'propertyAddress': propertyAddress,
        'electricFaultDes': electricFaultDes,
        'waterFaultDes': waterFaultDes,
        'depAllocation': depAllocation,
        'faultResolved': faultResolved.toString(),
        'dateReported': dateReported,///format to be changed from string to datetime with formatting to only month matching the mySql db format
      };

}