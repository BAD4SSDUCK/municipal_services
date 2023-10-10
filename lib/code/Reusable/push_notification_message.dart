import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void sendPushMessage(String token, String title, String body,) async{
  try{
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=AAAA5PnILx8:APA91bFrXK321LraFWsbh6er8bWta0ggbvb0pxUhVnzYfjYbP6rDMecElIu0pAYnKOWthddgsZUxXMEPPXxT1EguNdkGYZsrm3fjjlGeY2EP4bxjgvn9IZQvgxKzv6w8ES2f_g9Idlv5',
      },
      body: jsonEncode(
        <String, dynamic>{
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action':'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'title': title,
            'body': body,
          },

          "notification": <String, dynamic>{
            "title": title,
            "body": body,
            "android_channel_id": "User"
          },
          "to": token,
        },
      ),
    );
  } catch(e) {
    if(kDebugMode){
      print("error push notification");
    }
  }
}