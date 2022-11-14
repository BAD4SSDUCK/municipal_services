import 'package:flutter/material.dart';

class MapUserBadge extends StatelessWidget {
  const MapUserBadge({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 0, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset.zero,
            )
          ]
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                image: const DecorationImage(
                    image: AssetImage('assets/images/user.png'),
                    fit: BoxFit.cover
                ),
                border: Border.all(
                  color: Colors.green,
                  width: 1,
                )
            ),
          ),
          const SizedBox(width: 10,),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Individual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Text('Location',
                    style: TextStyle(
                      color: Colors.green,
                    ),),
                ],
              )
          ),
          const Icon(Icons.location_pin,color: Colors.green, size: 40,)
        ],
      ),
    );
  }
}