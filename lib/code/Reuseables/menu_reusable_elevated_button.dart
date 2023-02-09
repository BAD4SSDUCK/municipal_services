import 'package:flutter/material.dart';

class ReusableElevatedButton extends StatelessWidget {
  const ReusableElevatedButton({Key? key, required this.onPress, required this.buttonText, required this.fSize, }) : super(key: key);

  final Function onPress;
  final String buttonText;
  final double fSize;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.black,
        minimumSize: const Size(350,60),
        disabledForegroundColor: Colors.red.withOpacity(0.38), //foreground
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: (){
        onPress();
      },
      child:  Text(buttonText, style: TextStyle(
        //default size 26 change was made for driver section
          fontSize:fSize,
          fontFamily: 'Gotham',
          fontWeight: FontWeight.w900),
      ),
    );
  }
}
