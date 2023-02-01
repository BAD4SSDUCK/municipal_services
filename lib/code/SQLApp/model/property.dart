///This is the map api for the structure of the data passed from mySql

///Important to check how to format fields monthUpdated and year

class Property{

  int id;
  String accountNumber;
  String address;
  int areaCode;
  String cellNumber;
  int eBill;
  String electricityMeterNumber;
  String electricityMeterReading;
  String waterMeterNumber;
  String waterMeterReading;
  String firstName;
  String lastName;
  int idNumber;
  int uid;
  String monthUpdated; ///format to be changed from string to datetime with formatting to only month matching the mySql db format
  String year; ///format to be changed from string to datetime with formatting to only month matching the mySql db format

  Property(
      this.id,
      this.accountNumber,
      this.address,
      this.areaCode,
      this.cellNumber,
      this.eBill,
      this.electricityMeterNumber,
      this.electricityMeterReading,
      this.waterMeterNumber,
      this.waterMeterReading,
      this.firstName,
      this.lastName,
      this.idNumber,
      this.uid,
      this.monthUpdated,
      this.year,
      );

  factory Property.fromJson(Map<String, dynamic> json) => Property(
    int.parse(json["id"]),
    json["accountNumber"],
    json["address"],
    int.parse(json["areaCode"]),
    json["cellNumber"],
    int.parse(json["eBill"]),
    json["electricityMeterNumber"],
    json["electricityMeterReading"],
    json["waterMeterNumber"],
    json["waterMeterReading"],
    json["firstName"],
    json["lastName"],
    int.parse(json["idNumber"]),
    int.parse(json["uid"]),
    json["monthUpdated"],///format to be changed from string to datetime with formatting to only month matching the mySql db format
    json["year"],///format to be changed from string to datetime with formatting to only month matching the mySql db format
  );

  Map<String, dynamic> toJson() =>
      {
        'id': id.toString(),
        'accountNumber': accountNumber,
        'address': address,
        'areaCode': areaCode.toString(),
        'cellNumber': cellNumber,
        'eBill': eBill.toString(),
        'electricityMeterNumber': electricityMeterNumber,
        'electricityMeterReading': electricityMeterReading,
        'waterMeterNumber': waterMeterNumber,
        'waterMeterReading': waterMeterReading,
        'firstName': firstName,
        'lastName': lastName,
        'idNumber': idNumber.toString(),
        'uid': uid.toString(),
        'monthUpdated': monthUpdated,///format to be changed from string to datetime with formatting to only month matching the mySql db format
        'year': year,///format to be changed from string to datetime with formatting to only month matching the mySql db format
      };

}