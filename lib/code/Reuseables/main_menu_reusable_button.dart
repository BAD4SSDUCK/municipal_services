import 'package:flutter/material.dart';

class ReusableMenuButton extends StatelessWidget {
  const ReusableMenuButton({Key? key, required this.colour, required this.myImage, required this.onPress}) : super(key: key);
  final Color colour;
  final AssetImage myImage;
  final Function onPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPress();
      }, // Handle your callback.
      splashColor: colour,
      child: Ink(
        height: 120,
        width: 250,
        decoration:  BoxDecoration(
          image: DecorationImage(
            image: myImage,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}