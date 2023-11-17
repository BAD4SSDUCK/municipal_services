import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EventsCalendar extends StatefulWidget {
  const EventsCalendar({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() =>_EventsCalendarState();
  }

final FirebaseAuth auth = FirebaseAuth.instance;
final User? user = auth.currentUser;
final uid = user?.uid;
final email = user?.email;
String userID = uid as String;
String userEmail = email as String;
DateTime now = DateTime.now();

  class _EventsCalendarState extends State<EventsCalendar>{

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  String formattedDate = DateFormat.yMMMEd().format(now);

  Map<DateTime, List<Event>> events ={};
  TextEditingController _eventController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  late final ValueNotifier<List<Event>> _selectedEvents;

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay){
    if(!isSameDay(_selectedDay,selectedDay)){
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  List<Event> _getEventForDay(DateTime day){
    return events[day] ?? [];
  }

  bool visShow = true;
  bool visHide = false;
  bool visAdmin = false;

  String userRole = '';
  List _allUserResults = [];
  List _allEventResults = [];

  final CollectionReference _eventCalendarList =
  FirebaseFirestore.instance.collection('calendar');

  @override
  void initState() {
    super.initState();
    adminCheck();
    getCalendarStream();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventForDay(_selectedDay!));
  }

  @override
  void dispose(){
    super.dispose();
  }

  void adminCheck() {
    getUsersStream();
    if(userRole == 'Admin'|| userRole == 'Administrator'){
      visAdmin = true;
    } else {
      visAdmin = false;
    }
  }

  getUsersStream() async{
    var data = await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      _allUserResults = data.docs;
    });
    getUserDetails();
  }

  getUserDetails() async {
    for (var userSnapshot in _allUserResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var user = userSnapshot['email'].toString();
      var role = userSnapshot['userRole'].toString();

      if (user == userEmail) {
        userRole = role;
        print('My Role is::: $userRole');

        if (userRole == 'Admin' || userRole == 'Administrator') {
          visAdmin = true;
        } else {
          visAdmin = false;
        }
      }
    }
  }

  getCalendarStream() async{
    var data = await FirebaseFirestore.instance.collection('calendar').get();
    _allEventResults = data.docs;
    getCalendarDetails();
  }

  getCalendarDetails() async {
    for (var userSnapshot in _allEventResults) {
      ///Need to build a property model that retrieves property data entirely from the db
      var event = userSnapshot['eventDes'].toString();
      var date = userSnapshot['date'].toString();
      print(event + date);
      print(_allEventResults);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(

      ///When a background image is created this section will display it on the dashboard instead of just a grey colour with no background
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/images/greyscale.jpg"), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, //grey[350],
        appBar: AppBar(
          title:
          const Text('City Event Calendar', style: TextStyle(color: Colors.white, fontSize: 19),),
          backgroundColor: Colors.black54,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        floatingActionButton: Visibility(
          visible: visAdmin,
          child: FloatingActionButton(
            splashColor: Colors.grey,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),

            onPressed: () {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  scrollable: true,
                  title: const Text("Event Description"),
                  content: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _eventController,

                    ),
                  ),
                  actions: [
                    ElevatedButton(
                        onPressed: () {
                          events.addAll({
                            _selectedDay!: [Event(_eventController.text)]
                          });

                          _create();
                          getCalendarStream();

                          _selectedEvents.value = _getEventForDay(_selectedDay!);

                          Navigator.of(context).pop();

                          },
                        child: const Text("Add Event")
                    )
                  ],

                );
              });

            },
          ),
        ),
        // drawer: const NavDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8,8,8,8),

              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8,8,8,20),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2010, 3, 14),
                    lastDay: DateTime.utc(2030, 3, 14),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    startingDayOfWeek: StartingDayOfWeek.saturday,
                    onDaySelected: _onDaySelected,
                    eventLoader: _getEventForDay,
                    calendarStyle: const CalendarStyle(
                      outsideDaysVisible: false,
                    ),
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          getCalendarStream();
                        });
                      }
                    },
                    onPageChanged: (focusedDay){
                      getCalendarStream();
                      _focusedDay = focusedDay;
                    },
                  ),                  
                ),
              ),
            ),
            const SizedBox(height: 5.0,),

            Expanded(child: eventCards(),),

            const SizedBox(height: 5,),

          ],
        ),
      ),
    );
  }

  Widget eventCards() {

    String formattedSelectedDay = DateFormat.yMMMEd().format(_focusedDay);
    getCalendarStream();

    if (_allEventResults.isNotEmpty) {
      return ListView.builder(
        ///this call is to display all details for all users but is only displaying for the current user account.
        ///it can be changed to display all users for the staff to see if the role is set to all later on.

        itemCount: _allEventResults.length,
        itemBuilder: (context, index) {

          print('Day Selected is::: $formattedSelectedDay');
          print('Day from db is::: ${_allEventResults[index]['date']}');

          if(_allEventResults[index]['date'] == formattedSelectedDay){
            return Card(
                margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Event Date: ${_allEventResults[index]['date']} ',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 10,),
                        Row(
                          children: [
                            Text(
                              'Details: ${_allEventResults[index]['eventDes']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Visibility(
                                  visible: visAdmin,
                                  child: IconButton(
                                      onPressed: () {
                                        _delete(_allEventResults[index]);
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.redAccent,),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 5,),
                      ]
                  ),
                )
            );
          }

        },
      );
    } return const Center(
      child: CircularProgressIndicator(),
    );
  }


  Future<void> _create([DocumentSnapshot? documentSnapshot]) async {

    _dateController.text = formattedDate;
    // _eventController.text = '';
    String formattedSelectedDay = DateFormat.yMMMEd().format(_focusedDay);

    final String date = _selectedDay.toString();
    final String eventDescription = _eventController.text;

    if (eventDescription != null) {
      await _eventCalendarList.add({
        "eventDes": eventDescription,
        "date": formattedSelectedDay,
      });

      _eventController.text = '';
      _dateController.text = '';

      // if(context.mounted)Navigator.of(context).pop();
    }
  }

  Future<void> _delete(String event) async {
    await _eventCalendarList.doc(event).delete();

    if(context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You have successfully deleted an event!')));
    }
  }

}

class Event{
  final String title;
  Event(this.title);
}
