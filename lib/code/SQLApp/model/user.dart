///This is the map api for the structure of the data passed from mySql

class User{
  int uid;
  String cellNumber;
  String email;
  String firstName;
  String lastName;
  String userName;
  String userPassword;

  User(
      this.uid,
      this.cellNumber,
      this.email,
      this.firstName,
      this.lastName,
      this.userName,
      this.userPassword,
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
    int.parse(json["uid"]),
    json["cellNumber"],
    json["email"],
    json["firstName"],
    json["lastName"],
    json["userName"],
    json["userPassword"],
  );

  Map<String, dynamic> toJson() =>
      {
        'uid': uid.toString(),
        'cellNumber': cellNumber,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'userName': userName,
        'userPassword': userPassword,
      };
//
}