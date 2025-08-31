import 'package:flutter/material.dart';

Widget providerMarker(String type) {
  switch (type) {
    case 'photographer':
      return Icon(Icons.camera_alt, color: Colors.purple, size: 36);
    case 'venue':
      return Icon(Icons.location_city, color: Colors.blue, size: 36);
    case 'caterer':
      return Icon(Icons.restaurant, color: Colors.green, size: 36);
    case 'decorator':
      return Icon(Icons.celebration, color: Colors.orange, size: 36);
    case 'makeup_artist':
      return Icon(Icons.face, color: Colors.pink, size: 36);
    case 'event_organizer':
      return Icon(Icons.event, color: Colors.indigo, size: 36);
    default:
      return Icon(Icons.location_on, color: Colors.red, size: 36);
  }
} 