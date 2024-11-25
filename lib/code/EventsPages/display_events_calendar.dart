
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
class EventsCalendar extends StatefulWidget {
  const EventsCalendar({super.key});

  @override
  _EventsCalendarState createState() => _EventsCalendarState();
}

class _EventsCalendarState extends State<EventsCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, List<Event>> events = {};

  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchCalendarEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _fetchCalendarEvents() async {
    // Replace 'municipalityId' with the actual municipality ID relevant to the user
    String municipalityId = await _getUserMunicipalityId();

    CollectionReference calendarCollection = FirebaseFirestore.instance
        .collection('localMunicipalities')
        .doc(municipalityId)
        .collection('calendar');

    var data = await calendarCollection.get();

    setState(() {
      events.clear();
      for (var eventSnapshot in data.docs) {
        var eventDescription = eventSnapshot['eventDes'].toString();
        var dateStr = eventSnapshot['date'].toString();

        if (dateStr.isNotEmpty) {
          try {
            DateTime date = DateFormat('yMMMEd').parse(dateStr);
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            events[normalizedDate] = (events[normalizedDate] ?? [])..add(Event(eventDescription, eventSnapshot.id));
          } catch (e) {
            print('Error parsing date: $e');
          }
        }
      }
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  Future<String> _getUserMunicipalityId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('municipalityId') ?? '';
  }

  List<Event> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/greyscale.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'City Event Calendar',
            style: TextStyle(color: Colors.white, fontSize: 19),
          ),
          backgroundColor: Colors.black54,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 3, 14),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: StartingDayOfWeek.saturday,
                    onDaySelected: _onDaySelected,
                    eventLoader: _getEventsForDay,
                    calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          return Positioned(
                            bottom: 1,
                            child: _buildEventsMarker(date, events),
                          );
                        }
                        return null;
                      },
                      selectedBuilder: (context, date, _) => Container(
                        margin: const EdgeInsets.all(6.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          date.day.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      todayBuilder: (context, date, _) => Container(
                        margin: const EdgeInsets.all(6.0),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          date.day.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5.0),
            Expanded(child: _buildEventCards()),
            const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${events.length}',
          style: const TextStyle(color: Colors.white, fontSize: 12.0),
        ),
      ),
    );
  }

  Widget _buildEventCards() {
    String formattedSelectedDay = DateFormat.yMMMEd().format(_focusedDay);

    return ListView.builder(
      itemCount: events[DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day)]?.length ?? 0,
      itemBuilder: (context, index) {
        var event = events[DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day)]?[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            title: Text(event?.title ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            subtitle: Text('Event Date: $formattedSelectedDay', style: const TextStyle(fontSize: 16)),
          ),
        );
      },
    );
  }
}


class Event {
  final String title;
  final String id;

  Event(this.title, this.id);
}

