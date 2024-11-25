import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';


class LogScreen extends StatefulWidget {
  final String userId;
  final String districtId;
  final String municipalityId;
  final String propertyAddress;
  final bool isLocalMunicipality;

  const LogScreen({
    super.key,
    required this.userId,
    required this.districtId,
    required this.municipalityId,
    required this.propertyAddress,
    required this.isLocalMunicipality,
  });

  @override
  _LogScreenState createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the appropriate Firestore path based on whether it's a local municipality
    String path;
    if (widget.isLocalMunicipality) {
      path = '/localMunicipalities/${widget.municipalityId}/actionLogs/${widget.userId}/${widget.propertyAddress}/';
    } else {
      path = '/districts/${widget.districtId}/municipalities/${widget.municipalityId}/actionLogs/${widget.userId}/${widget.propertyAddress}/';
    }

    // Debugging: print the path to verify it
    print("Path to logs: $path");

    // Check if any of the values are empty or null
    if ((widget.isLocalMunicipality && widget.municipalityId.isEmpty) ||
        (!widget.isLocalMunicipality && (widget.districtId.isEmpty || widget.municipalityId.isEmpty)) ||
        widget.userId.isEmpty ||
        widget.propertyAddress.isEmpty) {
      print("Error: One of the required values is empty: "
          "districtId: ${widget.districtId}, "
          "municipalityId: ${widget.municipalityId}, "
          "userId: ${widget.userId}, "
          "propertyAddress: ${widget.propertyAddress}");

      Stream<QuerySnapshot> logStream;
      if (widget.isLocalMunicipality) {
        logStream = FirebaseFirestore.instance
            .collection('localMunicipalities')
            .doc(widget.municipalityId)
            .collection('actionLogs')
            .doc(widget.userId)
            .collection(widget.propertyAddress)
            .orderBy('timestamp', descending: false)
            .snapshots();
      } else {
        logStream = FirebaseFirestore.instance
            .collection('districts')
            .doc(widget.districtId)
            .collection('municipalities')
            .doc(widget.municipalityId)
            .collection('actionLogs')
            .doc(widget.userId)
            .collection(widget.propertyAddress)
            .orderBy('timestamp', descending: false)
            .snapshots();
      }


      return Scaffold(
        backgroundColor: Colors.grey[350],
        appBar: AppBar(
          title: const Text('Update Logs', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.green,
        ),
        body: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              final double pageScrollAmount = _scrollController.position.viewportDimension;

              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                _scrollController.animateTo(
                  _scrollController.offset + 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                _scrollController.animateTo(
                  _scrollController.offset - 50,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
                _scrollController.animateTo(
                  _scrollController.offset + pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              } else if (event.logicalKey == LogicalKeyboardKey.pageUp) {
                _scrollController.animateTo(
                  _scrollController.offset - pageScrollAmount,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                );
              }
            }
          },
          child: StreamBuilder<QuerySnapshot>(
            stream: logStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                print('Error fetching logs: ${snapshot.error}');
                return Center(child: Text('Error fetching logs: ${snapshot.error}'));
              }
              if (snapshot.data?.docs.isEmpty ?? true) {
                print('No logs found for property address: ${widget.propertyAddress}');
                return const Center(child: Text('No logs found for this property.'));
              }

              return Scrollbar(
                controller: _scrollController,
                thickness: 10,
                radius: const Radius.circular(8),
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var log = snapshot.data!.docs[index];
                    print('Log description: ${log['description']}, timestamp: ${log['timestamp']}');

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text(log['description'] ?? 'No description'),
                        subtitle: Text(log['timestamp'].toDate().toString()),
                        leading: const Icon(Icons.update),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      );
    }


    // Use Firestore query to fetch logs based on local or district municipality
    Stream<QuerySnapshot> logStream;

    if (widget.isLocalMunicipality) {
      logStream = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(widget.userId)
          .collection(widget.propertyAddress)
          .orderBy('timestamp', descending: false)
          .snapshots();
    } else {
      logStream = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('actionLogs')
          .doc(widget.userId)
          .collection(widget.propertyAddress)
          .orderBy('timestamp', descending: false)
          .snapshots();
    }

    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Update Logs', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: logStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching logs: ${snapshot.error}');
            return Center(child: Text('Error fetching logs: ${snapshot.error}'));
          }
          if (snapshot.data?.docs.isEmpty ?? true) {
            print('No logs found for property address: ${widget.propertyAddress}');
            return const Center(child: Text('No logs found for this property.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var log = snapshot.data!.docs[index];
              print('Log description: ${log['description']}, timestamp: ${log['timestamp']}');

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(log['description'] ?? 'No description'),
                  subtitle: Text(log['timestamp'].toDate().toString()),
                  leading: const Icon(Icons.update),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
