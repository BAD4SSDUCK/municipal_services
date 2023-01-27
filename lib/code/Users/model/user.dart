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

}