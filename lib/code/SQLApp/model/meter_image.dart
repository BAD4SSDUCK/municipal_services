import 'dart:typed_data';

import 'package:http/http.dart';

///This is the map api for the structure of the data passed from mySql

///Important to check how to format fields monthUpdated and year

class MeterImage{

  int id;
  String address;
  int uid;
  MultipartFile electricImage;
  MultipartFile waterImage;
  DateTime uploadTime; ///format to be changed from string to datetime with formatting to only month matching the mySql db format

  MeterImage(
      this.id,
      this.uid,
      this.address,
      this.electricImage,
      this.waterImage,
      this.uploadTime,
      );

  factory MeterImage.fromJson(Map<String, dynamic> json) => MeterImage(
    int.parse(json["id"]),
    int.parse(json["uid"]),
    json["address"],
    json["electricImage"],///find out for files
    json["waterImage"],///find out for files
    json["uploadTime"],///format to be changed from string to datetime with formatting to only month matching the mySql db format
  );

  Map<String, dynamic> toJson() =>
      {
        'id': id.toString(),
        'uid': uid.toString(),
        'address': address,
        'electricImage': electricImage,
        'waterImage': waterImage,
        'uploadTime': uploadTime,///format to be changed from string to datetime with formatting to only month matching the mySql db format
      };

}