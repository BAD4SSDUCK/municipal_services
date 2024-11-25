import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MunicipalEventsCalendar extends StatefulWidget {
  final String districtId;
  final bool isLocalUser;
  final bool isLocalMunicipality;
  const MunicipalEventsCalendar({
    super.key,
    required this.districtId,
    required this.isLocalUser, required this.isLocalMunicipality,
  });

  @override
  _MunicipalEventsCalendarState createState() =>
      _MunicipalEventsCalendarState();
}

class _MunicipalEventsCalendarState extends State<MunicipalEventsCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();
  String formattedDate = DateFormat.yMMMEd().format(DateTime.now());

  Map<DateTime, List<Event>> events = {};
  TextEditingController _eventController = TextEditingController();
  late final ValueNotifier<List<Event>> _selectedEvents;

  List<String> municipalities = [];
  String? selectedMunicipalityId;
  bool isLocalMunicipality=false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    if (widget.isLocalUser) {
      _fetchEvents(); // Local user, directly fetch events
    } else {
      _fetchMunicipalities(); // District-level user, fetch municipalities
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _fetchMunicipalities() async {
    try {
      var municipalitiesSnapshot = await FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .get();

      setState(() {
        municipalities = municipalitiesSnapshot.docs
            .map((doc) => doc.id) // Assuming municipality ID as identifier
            .toList();
      });
    } catch (e) {
      print('Error fetching municipalities: $e');
    }
  }

  // Future<void> _fetchEvents() async {
  //   if (selectedMunicipalityId == null && !widget.isLocalUser) return;
  //
  //   String municipalityId =
  //   widget.isLocalUser ? widget.districtId : selectedMunicipalityId!;
  //   CollectionReference calendarCollection = FirebaseFirestore.instance
  //       .collection('localMunicipalities')
  //       .doc(municipalityId)
  //       .collection('calendar');
  //
  //   var data = await calendarCollection.get();
  //
  //   setState(() {
  //     events.clear();
  //     for (var eventSnapshot in data.docs) {
  //       var eventDescription = eventSnapshot['eventDes'].toString();
  //       var dateStr = eventSnapshot['date'].toString();
  //
  //       if (dateStr.isNotEmpty) {
  //         try {
  //           DateTime date = DateFormat('yMMMEd').parse(dateStr);
  //           DateTime normalizedDate = DateTime(date.year, date.month, date.day);
  //           events[normalizedDate] = (events[normalizedDate] ?? [])
  //             ..add(Event(eventDescription, eventSnapshot.id));
  //         } catch (e) {
  //           print('Error parsing date: $e');
  //         }
  //       }
  //     }
  //     _selectedEvents.value = _getEventsForDay(_selectedDay!);
  //   });
  // }
  Future<void> _fetchEvents() async {
    if (selectedMunicipalityId == null && !widget.isLocalUser) return;

    String path;
    if (!widget.isLocalUser && !widget.isLocalMunicipality) {
      // District-level user
      path = 'districts/${widget.districtId}/municipalities/$selectedMunicipalityId/calendar';
    } else {
      // Local municipality user
      path = 'localMunicipalities/${widget.districtId}/calendar';
    }

    CollectionReference calendarCollection = FirebaseFirestore.instance.collection(path);

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

  // Future<void> _createEvent() async {
  //   if (_eventController.text.isEmpty || _selectedDay == null) return;
  //
  //   String formattedSelectedDay = DateFormat.yMMMEd().format(_selectedDay!);
  //   String municipalityId =
  //   widget.isLocalUser ? widget.districtId : selectedMunicipalityId!;
  //
  //   CollectionReference calendarCollection = FirebaseFirestore.instance
  //       .collection('localMunicipalities')
  //       .doc(municipalityId)
  //       .collection('calendar');
  //
  //   await calendarCollection.add({
  //     "eventDes": _eventController.text,
  //     "date": formattedSelectedDay,
  //   });
  //
  //   _eventController.clear();
  //   _fetchEvents(); // Refresh events
  // }
 Future<void> _createEvent() async {
    if (_eventController.text.isEmpty || _selectedDay == null) return;

    String formattedSelectedDay = DateFormat.yMMMEd().format(_selectedDay!);
    String path;

    if (!widget.isLocalUser && !widget.isLocalMunicipality) {
      // District-level user
      path = 'districts/${widget.districtId}/municipalities/$selectedMunicipalityId/calendar';
    } else {
      // Local municipality user
      path = 'localMunicipalities/${widget.districtId}/calendar';
    }

    CollectionReference calendarCollection = FirebaseFirestore.instance.collection(path);

    await calendarCollection.add({
      "eventDes": _eventController.text,
      "date": formattedSelectedDay,
    });

    _eventController.clear();
    _fetchEvents(); // Refresh events
  }
  // Future<void> _deleteEvent(String eventId) async {
  //   String municipalityId =
  //   widget.isLocalUser ? widget.districtId : selectedMunicipalityId!;
  //
  //   DocumentReference eventDoc = FirebaseFirestore.instance
  //       .collection('localMunicipalities')
  //       .doc(municipalityId)
  //       .collection('calendar')
  //       .doc(eventId);
  //
  //   await eventDoc.delete();
  //   _fetchEvents(); // Refresh events
  // }
  Future<void> _deleteEvent(String eventId) async {
    String path;

    if (!widget.isLocalUser && !widget.isLocalMunicipality) {
      // District-level user
      path = 'districts/${widget.districtId}/municipalities/$selectedMunicipalityId/calendar';
    } else {
      // Local municipality user
      path = 'localMunicipalities/${widget.districtId}/calendar';
    }

    DocumentReference eventDoc = FirebaseFirestore.instance.collection(path).doc(eventId);

    await eventDoc.delete();
    _fetchEvents(); // Refresh events
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
        floatingActionButton: FloatingActionButton(
          splashColor: Colors.grey,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.white,
                  scrollable: true,
                  title: const Text(
                    "Add New Event",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  content: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _eventController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter event description',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (_eventController.text.isNotEmpty) {
                          _createEvent();
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        "Add Event",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );

              },
            );
          },
        ),
        body: Column(
          children: [
            if (!widget.isLocalUser)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  hint: const Text("Select Municipality"),
                  value: selectedMunicipalityId,
                  items: municipalities
                      .map((municipalityId) => DropdownMenuItem(
                    value: municipalityId,
                    child: Text(municipalityId),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMunicipalityId = value;
                      _fetchEvents();
                    });
                  },
                ),
              ),
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
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteEvent(event!.id),
            ),
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
