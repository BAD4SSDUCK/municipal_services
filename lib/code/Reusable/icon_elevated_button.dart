import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ElevatedIconButton extends StatelessWidget {
  const ElevatedIconButton({super.key, required this.onPress, required this.labelText, required this.fSize, required this.faIcon, required this.fgColor, required this.btSize, });

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
        label: Text(labelText,
          textAlign: TextAlign.center,
          style: GoogleFonts.tenorSans(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: fSize,
          ),
        ),
        style: IconButton.styleFrom(
          foregroundColor: fgColor,
          minimumSize: Size(140.w, 120.h),
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
        label: Text(labelText,
          textAlign: TextAlign.center,
          style: GoogleFonts.tenorSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fSize,),
        ),
        style: IconButton.styleFrom(
          foregroundColor: fgColor,
          minimumSize: btSize,
          disabledForegroundColor: Colors.red.withOpacity(0.38), //foreground
          backgroundColor: Colors.green,
          shadowColor: Colors.black,
          side: const BorderSide(
            width: 1,
            color: Colors.black38,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class BasicIconButtonGrey extends StatelessWidget {
  const BasicIconButtonGrey({super.key, required this.onPress, required this.labelText, required this.fSize, required this.faIcon, required this.fgColor, required this.btSize, });

  final Function onPress;
  final String labelText;
  final double fSize;
  final FaIcon faIcon;
  final Size btSize;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB( 5.0,2.0,5.0,1.0),
      child: ElevatedButton.icon(
        onPressed: (){
          onPress();
        },
        icon: IconTheme(
          data: IconThemeData(color: fgColor),
          child: faIcon,
        ),
        label: Text(labelText,
          textAlign: TextAlign.center,
          style: GoogleFonts.tenorSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: fSize,),
        ),
        style: IconButton.styleFrom(
          foregroundColor: fgColor,
          minimumSize: btSize,
          disabledForegroundColor: Colors.red.withOpacity(0.38), //foreground
          backgroundColor: Colors.white70,
          shadowColor: Colors.black,
          side: const BorderSide(
            width: 1,
            color: Colors.black38,
          ),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