// class EventsCalendar extends StatefulWidget {
//   const EventsCalendar({super.key, });
//
//   @override
//   _EventsCalendarState createState() => _EventsCalendarState();
// }
//
// final FirebaseAuth auth = FirebaseAuth.instance;
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final email = user?.email;
// String userID = uid as String;
// String userEmail = email as String;
// DateTime now = DateTime.now();
//
// class _EventsCalendarState extends State<EventsCalendar> {
//   CalendarFormat _calendarFormat = CalendarFormat.month;
//   DateTime? _selectedDay;
//   DateTime _focusedDay = DateTime.now();
//   String formattedDate = DateFormat.yMMMEd().format(now);
//
//   Map<DateTime, List<Event>> events = {};
//   TextEditingController _eventController = TextEditingController();
//   TextEditingController _dateController = TextEditingController();
//
//   late final ValueNotifier<List<Event>> _selectedEvents;
//
//   bool visAdmin = false; // Initialize visAdmin to false
//   List _allEventResults = []; // Initialize _allEventResults as an empty list
//   String? userEmail;
//   String districtId = '';
//   String municipalityId = '';
//   bool isLocalMunicipality = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCalendar(); // Call this function to fetch details and check admin
//     _selectedDay = _focusedDay;
//     _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
//   }
//
//   @override
//   void dispose() {
//     _selectedEvents.dispose();
//     _eventController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _initializeCalendar() async {
//     await fetchUserDetails(); // Ensure this completes before proceeding
//
//     // Debugging print statements to understand what's happening
//     print("Debugging _initializeCalendar:");
//     print("District ID: $districtId");
//     print("Municipality ID: $municipalityId");
//
//     // Check for valid IDs before fetching the calendar and user stream
//     if (municipalityId.isNotEmpty) {
//       print("Municipality ID is set correctly. Proceeding to get users and calendar stream.");
//       await getUsersStream(); // Fetch user stream after district and municipality are fetched
//       getCalendarStream(); // Fetch calendar data
//     } else {
//       print('Error: Municipality ID is not set properly. Cannot proceed.');
//     }
//   }
//
//
//
//   Future<void> fetchUserDetails() async {
//     try {
//       // Load selected property details from SharedPreferences
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? selectedPropertyAccountNumber = prefs.getString('selectedPropertyAccountNo');
//       bool? isLocalMunicipality = prefs.getBool('isLocalMunicipality');
//       municipalityId = prefs.getString('municipalityId') ?? '';
//       districtId = prefs.getString('districtId') ?? '';
//
//       // Debugging print statements to understand what's happening
//       print("Debugging fetchUserDetails:");
//       print("Selected Property Account Number: $selectedPropertyAccountNumber");
//       print("Is Local Municipality: $isLocalMunicipality");
//       print("Municipality ID: $municipalityId");
//       print("District ID: $districtId");
//
//       // If selectedPropertyAccountNumber is null, we can't proceed
//       if (selectedPropertyAccountNumber == null || isLocalMunicipality == null) {
//         print('Error: No selected property details found in SharedPreferences.');
//         return;
//       }
//
//       // Log and handle local or district municipality separately
//       if (isLocalMunicipality) {
//         if (municipalityId.isEmpty) {
//           print('Error: Municipality ID is missing for local municipality.');
//           return;
//         }
//
//         print('Local Municipality Detected. municipalityId: $municipalityId');
//         // For local municipality, districtId is not required.
//       } else {
//         if (districtId.isEmpty || municipalityId.isEmpty) {
//           print('Error: District or Municipality ID is missing for district property.');
//           return;
//         }
//
//         print('District Municipality Detected. districtId: $districtId, municipalityId: $municipalityId');
//       }
//
//     } catch (e) {
//       print('Error fetching user details: $e');
//     }
//   }
//
//
//   Future<void> getUsersStream() async {
//     try {
//       if (districtId.isEmpty || municipalityId.isEmpty) {
//         print('Error: districtId or municipalityId is missing.');
//         return;
//       }
//
//       var data = await FirebaseFirestore.instance
//           .collection('districts')
//           .doc(districtId)
//           .collection('municipalities')
//           .doc(municipalityId)
//           .collection('users')
//           .get();
//
//       setState(() {
//         for (var userSnapshot in data.docs) {
//           if (userSnapshot.data().containsKey('userRole')) {
//             var user = userSnapshot['email'].toString();
//             var role = userSnapshot['userRole'].toString();
//             if (user == userEmail) {
//               setState(() {
//                 visAdmin = (role == 'Admin' || role == 'Administrator');
//               });
//             }
//           } else {
//             print('Warning: userRole field does not exist for user document: ${userSnapshot.id}');
//           }
//         }
//       });
//     } catch (e) {
//       print('Error fetching users: $e');
//     }
//   }
//
//
//
//   Future<void> getCalendarStream() async {
//     try {
//       // Determine the Firestore path based on whether the property is local or district
//       CollectionReference calendarCollection;
//
//       if (districtId.isEmpty) {
//         // If districtId is empty, it means we are dealing with a local municipality
//         calendarCollection = FirebaseFirestore.instance
//             .collection('localMunicipalities')
//             .doc(municipalityId)
//             .collection('calendar');
//
//         print('Fetching calendar for local municipality. Path: /localMunicipalities/$municipalityId/calendar');
//       } else {
//         // If districtId is not empty, it's a district municipality
//         calendarCollection = FirebaseFirestore.instance
//             .collection('districts')
//             .doc(districtId)
//             .collection('municipalities')
//             .doc(municipalityId)
//             .collection('calendar');
//
//         print('Fetching calendar for district municipality. Path: /districts/$districtId/municipalities/$municipalityId/calendar');
//       }
//
//       // Fetch calendar events from the determined collection
//       var data = await calendarCollection.get();
//
//       // Process fetched data
//       setState(() {
//         _allEventResults = data.docs;
//         events.clear();
//
//         for (var eventSnapshot in data.docs) {
//           var event = eventSnapshot['eventDes'].toString();
//           var dateStr = eventSnapshot['date'].toString();
//
//           // Check if dateStr is not null or empty
//           if (dateStr.isNotEmpty) {
//             try {
//               // Parse the date string
//               DateTime date = DateFormat('yMMMEd').parse(dateStr);
//               DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//
//               // Add event to the calendar
//               events[normalizedDate] = (events[normalizedDate] ?? [])..add(Event(event, eventSnapshot.id));
//             } catch (e) {
//               print('Error parsing date: $e, Date string: $dateStr');
//             }
//           } else {
//             print('Warning: Found an event with an empty or null date.');
//           }
//         }
//
//         // Update selected events for the selected day
//         _selectedEvents.value = _getEventsForDay(_selectedDay!);
//       });
//
//     } catch (e) {
//       print('Error fetching calendar: $e');
//     }
//   }
//
//
//
//
//   List<Event> _getEventsForDay(DateTime day) {
//     DateTime normalizedDay = DateTime(day.year, day.month, day.day);
//     return events[normalizedDay] ?? [];
//   }
//
//   void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
//     if (!isSameDay(_selectedDay, selectedDay)) {
//       setState(() {
//         _selectedDay = selectedDay;
//         _focusedDay = focusedDay;
//         _selectedEvents.value = _getEventsForDay(_selectedDay!);
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         image: DecorationImage(
//           image: AssetImage("assets/images/greyscale.jpg"),
//           fit: BoxFit.cover,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: const Text(
//             'City Event Calendar',
//             style: TextStyle(color: Colors.white, fontSize: 19),
//           ),
//           backgroundColor: Colors.black54,
//           iconTheme: const IconThemeData(color: Colors.white),
//         ),
//         floatingActionButton: Visibility(
//           visible: visAdmin,
//           child: FloatingActionButton(
//             splashColor: Colors.grey,
//             backgroundColor: Colors.blue,
//             child: const Icon(Icons.add),
//             onPressed: () {
//               showDialog(
//                 context: context,
//                 builder: (context) {
//                   return AlertDialog(
//                     scrollable: true,
//                     title: const Text("Event Description"),
//                     content: Padding(
//                       padding: const EdgeInsets.all(8),
//                       child: TextField(
//                         controller: _eventController,
//                       ),
//                     ),
//                     actions: [
//                       ElevatedButton(
//                         onPressed: () {
//                           if (_eventController.text.isNotEmpty) {
//                             _createEvent();
//                             Navigator.of(context).pop();
//                           }
//                         },
//                         child: const Text("Add Event"),
//                       ),
//                     ],
//                   );
//                 },
//               );
//             },
//           ),
//         ),
//         body: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
//               child: Card(
//                 color: Colors.white,
//                 child: Padding(
//                   padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
//                   child: TableCalendar(
//                     firstDay: DateTime.utc(2010, 3, 14),
//                     lastDay: DateTime.utc(2030, 3, 14),
//                     focusedDay: _focusedDay,
//                     selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//                     calendarFormat: _calendarFormat,
//                     startingDayOfWeek: StartingDayOfWeek.saturday,
//                     onDaySelected: _onDaySelected,
//                     eventLoader: _getEventsForDay,
//                     calendarStyle: const CalendarStyle(
//                       outsideDaysVisible: false,
//                     ),
//                     onFormatChanged: (format) {
//                       if (_calendarFormat != format) {
//                         setState(() {
//                           _calendarFormat = format;
//                         });
//                       }
//                     },
//                     onPageChanged: (focusedDay) {
//                       _focusedDay = focusedDay;
//                     },
//                     calendarBuilders: CalendarBuilders(
//                       markerBuilder: (context, date, events) {
//                         if (events.isNotEmpty) {
//                           return Positioned(
//                             bottom: 1,
//                             child: _buildEventsMarker(date, events),
//                           );
//                         }
//                         return null;
//                       },
//                       selectedBuilder: (context, date, _) => Container(
//                         margin: const EdgeInsets.all(6.0),
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: Colors.blue,
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Text(
//                           date.day.toString(),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       todayBuilder: (context, date, _) => Container(
//                         margin: const EdgeInsets.all(6.0),
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: Colors.orange,
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Text(
//                           date.day.toString(),
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                       ),
//                       defaultBuilder: (context, date, _) {
//                         print('Building default cell for $date');
//                         DateTime normalizedDate = DateTime(date.year, date.month, date.day);
//                         if (events.containsKey(normalizedDate)) {
//                           print('Highlighting date with events: $normalizedDate');
//                           return Container(
//                             margin: const EdgeInsets.all(6.0),
//                             alignment: Alignment.center,
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(8.0),
//                             ),
//                             child: Text(
//                               date.day.toString(),
//                               style: const TextStyle(color: Colors.white),
//                             ),
//                           );
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 5.0),
//             Expanded(child: eventCards()),
//             const SizedBox(height: 5),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEventsMarker(DateTime date, List events) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.blue,
//       ),
//       width: 16.0,
//       height: 16.0,
//       child: Center(
//         child: Text(
//           '${events.length}',
//           style: const TextStyle().copyWith(
//             color: Colors.white,
//             fontSize: 12.0,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget eventCards() {
//     String formattedSelectedDay = DateFormat.yMMMEd().format(_focusedDay);
//
//     if (_allEventResults.isNotEmpty) {
//       return ListView.builder(
//         itemCount: _allEventResults.length,
//         itemBuilder: (context, index) {
//           if (_allEventResults[index]['date'] == formattedSelectedDay) {
//             return Card(
//               margin: const EdgeInsets.only(
//                   left: 10, right: 10, top: 0, bottom: 10),
//               child: Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Text(
//                         'Event Date: ${_allEventResults[index]['date']} ',
//                         style: const TextStyle(
//                             fontSize: 16, fontWeight: FontWeight.w700),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         Text(
//                           'Details: ${_allEventResults[index]['eventDes']}',
//                           style: const TextStyle(
//                               fontSize: 16, fontWeight: FontWeight.w400),
//                         ),
//                         Column(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Visibility(
//                               visible: visAdmin,
//                               child: IconButton(
//                                 onPressed: () {
//                                   _delete(_allEventResults[index].id);
//                                 },
//                                 icon: const Icon(
//                                   Icons.delete,
//                                   color: Colors.redAccent,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 5),
//                   ],
//                 ),
//               ),
//             );
//           }
//           return const SizedBox.shrink();
//         },
//       );
//     }
//     return const Center(
//       child: CircularProgressIndicator(),
//     );
//   }
//
//   Future<void> _createEvent() async {
//     String formattedSelectedDay = DateFormat.yMMMEd().format(_selectedDay!);
//     final String eventDescription = _eventController.text;
//
//     if (eventDescription.isNotEmpty) {
//       var calendarCollection = isLocalMunicipality
//           ? FirebaseFirestore.instance
//           .collection('localMunicipalities')
//           .doc(municipalityId)
//           .collection('calendar')
//           : FirebaseFirestore.instance
//           .collection('districts')
//           .doc(districtId)
//           .collection('municipalities')
//           .doc(municipalityId)
//           .collection('calendar');
//
//       await calendarCollection.add({
//         "eventDes": eventDescription,
//         "date": formattedSelectedDay,
//       });
//
//       _eventController.clear();
//       getCalendarStream();
//     }
//   }
//
//
//   Future<void> _delete(String eventId) async {
//     var calendarDoc = isLocalMunicipality
//         ? FirebaseFirestore.instance
//         .collection('localMunicipalities')
//         .doc(municipalityId)
//         .collection('calendar')
//         .doc(eventId)
//         : FirebaseFirestore.instance
//         .collection('districts')
//         .doc(districtId)
//         .collection('municipalities')
//         .doc(municipalityId)
//         .collection('calendar')
//         .doc(eventId);
//
//     await calendarDoc.delete();
//     getCalendarStream();
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('You have successfully deleted an event!'),
//         ),
//       );
//     }
//   }
//
// }
//
// class Event {
//   final String title;
//   final String id;
//
//   Event(this.title, this.id);
// }
