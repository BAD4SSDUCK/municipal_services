import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ElevatedIconButton extends StatelessWidget {
  const ElevatedIconButton({Key? key, required this.onPress, required this.labelText, required this.fSize, required this.faIcon, required this.fgColor, required this.btSize, }) : super(key: key);

  final Function onPress;
  final String labelText;
  final double fSize;
  final FaIcon faIcon;
  final Size btSize;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB( 10.0,5.0,10.0,5.0),
      child: ElevatedButton.icon(
        onPressed: (){
          onPress();
        },
        icon: faIcon,
        label: Text(labelText, style: TextStyle(
          color: Colors.black,
            fontSize:fSize,
            fontFamily: 'Gotham',
            fontWeight: FontWeight.w900),
        ),
        style: IconButton.styleFrom(
          foregroundColor: fgColor,
          minimumSize: btSize,
          disabledForegroundColor: Colors.red.withOpacity(0.38), //foreground
          backgroundColor: Colors.white70,
          shadowColor: Colors.black,
          side: const BorderSide(
            width: 5,
            color: Colors.black54,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100)),
        ),
      ),
    );
  }
}

class BasicIconButtonGreen extends StatelessWidget {
  const BasicIconButtonGreen({Key? key, required this.onPress, required this.labelText, required this.fSize, required this.faIcon, required this.fgColor, required this.btSize, }) : super(key: key);

  final Function onPress;
  final String labelText;
  final double fSize;
  final FaIcon faIcon;
  final Size btSize;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB( 10.0,5.0,10.0,5.0),
      child: ElevatedButton.icon(
        onPressed: (){
          onPress();
        },
        icon: faIcon,
        label: Text(labelText, style: TextStyle(
            color: Colors.white,
            fontSize:fSize,
            fontFamily: 'Gotham',
            fontWeight: FontWeight.w900),
        ),
        style: IconButton.styleFrom(
          foregroundColor: fgColor,
          minimumSize: btSize,
          disabledForegroundColor: Colors.red.withOpacity(0.38), //foreground
          backgroundColor: Colors.green,
          shadowColor: Colors.black,
          // side: const BorderSide(
          //   width: 5,
          //   color: Colors.black54,
          // ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
