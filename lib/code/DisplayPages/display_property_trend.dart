import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:municipal_services/code/DisplayPages/display_info.dart';
import 'package:municipal_services/code/Chat/chat_screen_finance.dart';
import 'package:municipal_services/code/Reusable/icon_elevated_button.dart';


class PropertyTrend extends StatefulWidget {
  const PropertyTrend({super.key, required this.addressTarget, required this.districtId, required this.municipalityId,required this.isLocalMunicipality,this.isLocalUser=false });
  final String districtId;
  final String municipalityId;
  final String addressTarget;
  final bool isLocalMunicipality;
  final bool isLocalUser;

  @override
  _PropertyTrendState createState() => _PropertyTrendState();
}

final FirebaseAuth auth = FirebaseAuth.instance;
final storageRef = FirebaseStorage.instance.ref();

DateTime now = DateTime.now();
int monthNum = 1;

final User? user = auth.currentUser;
final uid = user?.uid;
final phone = user?.phoneNumber;
final email = user?.email;
String userID = uid as String;

String locationGiven = ' ';

bool visibilityState1 = true;
bool visibilityState2 = false;
bool showElectricityGraph = true; // Default to electricity graph

final FirebaseStorage imageStorage = FirebaseStorage.instance;

String formattedMonth = DateFormat.MMMM().format(now);
String formattedDateMonth = DateFormat.MMMMd().format(now);

double currentMonth = 0;

List<String> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

List<double> waterReadings = [];
List<double> xAxisIteration = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
List<String> monthCaptured = [];
List<FlSpot> waterMeterSpots = [];
List<FlSpot> invalidWaterSpots = [];

class FireStorageService extends ChangeNotifier {
  FireStorageService();
  static Future<String> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }
}

class _PropertyTrendState extends State<PropertyTrend> {
  final user = FirebaseAuth.instance.currentUser!;
  late final CollectionReference _propList;
  late final CollectionReference _consumptionCollection;

  String formattedDate = DateFormat.MMMM().format(now);
  Timer? timer2;

  String dropdownValue = 'Select Month';
  List<String> dropdownMonths = [
    'Select Month',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  late String consumptionProp;
  bool isLoading = true;
  List<FlSpot> waterMeterSpots = [];
  @override
  void initState() {
    super.initState();
    if (widget.isLocalMunicipality) {
      _propList = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('properties');

      _consumptionCollection = FirebaseFirestore.instance
          .collection('localMunicipalities')
          .doc(widget.municipalityId)
          .collection('consumption');
    } else {
      _propList = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('properties');

      _consumptionCollection = FirebaseFirestore.instance
          .collection('districts')
          .doc(widget.districtId)
          .collection('municipalities')
          .doc(widget.municipalityId)
          .collection('consumption');
    }


    getWaterReadings();  // Fetch water readings on init
    Future.delayed(const Duration(seconds: 5), () {
      checkWaterLoad();
    });
  }


  @override
  void dispose() {
    waterReadings.clear();
    timer2?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[350],
      appBar: AppBar(
        title: const Text('Property Reading Trend', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
            child: Card(
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Captured Consumption Trend',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Center(
                    child: Container(
                      color: const Color(0xF9F2F7),
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator()) // Show progress indicator while loading
                          : (waterMeterSpots.isEmpty
                          ? const Center(child: Text("No water data available.")) // Show message if no data
                          : LineChartWaterMeter(
                        waterLineColor: Colors.blue,
                        waterMeterSpots: waterMeterSpots,
                        isLoading: isLoading,
                        currentMonth: currentMonth,
                        screenWidth: MediaQuery.of(context).size.width,
                        screenHeight: MediaQuery.of(context).size.height,
                      )),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: firebasePropertyCard(_propList),
          ),
        ],
      ),
    );
  }


  Widget firebasePropertyCard(CollectionReference<Object?> propertyDataStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: propertyDataStream.snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
        if (streamSnapshot.hasData) {
          return ListView.builder(
            itemCount: streamSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];

              if (streamSnapshot.data!.docs[index]['address'] == widget.addressTarget) {
                return Card(
                  margin: const EdgeInsets.only(
                      left: 10, right: 10, top: 0, bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Property Data',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Account Number: ${documentSnapshot['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Street Address: ${documentSnapshot['address']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Area Code: ${documentSnapshot['areaCode']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 20),
                        ]),
                  ),
                );
              } else {
                return const SizedBox(height: 0, width: 0);
              }
            },
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void checkWaterLoad() {
    if (mounted) {
      setState(() {
        isLoading = false;  // Data has been fetched, stop showing the loading indicator
      });
    }
  }

  Future<void> getWaterReadings() async {
    setState(() {
      isLoading = true; // Start loading data
    });

    waterReadings.clear();  // Clear previous data
    waterMeterSpots.clear(); // Clear previous spots
    invalidWaterSpots.clear(); // Clear invalid spots
    double lastValidReading = 0.0;

    try {
      for (int i = 0; i < months.length; i++) {
        var propertyData = await _consumptionCollection
            .doc(months[i])
            .collection('address')
            .where('address', isEqualTo: widget.addressTarget.trim())
            .get();

        if (propertyData.docs.isNotEmpty) {
          var firstDocData = propertyData.docs.first.data();
          var reading = double.parse(firstDocData['water_meter_reading'] ?? '0');

          if (reading > 1000) {
            reading = log(reading);
          }


          if (reading > 0) {
            lastValidReading = reading;
            waterMeterSpots.add(FlSpot(i.toDouble(), reading));
          } else {
            // If no valid reading, add to invalidWaterSpots
            invalidWaterSpots.add(FlSpot(i.toDouble(), lastValidReading));
          }

          waterReadings.add(lastValidReading);
        } else {
          // No data for the current month
          waterReadings.add(lastValidReading); // Use last valid reading
          invalidWaterSpots.add(FlSpot(i.toDouble(), lastValidReading));
        }
      }


      // Calculate the current month index (January = 0, February = 1, etc.)
      DateTime now = DateTime.now();
      int currentMonthIndex = now.month - 1; // Convert to zero-based index
      currentMonth = currentMonthIndex.toDouble(); // Set currentMonth for the vertical line

      prepareWaterReadings(); // Prepare graph data points

    } catch (e) {
      debugPrint("Error fetching water readings: $e");
      if (waterReadings.isNotEmpty) {
        waterReadings.add(waterReadings.last);
      } else {
        waterReadings.add(0.0); // Default value if no data at all
      }
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }


  void prepareWaterReadings() {
    waterMeterSpots.clear();  // Clear previous spots
    for (int i = 0; i < waterReadings.length; i++) {
      double reading = waterReadings[i];
      waterMeterSpots.add(FlSpot(i.toDouble(), reading));
    }
    debugPrint('Water Meter Spots: $waterMeterSpots');  // Debug print spots for checking
    setState(() {});
  }


  Future<void> getCollectionData() async {
    for (int i = 0; i < months.length; i++) {
      try {
        var propertyData = await _consumptionCollection
            .doc(months[i])
            .collection('address')
            .where('address', isEqualTo: widget.addressTarget.trim())
            .get();

        if (propertyData.docs.isNotEmpty) {
          var firstDocData = propertyData.docs[0].data();
          String waterMeterReadingStr = firstDocData['water_meter_reading'] ?? '0';
          double waterMeterReading = waterMeterReadingStr.isNotEmpty ? double.parse(waterMeterReadingStr) : 0.0;
          monthCaptured.add(months[i]);
          waterReadings.add(waterMeterReading);
        } else {
          throw Exception("No data found for ${months[i]}");
        }
      } catch (e) {
        monthCaptured.add(months[i]);
        if (waterReadings.isNotEmpty) {
          waterReadings.add(waterReadings.last);
        } else {
          waterReadings.add(0.0);
        }
      }
    }

    for (int i = 0; i < months.length; i++) {
      if (months[i] == formattedMonth) {
        currentMonth = i.toDouble();
      }
    }

    xAxisIteration = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
  }
}

class LineChartWaterMeter extends StatefulWidget {
  final Color waterLineColor;
  final List<FlSpot> waterMeterSpots;
  final bool isLoading;
  final double currentMonth;
  final double screenWidth;
  final double screenHeight;

  const LineChartWaterMeter({
    super.key,
    this.waterLineColor = Colors.blue,
    required this.waterMeterSpots,
    required this.isLoading,
    required this.currentMonth,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  _LineChartWaterMeterState createState() => _LineChartWaterMeterState();
}

class _LineChartWaterMeterState extends State<LineChartWaterMeter> {
  bool isLocalLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasValidData = widget.waterMeterSpots.isNotEmpty || invalidWaterSpots.isNotEmpty;
    if (isLocalLoading || widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (!hasValidData) {
      return const Center(child: Text("No water data available."));
    }

    double maxY = hasValidData
        ? widget.waterMeterSpots.map((spot) => spot.y).reduce(max) * 1.2
        : 10;
    maxY = maxY < 10 ? 10 : maxY;
    double minY = 0.0;
    return AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          color: Colors.white,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              lineTouchData: const LineTouchData(enabled: true),
              extraLinesData: ExtraLinesData(
                verticalLines: <VerticalLine>[
                  VerticalLine(
                      x: widget.currentMonth,
                      color: Colors.greenAccent,
                      dashArray: [4, 4]),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: widget.waterMeterSpots,
                  isCurved: false,
                  barWidth: 4,
                  color: widget.waterLineColor, // Blue Line for valid data
                  belowBarData: BarAreaData(
                      show: false, color: Colors.blue.withOpacity(0.3)),
                  aboveBarData: BarAreaData(
                      show: false, color: Colors.blue.withOpacity(0.1)),
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: invalidWaterSpots,  // Red Line for missing data
                  isCurved: false,
                  barWidth: 4,
                  color: Colors.red,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                  aboveBarData: BarAreaData(show: false),
                ),
              ],
              titlesData: buildTitlesData(maxY),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: true),
            ),
          )
        ));
  }

  FlTitlesData buildTitlesData(double maxY) => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      ),
    ),
    leftTitles: AxisTitles(
      axisNameSize: 20,
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(
            bottom: 1), // Adjust the padding value as needed
        child: Text(
          'kilo Liters Readings',
          style: TextStyle(
            color: AppColors.contentColorBlack,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 50,
        interval: 5,
        getTitlesWidget: leftTitleWidgets,
      ),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    String text = months[value.toInt() % months.length];

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text,
          style: const TextStyle(
              fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    String label = '${(value).toStringAsFixed(0)} kL';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10.0,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}




// //
// //
// // class PropertyTrend extends StatefulWidget {
// //   PropertyTrend({Key? key, required this.addressTarget}) : super(key: key);
// //
// //   final String addressTarget;
// //
// //   @override
// //   _PropertyTrendState createState() => _PropertyTrendState();
// // }
// //
// // final FirebaseAuth auth = FirebaseAuth.instance;
// // final storageRef = FirebaseStorage.instance.ref();
// //
// // DateTime now = DateTime.now();
// // int monthNum = 1;
// //
// // final User? user = auth.currentUser;
// // final uid = user?.uid;
// // final phone = user?.phoneNumber;
// // final email = user?.email;
// // String userID = uid as String;
// //
// // String locationGiven = ' ';
// //
// // bool visibilityState1 = true;
// // bool visibilityState2 = false;
// //
// // final FirebaseStorage imageStorage = firebase_storage.FirebaseStorage.instance;
// //
// // String formattedMonth = DateFormat.MMMM().format(now);//format for full Month by name
// // String formattedDateMonth = DateFormat.MMMMd().format(now);//format for Day Month only
// //
// // double currentMonth = 0;
// //
// // List<String> months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
// // List<double> electricityReadings =[];
// // List<double> waterReadings =[];
// // List<double> xAxisIteration =[0,1,2,3,4,5,6,7,8,9,10,11];
// // List<String> monthCaptured =[];
// // List<FlSpot> eMeterSpots = [];
// // List<FlSpot> invalidSpots = [];
// //
// // class FireStorageService extends ChangeNotifier{
// //   FireStorageService();
// //   static Future<String> loadImage(BuildContext context, String image) async{
// //     return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
// //   }
// // }
// //
// // class _PropertyTrendState extends State<PropertyTrend> {
// //
// //   final user = FirebaseAuth.instance.currentUser!;
// //
// //   final CollectionReference _propList =
// //   FirebaseFirestore.instance.collection('properties');
// //
// //   String formattedDate = DateFormat.MMMM().format(now);
// //   Timer? timer;
// //
// //   String dropdownValue = 'Select Month';
// //   List<String> dropdownMonths = ['Select Month','January','February','March','April','May','June','July','August','September','October','November','December'];
// //
// //   late String consumptionProp;
// //
// //   late bool _isLoading = true;
// //
// //   @override
// //   void initState() {
// //     Fluttertoast.showToast(msg: "Press and hold line to see the values!", gravity: ToastGravity.CENTER, toastLength: Toast.LENGTH_LONG);
// //     // setMonthLimits(formattedDate);
// //     getCollectionData();
// //     // timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => build(context));
// //
// //     timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => checkDataLoad());
// //
// //     Future.delayed(const Duration(seconds: 10),(){
// //       // setState(() {
// //       //   if(electricityReadings.length == 12){
// //       //     _isLoading = false;
// //       //   } else {
// //       //     _isLoading = true;
// //       //   }
// //       // });
// //       Fluttertoast.showToast(msg: "Press and hold line to see the values!", gravity: ToastGravity.CENTER, toastLength: Toast.LENGTH_LONG);
// //       // Fluttertoast.showToast(msg: "Reading values rounded!",gravity: ToastGravity.CENTER);
// //     });
// //     super.initState();
// //   }
// //
// //   @override
// //   void dispose() {
// //     // getCollectionData();
// //     electricityReadings = [];
// //     waterReadings = [];
// //     monthCaptured = [];
// //     months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
// //     eMeterSpots = [];
// //     // LineChartSample();
// //     timer?.cancel();
// //     super.dispose();
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.grey[350],
// //       appBar: AppBar(
// //         title: const Text('Property Reading Trend',style: TextStyle(color: Colors.white),),
// //         backgroundColor: Colors.green,
// //         iconTheme: const IconThemeData(color: Colors.white),
// //       ),
// //       body:
// //       Column(
// //         children: [
// //           const SizedBox(height: 10,),
// //
// //           ///month selector disabled
// //           // Padding(
// //           //   padding: const EdgeInsets.symmetric(vertical: 0.0,horizontal: 15.0),
// //           //   child: Column(
// //           //       children: [
// //           //         SizedBox(
// //           //           width: 400,
// //           //           height: 50,
// //           //           child: Padding(
// //           //             padding: const EdgeInsets.only(left: 10, right: 10),
// //           //             child: Center(
// //           //               child: TextField(
// //           //                 ///Input decoration here had to be manual because dropdown button uses suffix icon of the textfield
// //           //                 decoration: InputDecoration(
// //           //                   border: OutlineInputBorder(
// //           //                       borderRadius: BorderRadius.circular(
// //           //                           30),
// //           //                       borderSide: const BorderSide(
// //           //                         color: Colors.grey,
// //           //                       )
// //           //                   ),
// //           //                   enabledBorder: OutlineInputBorder(
// //           //                       borderRadius: BorderRadius.circular(
// //           //                           30),
// //           //                       borderSide: const BorderSide(
// //           //                         color: Colors.grey,
// //           //                       )
// //           //                   ),
// //           //                   focusedBorder: OutlineInputBorder(
// //           //                       borderRadius: BorderRadius.circular(
// //           //                           30),
// //           //                       borderSide: const BorderSide(
// //           //                         color: Colors.grey,
// //           //                       )
// //           //                   ),
// //           //                   disabledBorder: OutlineInputBorder(
// //           //                       borderRadius: BorderRadius.circular(
// //           //                           30),
// //           //                       borderSide: const BorderSide(
// //           //                         color: Colors.grey,
// //           //                       )
// //           //                   ),
// //           //                   contentPadding: const EdgeInsets.symmetric(
// //           //                       horizontal: 14,
// //           //                       vertical: 6
// //           //                   ),
// //           //                   fillColor: Colors.white,
// //           //                   filled: true,
// //           //                   suffixIcon: DropdownButtonFormField <String>(
// //           //                     value: dropdownValue,
// //           //                     items: dropdownMonths
// //           //                         .map<DropdownMenuItem<String>>((String value) {
// //           //                       return DropdownMenuItem<String>(
// //           //                         value: value,
// //           //                         child: Padding(
// //           //                           padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
// //           //                           child: Text(
// //           //                             value,
// //           //                             style: const TextStyle(fontSize: 16),
// //           //                           ),
// //           //                         ),
// //           //                       );
// //           //                     }).toList(),
// //           //                     onChanged: (String? newValue) {
// //           //                       setState(() {
// //           //                         dropdownValue = newValue!;
// //           //                       });
// //           //                     },
// //           //                     icon: const Padding(
// //           //                       padding: EdgeInsets.only(left: 10, right: 10),
// //           //                       child: Icon(Icons.arrow_circle_down_sharp),
// //           //                     ),
// //           //                     iconEnabledColor: Colors.green,
// //           //                     style: const TextStyle(
// //           //                         color: Colors.black,
// //           //                         fontSize: 18
// //           //                     ),
// //           //                     dropdownColor: Colors.grey[50],
// //           //                     isExpanded: true,
// //           //
// //           //                   ),
// //           //                 ),
// //           //               ),
// //           //             ),
// //           //           ),
// //           //         ),
// //           //       ]
// //           //   ),
// //           // ),
// //
// //           const Padding(
// //             padding: EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
// //             child: Card(
// //                 child: Column(
// //                   children: [
// //                     SizedBox(height: 10,),
// //                     Center(
// //                       child: Text(
// //                         'Captured Consumption Trend',
// //                         style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
// //                       ),
// //                     ),
// //                     SizedBox(height: 10,),
// //                   ],
// //                 ),
// //             ),
// //           ),
// //
// //           // const SizedBox(height: 5,),
// //
// //           Expanded(
// //             child: Stack(
// //               children: [_isLoading
// //                   ? const Center(child: CircularProgressIndicator(),)
// //                   : Padding(
// //                 padding: const EdgeInsets.all(8.0),
// //                 child: Card(
// //                   child: Padding(
// //                     padding: const EdgeInsets.all(4.0),
// //                     child: Center(
// //                       child: Container(
// //                         color: Color(0xF9F2F7),
// //                         child:
// //                         LineChartEMeter(),
// //                         // _LineChart(),
// //                       )
// //                     ),
// //                   ),
// //                 ),
// //               )]
// //             ),
// //           ),
// //
// //           firebasePropertyCard(_propList),
// //
// //           // propertyConsumptionCard(),
// //
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget firebasePropertyCard(CollectionReference<Object?> propertyDataStream){
// //     return Expanded(
// //       child: StreamBuilder<QuerySnapshot>(
// //         stream: propertyDataStream.snapshots(),
// //         builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
// //           if (streamSnapshot.hasData) {
// //             return ListView.builder(
// //               ///this call is to display all details for all users but is only displaying for the current user account.
// //               ///it can be changed to display all users for the staff to see if the role is set to all later on.
// //               itemCount: streamSnapshot.data!.docs.length,
// //               itemBuilder: (context, index) {
// //                 final DocumentSnapshot documentSnapshot =
// //                 streamSnapshot.data!.docs[index];
// //
// //                 ///Check for only user information, this displays only for the users details and not all users in the database.
// //                 if(streamSnapshot.data!.docs[index]['address'] == widget.addressTarget) {
// //                   return Card(
// //                     margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
// //                     child: Padding(
// //                       padding: const EdgeInsets.all(20.0),
// //                       child: Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           crossAxisAlignment: CrossAxisAlignment.start,
// //                           children: [
// //                             const Center(
// //                               child: Text(
// //                                 'Property Data',
// //                                 style: TextStyle(
// //                                     fontSize: 16, fontWeight: FontWeight.w700),
// //                               ),
// //                             ),
// //                             const SizedBox(height: 10,),
// //                             Text(
// //                               'Account Number: ${documentSnapshot['account number']}',
// //                               style: const TextStyle(
// //                                   fontSize: 16, fontWeight: FontWeight.w400),
// //                             ),
// //                             const SizedBox(height: 5,),
// //                             Text(
// //                               'Street Address: ${documentSnapshot['address']}',
// //                               style: const TextStyle(
// //                                   fontSize: 16, fontWeight: FontWeight.w400),
// //                             ),
// //                             const SizedBox(height: 5,),
// //                             Text(
// //                               'Area Code: ${documentSnapshot['area code']}',
// //                               style: const TextStyle(
// //                                   fontSize: 16, fontWeight: FontWeight.w400),
// //                             ),
// //                             const SizedBox(height: 20,),
// //
// //                           ]
// //                       ),
// //                     ),
// //                   );
// //                 }///end of single user information display.
// //                 else {
// //                   return const SizedBox(height: 0, width: 0,);
// //                 }
// //               },
// //             );
// //           }
// //           return const Center(
// //             child: CircularProgressIndicator(),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   ///To add the card
// //   Widget propertyConsumptionCard(){
// //
// //     return Expanded(
// //       child: FutureBuilder<QuerySnapshot>(
// //         future: FirebaseFirestore.instance
// //             .collection('consumption')
// //             .doc(formattedMonth)
// //             .collection('address').get(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.done) {
// //             if (snapshot.data!.docs.isEmpty) {
// //               return const Card(
// //                 margin: EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
// //                 child: Padding(
// //                   padding: EdgeInsets.all(20.0),
// //                   child: Text(
// //                     'Readings not taken for this month',
// //                     style: TextStyle(
// //                         fontSize: 16, fontWeight: FontWeight.w700),
// //                   ),
// //                 ),
// //               );
// //             } else if (snapshot.hasData) {
// //               return Card(
// //                 margin: const EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 10),
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(20.0),
// //                   child: Column(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         Center(
// //                           child: Text(
// //                             'Property Readings for ${snapshot.data?.docs[monthNum][formattedMonth]}',
// //                             style: const TextStyle(
// //                                 fontSize: 16, fontWeight: FontWeight.w700),
// //                           ),
// //                         ),
// //                         const SizedBox(height: 10,),
// //                         Text(
// //                           'Address: ${snapshot.data?.docs[monthNum]['address']}',
// //                           style: const TextStyle(
// //                               fontSize: 16, fontWeight: FontWeight.w400),
// //                         ),
// //                         const SizedBox(height: 5,),
// //                         Text(
// //                           'Electricity Meter Reading Address: ${snapshot.data?.docs[monthNum]['address']}',
// //                           style: const TextStyle(
// //                               fontSize: 16, fontWeight: FontWeight.w400),
// //                         ),
// //                         const SizedBox(height: 5,),
// //                         Text(
// //                           'Area Code: ${snapshot.data?.docs[monthNum]['area code']}',
// //                           style: const TextStyle(
// //                               fontSize: 16, fontWeight: FontWeight.w400),
// //                         ),
// //                         const SizedBox(height: 20,),
// //
// //                       ]
// //                   ),
// //                 ),
// //
// //               );
// //             }
// //           }
// //           return const SizedBox(
// //             child: Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           );
// //         },
// //       ),
// //     );
// //   }
// //
// //   void checkDataLoad() async {
// //     if(context.mounted) {
// //       setState(() {
// //       if(electricityReadings.length == 12){
// //         _isLoading = false;
// //       } else {
// //         _isLoading = true;
// //       }
// //     });
// //     }
// //   }
// //
// //   Future getCollectionData() async {
// //
// //     for (int i=0; i<months.length; i++) {
// //
// //       try{
// //         var propertyData = await FirebaseFirestore.instance
// //             .collection('consumption')
// //             .doc(months[i])
// //             .collection('address')
// //             .where('address', isEqualTo: widget.addressTarget)
// //             .get();
// //
// //         String meterReading = propertyData.docs[0].data()['meter reading'];
// //         String waterMeterReading = propertyData.docs[0].data()['water meter reading'];
// //
// //         monthCaptured.add(months[i]);
// //         electricityReadings.add(double.parse(meterReading));
// //         waterReadings.add(double.parse(waterMeterReading));
// //
// //       } catch(e){
// //         print(e);
// //         monthCaptured.add(months[i]);
// //         print('test::: ${months[i]}');
// //         electricityReadings.add(electricityReadings[i-1]);
// //         waterReadings.add(waterReadings[i-1]);
// //       }
// //       print(monthCaptured);
// //       print(electricityReadings);
// //       print(waterReadings);
// //
// //     }
// //
// //     for (int i = 0; i < months.length; i++) {
// //       if(months[i] == formattedMonth){
// //         currentMonth = i.toDouble();
// //       }
// //     }
// //
// //     xAxisIteration =[0,1,2,3,4,5,6,7,8,9,10,11,];
// //
// //     eMeterSpots = [for (int i = 0; i < months.length; i++)
// //       FlSpot(xAxisIteration[i], double.parse(((electricityReadings[i] / 100000) * 10).toStringAsFixed(4)))];
// //       // FlSpot(xAxisIteration[i], electricityReadings[i])];
// //
// //     invalidSpots = [for (int i = 1+currentMonth.toInt(); i < months.length; i++)
// //       FlSpot(xAxisIteration[i], double.parse(((electricityReadings[i] / 100000) * 10).toStringAsFixed(4)))];
// //
// //     // print('the chart spots are::: $eMeterSpots');
// //
// //   }
// //
// //
// //   void setMonthLimits(String currentMonth) {
// //     String month1 = 'January';
// //     String month2 = 'February';
// //     String month3 = 'March';
// //     String month4 = 'April';
// //     String month5 = 'May';
// //     String month6 = 'June';
// //     String month7 = 'July';
// //     String month8 = 'August';
// //     String month9 = 'September';
// //     String month10 = 'October';
// //     String month11 = 'November';
// //     String month12 = 'December';
// //
// //
// //     switch(formattedMonth){
// //       case 'January': monthNum = 1; break;
// //       case 'February': monthNum = 2; break;
// //       case 'March': monthNum = 3; break;
// //       case 'April': monthNum = 4; break;
// //       case 'May': monthNum = 5; break;
// //       case 'June': monthNum = 6; break;
// //       case 'July': monthNum = 7; break;
// //       case 'August': monthNum = 8; break;
// //       case 'September': monthNum = 9; break;
// //       case 'October': monthNum = 10; break;
// //       case 'November': monthNum = 11; break;
// //       case 'December': monthNum = 12; break;
// //     }
// //
// //     print('current month numbered is:::: $monthNum');
// //
// //     if (currentMonth.contains(month1)) {
// //       dropdownMonths = ['Select Month', month10,month11,month12,currentMonth,];
// //     } else if (currentMonth.contains(month2)) {
// //       dropdownMonths = ['Select Month', month11,month12,month1,currentMonth,];
// //     } else if (currentMonth.contains(month3)) {
// //       dropdownMonths = ['Select Month', month12,month1,month2,currentMonth,];
// //     } else if (currentMonth.contains(month4)) {
// //       dropdownMonths = ['Select Month', month1,month2,month3,currentMonth,];
// //     } else if (currentMonth.contains(month5)) {
// //       dropdownMonths = ['Select Month', month2,month3,month4,currentMonth,];
// //     } else if (currentMonth.contains(month6)) {
// //       dropdownMonths = ['Select Month', month3,month4,month5,currentMonth,];
// //     } else if (currentMonth.contains(month7)) {
// //       dropdownMonths = ['Select Month', month4,month5,month6,currentMonth,];
// //     } else if (currentMonth.contains(month8)) {
// //       dropdownMonths = ['Select Month', month5,month6,month7,currentMonth,];
// //     } else if (currentMonth.contains(month9)) {
// //       dropdownMonths = ['Select Month', month6,month7,month8,currentMonth,];
// //     } else if (currentMonth.contains(month10)) {
// //       dropdownMonths = ['Select Month', month7,month8,month9,currentMonth,];
// //     } else if (currentMonth.contains(month11)) {
// //       dropdownMonths = ['Select Month', month8,month9,month10,currentMonth,];
// //     } else if (currentMonth.contains(month12)) {
// //       dropdownMonths = ['Select Month', month9,month10,month11,currentMonth,];
// //     } else {
// //       dropdownMonths = [
// //         'Select Month',
// //         'January',
// //         'February',
// //         'March',
// //         'April',
// //         'May',
// //         'June',
// //         'July',
// //         'August',
// //         'September',
// //         'October',
// //         'November',
// //         'December'
// //       ];
// //     }
// //   }
// //
// // }
// //
// //
// // class LineChartEMeter extends StatelessWidget {
// //   LineChartEMeter({
// //     super.key,
// //     Color? mainLineColor,
// //     Color? belowLineColor,
// //     Color? aboveLineColor,
// //   })  : mainLineColor = mainLineColor ?? AppColors.contentColorYellow.withOpacity(1),
// //         belowLineColor = belowLineColor ?? AppColors.gridLinesColor.withOpacity(0.5),
// //         aboveLineColor = aboveLineColor ?? AppColors.mainTextColor3.withOpacity(0.5);
// //
// //   final Color mainLineColor;
// //   final Color belowLineColor;
// //   final Color aboveLineColor;
// //   static const cutOffYValue = 10.0;
// //
// //   Widget bottomTitleWidgets(double value, TitleMeta meta) {
// //     String text;
// //     switch (value.toInt()) {
// //       case 0:text = 'Jan'; break;
// //       case 1:text = 'Feb'; break;
// //       case 2:text = 'Mar'; break;
// //       case 3:text = 'Apr'; break;
// //       case 4:text = 'May'; break;
// //       case 5:text = 'Jun'; break;
// //       case 6:text = 'Jul'; break;
// //       case 7:text = 'Aug'; break;
// //       case 8:text = 'Sep'; break;
// //       case 9:text = 'Oct'; break;
// //       case 10:text = 'Nov'; break;
// //       case 11:text = 'Dec'; break;
// //       default: return Container();
// //     }
// //
// //     return SideTitleWidget(
// //       axisSide: meta.axisSide,
// //       space: 4,
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           fontSize: 10,
// //           color: mainLineColor,
// //           fontWeight: FontWeight.bold,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget leftTitleWidgets(double value, TitleMeta meta) {
// //     const style = TextStyle(
// //       color: AppColors.contentColorBlack,
// //       fontWeight: FontWeight.w600,
// //       fontSize: 7,
// //     );
// //     return SideTitleWidget(
// //       axisSide: meta.axisSide,
// //       child: Text('${(value * 100000).toStringAsFixed(0)}', style: style),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     const cutOffYValue = 10.0;
// //
// //     double startValue = double.parse(((electricityReadings[0] / 100000) * 10).toStringAsFixed(4)) - 2;
// //     double endValue = double.parse(((electricityReadings[11] / 100000) * 10).toStringAsFixed(4)) + 2;
// //
// //     // print(currentMonth);
// //
// //     return AspectRatio(
// //       aspectRatio: 1.15,
// //       child: Padding(
// //         padding: const EdgeInsets.only(
// //           left: 12,
// //           right: 28,
// //           top: 22,
// //           bottom: 12,
// //         ),
// //         child: LineChart(
// //           LineChartData(
// //             lineTouchData: const LineTouchData(enabled: true),
// //
// //             extraLinesData: ExtraLinesData(
// //               verticalLines: <VerticalLine>[
// //                 VerticalLine(x: currentMonth, color: Colors.greenAccent, dashArray: [4,4]),
// //               ],
// //             ),
// //
// //             lineBarsData: [
// //               LineChartBarData(
// //                 spots: eMeterSpots,
// //
// //                 // const [
// //                 //   FlSpot(0, 4),
// //                 //   FlSpot(1, 3.5),
// //                 //   FlSpot(2, 4.5),
// //                 //   FlSpot(3, 1),
// //                 //   FlSpot(4, 4),
// //                 //   FlSpot(5, 6),
// //                 //   FlSpot(6, 6.5),
// //                 //   FlSpot(7, 6),
// //                 //   FlSpot(8, 4),
// //                 //   FlSpot(9, 6),
// //                 //   FlSpot(10, 6),
// //                 //   FlSpot(11, 7),
// //                 // ],
// //                 isCurved: false,
// //                 barWidth: 4,
// //                 color: mainLineColor,
// //                 belowBarData: BarAreaData(
// //                   show: true,
// //                   color: belowLineColor,
// //                   cutOffY: 0,
// //                   applyCutOffY: true,
// //                 ),
// //                 aboveBarData: BarAreaData(
// //                   show: true,
// //                   color: aboveLineColor,
// //                   cutOffY: endValue,
// //                   applyCutOffY: true,
// //                 ),
// //                 dotData: const FlDotData(
// //                   show: true ,
// //                 ),
// //               ),
// //
// //               LineChartBarData(
// //                 spots: [
// //                   FlSpot(0, startValue),
// //                   // FlSpot(1, 0),
// //                   // FlSpot(2, 0),
// //                   // FlSpot(3, 0),
// //                   // FlSpot(4, 0),
// //                   // FlSpot(5, 0),
// //                   // FlSpot(6, 0),
// //                   // FlSpot(7, 0),
// //                   // FlSpot(8, 0),
// //                   // FlSpot(9, 0),
// //                   // FlSpot(10, 0),
// //                   FlSpot(11, endValue),
// //                 ],
// //                 color: Colors.transparent,
// //               ),
// //
// //               LineChartBarData(
// //                 spots: invalidSpots,
// //                 color: Colors.redAccent,
// //                 barWidth: 4,
// //               ),
// //
// //             ],
// //             minY: 0,
// //
// //             titlesData: FlTitlesData(
// //               show: true,
// //               topTitles: const AxisTitles(
// //                 sideTitles: SideTitles(showTitles: false),
// //               ),
// //               rightTitles: const AxisTitles(
// //                 sideTitles: SideTitles(showTitles: false),
// //               ),
// //               bottomTitles: AxisTitles(
// //                 // axisNameWidget: Text(
// //                 //   '2019',
// //                 //   style: TextStyle(
// //                 //     fontSize: 10,
// //                 //     color: mainLineColor,
// //                 //     fontWeight: FontWeight.bold,
// //                 //   ),
// //                 // ),
// //                 sideTitles: SideTitles(
// //                   showTitles: true,
// //                   reservedSize: 18,
// //                   interval: 1,
// //                   getTitlesWidget: bottomTitleWidgets,
// //                 ),
// //               ),
// //               leftTitles: AxisTitles(
// //                 axisNameSize: 20,
// //                 axisNameWidget: const Text(
// //                   'kWh Readings',
// //                   style: TextStyle(
// //                     color: AppColors.contentColorBlack, fontWeight: FontWeight.w800
// //                   ),
// //                 ),
// //                 sideTitles: SideTitles(
// //                   showTitles: true,
// //                   interval: 1,
// //                   reservedSize: 40,
// //                   getTitlesWidget: leftTitleWidgets,
// //                 ),
// //               ),
// //             ),
// //             borderData: FlBorderData(
// //               show: true,
// //               border: Border.all(
// //                 color: AppColors.itemsBackground,
// //               ),
// //             ),
// //             gridData: FlGridData(
// //               show: true,
// //               drawVerticalLine: false,
// //               horizontalInterval: 1,
// //               checkToShowHorizontalLine: (double value) {
// //                 return value == 1 || value == 3 || value == 5 || value == 7;
// //               },
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
// import 'dart:async';
// import 'dart:math';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:intl/intl.dart';
//
// class PropertyTrend extends StatefulWidget {
//   const PropertyTrend({super.key, required this.addressTarget, required this.districtId, required this.municipalityId});
//   final String districtId;
//   final String municipalityId;
//   final String addressTarget;
//
//   @override
//   _PropertyTrendState createState() => _PropertyTrendState();
// }
//
// final FirebaseAuth auth = FirebaseAuth.instance;
// final storageRef = FirebaseStorage.instance.ref();
//
// DateTime now = DateTime.now();
// int monthNum = 1;
//
// final User? user = auth.currentUser;
// final uid = user?.uid;
// final phone = user?.phoneNumber;
// final email = user?.email;
// String userID = uid as String;
//
// String locationGiven = ' ';
//
// bool visibilityState1 = true;
// bool visibilityState2 = false;
// bool showElectricityGraph = true; // Default to electricity graph
//
// final FirebaseStorage imageStorage = FirebaseStorage.instance;
//
// String formattedMonth = DateFormat.MMMM().format(now);
// String formattedDateMonth = DateFormat.MMMMd().format(now);
//
// double currentMonth = 0;
//
// List<String> months = [
//   'January',
//   'February',
//   'March',
//   'April',
//   'May',
//   'June',
//   'July',
//   'August',
//   'September',
//   'October',
//   'November',
//   'December'
// ];
// // List<double> electricityReadings = [];
// List<double> waterReadings = [];
// List<double> xAxisIteration = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
// List<String> monthCaptured = [];
// // List<FlSpot> eMeterSpots = [];
// List<FlSpot> waterMeterSpots = [];
// // List<FlSpot> invalidSpots = [];
// List<FlSpot> invalidWaterSpots = [];
//
// class FireStorageService extends ChangeNotifier {
//   FireStorageService();
//   static Future<String> loadImage(BuildContext context, String image) async {
//     return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
//   }
// }
//
// class _PropertyTrendState extends State<PropertyTrend> {
//   final user = FirebaseAuth.instance.currentUser!;
//   // final CollectionReference _propList =
//   //     FirebaseFirestore.instance.collection('properties');
//   late final CollectionReference _propList;
//   late final CollectionReference _consumptionCollection;
//
//   String formattedDate = DateFormat.MMMM().format(now);
//   Timer? timer;
//   Timer? timer2;
//
//   String dropdownValue = 'Select Month';
//   List<String> dropdownMonths = [
//     'Select Month',
//     'January',
//     'February',
//     'March',
//     'April',
//     'May',
//     'June',
//     'July',
//     'August',
//     'September',
//     'October',
//     'November',
//     'December'
//   ];
//
//   late String consumptionProp;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _propList = FirebaseFirestore.instance
//         .collection('districts')
//         .doc(widget.districtId)
//         .collection('municipalities')
//         .doc(widget.municipalityId)
//         .collection('properties');
//
//     _consumptionCollection = FirebaseFirestore.instance
//         .collection('districts')
//         .doc(widget.districtId)
//         .collection('municipalities')
//         .doc(widget.municipalityId)
//         .collection('consumption');
//
//     Fluttertoast.showToast(
//         msg: "Press and hold line to see the values!",
//         gravity: ToastGravity.CENTER,
//         toastLength: Toast.LENGTH_LONG);
//     getCollectionData();
//     getWaterReadings();
//     // timer = Timer.periodic(
//     //     const Duration(seconds: 5), (Timer t) => checkDataLoad());
//     timer2 = Timer.periodic(
//         const Duration(seconds: 5), (Timer t) => checkWaterLoad());
//     Future.delayed(const Duration(seconds: 10), () {
//       Fluttertoast.showToast(
//           msg: "Press and hold line to see the values!",
//           gravity: ToastGravity.CENTER,
//           toastLength: Toast.LENGTH_LONG);
//     });
//     printAllAddressesInFirestore();
//   }
//
//   @override
//   void dispose() {
//     // electricityReadings = [];
//     waterReadings = [];
//     monthCaptured = [];
//     months = [
//       'January',
//       'February',
//       'March',
//       'April',
//       'May',
//       'June',
//       'July',
//       'August',
//       'September',
//       'October',
//       'November',
//       'December'
//     ];
//     // eMeterSpots = [];
//     waterMeterSpots = [];
//     timer?.cancel();
//     timer2?.cancel();
//     super.dispose();
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   var screenWidth = MediaQuery.of(context).size.width; // Get screen width
//   //   var screenHeight = MediaQuery.of(context).size.height; // Get screen height
//   //
//   //   return Scaffold(
//   //     backgroundColor: Colors.grey[350],
//   //     appBar: AppBar(
//   //       title: const Text('Property Reading Trend',
//   //           style: TextStyle(color: Colors.white)),
//   //       backgroundColor: Colors.green,
//   //       iconTheme: const IconThemeData(color: Colors.white),
//   //     ),
//   //     body: Column(
//   //       children: [
//   //         const SizedBox(height: 10),
//   //         const Padding(
//   //           padding: EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
//   //           child: Card(
//   //             child: Column(
//   //               children: [
//   //                 SizedBox(height: 10),
//   //                 Center(
//   //                   child: Text(
//   //                     'Captured Consumption Trend',
//   //                     style:
//   //                         TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
//   //                   ),
//   //                 ),
//   //                 SizedBox(height: 10),
//   //               ],
//   //             ),
//   //           ),
//   //         ),
//   //         // Row(
//   //         //   mainAxisAlignment: MainAxisAlignment.center,
//   //         //   children: [
//   //             // ElevatedButton(
//   //             //   onPressed: () {
//   //             //     setState(() {
//   //             //       showElectricityGraph = true;
//   //             //     });
//   //             //   },
//   //             // //   child:  Text('Electricity',
//   //             // //       style: TextStyle(color: Colors.yellow[800])),
//   //             // // ),
//   //             // // const SizedBox(width: 10),
//   //             // // ElevatedButton(
//   //             // //   onPressed: () {
//   //             // //     setState(() {
//   //             // //       showElectricityGraph = false;
//   //             // //       getWaterReadings();
//   //             // //     });
//   //             // //   },
//   //             //   child:
//   //             //       const Text('Water', style: TextStyle(color: Colors.blue)),
//   //             // ),
//   //         //   ],
//   //         // ),
//   //         Flexible(
//   //           flex: 3,
//   //           child: Padding(
//   //             padding: const EdgeInsets.all(8.0),
//   //             child: Card(
//   //               child: Padding(
//   //                 padding: const EdgeInsets.all(4.0),
//   //                 child: Center(
//   //                   child: Container(
//   //                     color: const Color(0xF9F2F7),
//   //                     // child: showElectricityGraph
//   //                     //     ? LineChartEMeter(
//   //                     //         screenWidth: screenWidth,
//   //                     //         screenHeight: screenHeight,
//   //                     //         eMeterSpots: eMeterSpots,
//   //                     //         isLoading: isLoading,
//   //                     //         currentMonth: currentMonth,
//   //                     //       )
//   //                     child: isLoading
//   //                         ? const Center(child: CircularProgressIndicator())
//   //                         : (waterMeterSpots.isEmpty
//   //                         ? const Center(child: Text("No water data available."))
//   //                         : LineChartWaterMeter(
//   //                       waterLineColor: Colors.blue,
//   //                       waterMeterSpots: waterMeterSpots,
//   //                       isLoading: isLoading,
//   //                       currentMonth: currentMonth,
//   //                       screenWidth: MediaQuery.of(context).size.width,
//   //                       screenHeight: MediaQuery.of(context).size.height,
//   //                     )),
//   //                   ),
//   //                 ),
//   //               ),
//   //             ),
//   //           ),
//   //         ),
//   //         Flexible(
//   //           flex: 1,
//   //           child: firebasePropertyCard(_propList),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[350],
//       appBar: AppBar(
//         title: const Text('Property Reading Trend', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.green,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           const SizedBox(height: 10),
//           const Padding(
//             padding: EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
//             child: Card(
//               child: Column(
//                 children: [
//                   SizedBox(height: 10),
//                   Center(
//                     child: Text(
//                       'Captured Consumption Trend',
//                       style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                 ],
//               ),
//             ),
//           ),
//           // Remove Flexible and Expanded conflicts
//           Expanded(
//             flex: 3,
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(4.0),
//                   child: Center(
//                     child: Container(
//                       color: const Color(0xF9F2F7),
//                       child: isLoading
//                           ? const Center(child: CircularProgressIndicator())
//                           : (waterMeterSpots.isEmpty
//                           ? const Center(child: Text("No water data available."))
//                           : LineChartWaterMeter(
//                         waterLineColor: Colors.blue,
//                         waterMeterSpots: waterMeterSpots,
//                         isLoading: isLoading,
//                         currentMonth: currentMonth,
//                         screenWidth: MediaQuery.of(context).size.width,
//                         screenHeight: MediaQuery.of(context).size.height,
//                       )),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: firebasePropertyCard(_propList),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget firebasePropertyCard(CollectionReference<Object?> propertyDataStream) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: propertyDataStream.snapshots(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
//         if (streamSnapshot.hasData) {
//           return ListView.builder(
//             itemCount: streamSnapshot.data!.docs.length,
//             itemBuilder: (context, index) {
//               final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
//
//               if (streamSnapshot.data!.docs[index]['address'] == widget.addressTarget) {
//                 return Card(
//                   margin: const EdgeInsets.only(
//                       left: 10, right: 10, top: 0, bottom: 10),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Center(
//                             child: Text(
//                               'Property Data',
//                               style: TextStyle(
//                                   fontSize: 16, fontWeight: FontWeight.w700),
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             'Account Number: ${documentSnapshot['accountNumber']}',
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w400),
//                           ),
//                           const SizedBox(height: 5),
//                           Text(
//                             'Street Address: ${documentSnapshot['address']}',
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w400),
//                           ),
//                           const SizedBox(height: 5),
//                           Text(
//                             'Area Code: ${documentSnapshot['areaCode']}',
//                             style: const TextStyle(
//                                 fontSize: 16, fontWeight: FontWeight.w400),
//                           ),
//                           const SizedBox(height: 20),
//                         ]),
//                   ),
//                 );
//               } else {
//                 return const SizedBox(height: 0, width: 0);
//               }
//             },
//           );
//         }
//         return const Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );
//   }
//
//
//   // void checkDataLoad() async {
//   //   if (context.mounted) {
//   //     setState(() {
//   //       if (electricityReadings.length == 12) {
//   //         isLoading = false;
//   //       } else {
//   //         isLoading = true;
//   //       }
//   //     });
//   //   }
//   // }
//
//   // void checkWaterLoad() async {
//   //   if (context.mounted) {
//   //     setState(() {
//   //       if (waterReadings.length == 12) {
//   //         isLoading = false;
//   //       } else {
//   //         isLoading = true;
//   //       }
//   //     });
//   //   }
//   // }
//   void checkWaterLoad() {
//     if (mounted) {  // Correctly using 'mounted' to check if the widget is still part of the tree
//       setState(() {
//         isLoading = waterReadings.length != 12;
//       });
//     }
//   }
//   Future<void> printAllAddressesInFirestore() async {
//     for (int i = 0; i < months.length; i++) {
//       var snapshot = await _consumptionCollection
//           .doc(months[i])
//           .collection('address')
//           .get();
//
//       for (var doc in snapshot.docs) {
//         var address = doc.data()['address'];
//         print('Month: ${months[i]}, Address: $address');
//       }
//     }
//   }
//   void prepareWaterReadings() {
//     waterMeterSpots.clear();
//
//     for (int i = 0; i < waterReadings.length; i++) {
//       double reading = waterReadings[i];
//       waterMeterSpots.add(FlSpot(i.toDouble(), reading));
//     }
//
//     // Debugging: print the generated spots
//     print('Water Meter Spots: $waterMeterSpots');
//
//     setState(() {});  // Ensure UI updates
//   }
//
//
//   Future<void> getWaterReadings() async {
//     setState(() {
//       isLoading = true;  // Start loading
//     });
//
//     waterReadings.clear();  // Clear previous data
//     double lastValidReading = 0.0;
//
//     for (int i = 0; i < months.length; i++) {
//       try {
//         var propertyData = await _consumptionCollection
//             .doc(months[i])
//             .collection('address')
//             .where('address', isEqualTo: widget.addressTarget.trim())
//             .get();
//
//         if (propertyData.docs.isNotEmpty) {
//           var firstDocData = propertyData.docs.first.data();
//           var reading = double.parse(firstDocData['water_meter_reading'] ?? '0');
//           if (reading > 0) lastValidReading = reading;
//           waterReadings.add(lastValidReading);
//         } else {
//           waterReadings.add(lastValidReading);  // Use last known reading
//         }
//       } catch (e) {
//         waterReadings.add(waterReadings.isNotEmpty ? waterReadings.last : 0.0);  // Default to 0 if no data
//       }
//     }
//
//     prepareWaterReadings();  // Prepare the spots for the graph
//
//     // Ensure `isLoading` is false once data is loaded
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//
//
//   Future<void> getCollectionData() async {
//     for (int i = 0; i < months.length; i++) {
//       try {
//         print('Fetching data for ${months[i]}');
//         print(
//             'Using address target: ${widget.addressTarget.trim()}'); // Log fetching data
//         var propertyData = await _consumptionCollection
//             .doc(months[i])
//             .collection('address')
//             .where('address', isEqualTo: widget.addressTarget.trim())
//             .get();
//
//         print('Fetching water data for ${months[i]}, Address: ${widget.addressTarget.trim()}');
//     // Log the number of documents found
//
//         if (propertyData.docs.isNotEmpty) {
//           var firstDocData = propertyData.docs[0].data();
//           print('Data for ${months[i]}: $firstDocData');// Log fetched data
//
//           // String meterReadingStr= firstDocData['meter_reading'] ?? '0';
//           String waterMeterReadingStr = firstDocData['water_meter_reading'] ?? '0';
//           // double meterReading = meterReadingStr.isNotEmpty ? double.parse(meterReadingStr) : 0.0;
//           double waterMeterReading = waterMeterReadingStr.isNotEmpty ? double.parse(waterMeterReadingStr) : 0.0;
//
//           monthCaptured.add(months[i]);
//           // electricityReadings.add(meterReading);
//           waterReadings.add(waterMeterReading);
//
//         } else {
//           throw Exception("No data found for ${months[i]}");
//         }
//       } catch (e) {
//         print('Error fetching water data for ${months[i]}: $e');
//         monthCaptured.add(months[i]);
//         if ( waterReadings.isNotEmpty) {
//           waterReadings.add(waterReadings.last);
//         } else {
//           waterReadings.add(0.0);
//         }
//       }
//     }
//
//     for (int i = 0; i < months.length; i++) {
//       if (months[i] == formattedMonth) {
//         currentMonth = i.toDouble();
//       }
//     }
//
//     xAxisIteration = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
//
//     // eMeterSpots = [
//     //   for (int i = 0; i < months.length; i++)
//     //     FlSpot(
//     //         xAxisIteration[i],
//     //         double.parse(
//     //             ((electricityReadings[i] / 100000) * 10).toStringAsFixed(4)))
//     // ];
//     //
//     // invalidSpots = [
//     //   for (int i = 1 + currentMonth.toInt(); i < months.length; i++)
//     //     FlSpot(
//     //         xAxisIteration[i],
//     //         double.parse(
//     //             ((electricityReadings[i] / 100000) * 10).toStringAsFixed(4)))
//     // ];
//   }
// }
//
// class LineChartWaterMeter extends StatefulWidget {
//   final Color waterLineColor;
//   final List<FlSpot> waterMeterSpots;
//   final bool isLoading;
//   final double currentMonth;
//   final double screenWidth;
//   final double screenHeight;
//
//   const LineChartWaterMeter({
//     super.key,
//     this.waterLineColor = Colors.blue,
//     required this.waterMeterSpots,
//     required this.isLoading,
//     required this.currentMonth,
//     required this.screenWidth,
//     required this.screenHeight,
//   });
//
//   @override
//   _LineChartWaterMeterState createState() => _LineChartWaterMeterState();
// }
//
// class _LineChartWaterMeterState extends State<LineChartWaterMeter> {
//   bool isLocalLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     // Ensure the local loading indicator runs for at least 5 seconds
//     Future.delayed(Duration(seconds: 5), () {
//       if (mounted) {
//         setState(() {
//           isLocalLoading = false;
//         });
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Use local loading state to manage progress indicator visibility
//     if (isLocalLoading || widget.isLoading) {
//       return Center(child: CircularProgressIndicator());
//     } else if (widget.waterMeterSpots.isEmpty) {
//       return const Center(child: Text("No water data available."));
//     }
//
//     double maxY = widget.waterMeterSpots.isNotEmpty
//         ? widget.waterMeterSpots.map((spot) => spot.y).reduce(max) * 1.2
//         : 10;
//     maxY = maxY < 10 ? 10 : maxY;
//     double minY = 0.0;
//
//     return AspectRatio(
//         aspectRatio: 1.15,
//         child: Container(
//           color: Colors.white,
//           child: LineChart(
//             LineChartData(
//               minY: minY,
//               maxY: maxY,
//               lineTouchData: const LineTouchData(enabled: true),
//               extraLinesData: ExtraLinesData(
//                 verticalLines: <VerticalLine>[
//                   VerticalLine(
//                       x: widget.currentMonth,
//                       color: Colors.greenAccent,
//                       dashArray: [4, 4]),
//                 ],
//               ),
//               lineBarsData: [
//                 LineChartBarData(
//                   spots: widget.waterMeterSpots,
//                   isCurved: false,
//                   barWidth: 4,
//                   color: Colors.blue,
//                   belowBarData: BarAreaData(
//                       show: false, color: Colors.blue.withOpacity(0.3)),
//                   aboveBarData: BarAreaData(
//                       show: false, color: Colors.blue.withOpacity(0.1)),
//                   dotData: const FlDotData(show: true),
//                 ),
//                 LineChartBarData(
//                   spots: invalidWaterSpots,
//                   isCurved: false,
//                   barWidth: 4,
//                   color: Colors.red,
//                   dotData: const FlDotData(show: true),
//                   belowBarData: BarAreaData(show: false),
//                   aboveBarData: BarAreaData(show: false),
//                 )
//               ],
//               titlesData: buildTitlesData(maxY),
//               gridData: const FlGridData(show: true, drawVerticalLine: false),
//               borderData: FlBorderData(show: true),
//             ),
//           ),
//         ));
//   }
//
//   FlTitlesData buildTitlesData(double maxY) => FlTitlesData(
//         bottomTitles: AxisTitles(
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 30,
//             interval: 1,
//             getTitlesWidget: bottomTitleWidgets,
//           ),
//         ),
//         leftTitles: AxisTitles(
//           axisNameSize: 20,
//           axisNameWidget: const Padding(
//             padding: EdgeInsets.only(
//                 bottom: 1), // Adjust the padding value as needed
//             child: Text(
//               'kilo Liters Readings',
//               style: TextStyle(
//                 color: AppColors.contentColorBlack,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//           sideTitles: SideTitles(
//             showTitles: true,
//             reservedSize: 50,
//             interval: 5,
//             getTitlesWidget: leftTitleWidgets,
//           ),
//         ),
//         rightTitles: const AxisTitles(
//           sideTitles: SideTitles(
//               showTitles: false), // Explicitly disabling right titles
//         ),
//         topTitles: const AxisTitles(
//           sideTitles: SideTitles(showTitles: false),
//         ),
//       );
//
//   Widget bottomTitleWidgets(double value, TitleMeta meta) {
//     const List<String> months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec'
//     ];
//     String text = months[value.toInt() % months.length];
//
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 4,
//       child: Text(text,
//           style: const TextStyle(
//               fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
//     );
//   }
//
//   Widget leftTitleWidgets(double value, TitleMeta meta) {
//     // Converting value to kiloliters directly in the text
//     String label =
//         '${(value).toStringAsFixed(0)} kL'; // Ensure the space is adequately considered
//
//     return SideTitleWidget(
//       axisSide: meta.axisSide,
//       space: 10.0, // You might need to adjust this space to avoid clipping
//       child: Text(
//         label, // This will display as '2000 kL' directly
//         style: const TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.w600,
//           fontSize:
//               10, // Consider increasing font size if visibility is an issue
//         ),
//       ),
//     );
//   }
// }
//
// //   class LineChartEMeter extends StatelessWidget {
// //   LineChartEMeter({
// //     super.key,
// //     Color? mainLineColor,
// //     Color? belowLineColor,
// //     Color? aboveLineColor, required this.screenWidth, required this.screenHeight,
// //   })  : mainLineColor = mainLineColor ?? AppColors.contentColorYellow.withOpacity(1),
// //         belowLineColor = belowLineColor ?? AppColors.gridLinesColor.withOpacity(0.5),
// //         aboveLineColor = aboveLineColor ?? AppColors.mainTextColor3.withOpacity(0.5);
// //
// //   final Color mainLineColor;
// //   final Color belowLineColor;
// //   final Color aboveLineColor;
// //   static const cutOffYValue = 10.0;
// //   final double screenWidth;
// //   final double screenHeight;
// //
// //   Widget bottomTitleWidgets(double value, TitleMeta meta) {
// //     String text;
// //     switch (value.toInt()) {
// //       case 0:
// //         text = 'Jan';
// //         break;
// //       case 1:
// //         text = 'Feb';
// //         break;
// //       case 2:
// //         text = 'Mar';
// //         break;
// //       case 3:
// //         text = 'Apr';
// //         break;
// //       case 4:
// //         text = 'May';
// //         break;
// //       case 5:
// //         text = 'Jun';
// //         break;
// //       case 6:
// //         text = 'Jul';
// //         break;
// //       case 7:
// //         text = 'Aug';
// //         break;
// //       case 8:
// //         text = 'Sep';
// //         break;
// //       case 9:
// //         text = 'Oct';
// //         break;
// //       case 10:
// //         text = 'Nov';
// //         break;
// //       case 11:
// //         text = 'Dec';
// //         break;
// //       default:
// //         return Container();
// //     }
// //
// //     return SideTitleWidget(
// //       axisSide: meta.axisSide,
// //       space: 4,
// //       child: Text(
// //         text,
// //         style: TextStyle(
// //           fontSize: 10,
// //           color: mainLineColor,
// //           fontWeight: FontWeight.bold,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget leftTitleWidgets(double value, TitleMeta meta) {
// //     const style = TextStyle(
// //       color: AppColors.contentColorBlack,
// //       fontWeight: FontWeight.w600,
// //       fontSize: 7,
// //     );
// //     return SideTitleWidget(
// //       axisSide: meta.axisSide,
// //       child: Text((value * 100000).toStringAsFixed(0), style: style),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     const cutOffYValue = 10.0;
// //
// //     double startValue = double.parse(((electricityReadings[0] / 100000) * 10).toStringAsFixed(4)) - 2;
// //     double endValue = double.parse(((electricityReadings[11] / 100000) * 10).toStringAsFixed(4)) + 2;
// //
// //     return AspectRatio(
// //       aspectRatio: 1.15,
// //       child: Padding(
// //         padding: const EdgeInsets.only(
// //           left: 12,
// //           right: 28,
// //           top: 22,
// //           bottom: 12,
// //         ),
// //         child: LineChart(
// //           LineChartData(
// //             lineTouchData: const LineTouchData(enabled: true),
// //             extraLinesData: ExtraLinesData(
// //               verticalLines: <VerticalLine>[
// //                 VerticalLine(x: currentMonth, color: Colors.greenAccent, dashArray: [4, 4]),
// //               ],
// //             ),
// //             lineBarsData: [
// //               LineChartBarData(
// //                 spots: eMeterSpots,
// //                 isCurved: false,
// //                 barWidth: 4,
// //                 color: mainLineColor,
// //                 belowBarData: BarAreaData(
// //                   show: true,
// //                   color: belowLineColor,
// //                   cutOffY: 0,
// //                   applyCutOffY: true,
// //                 ),
// //                 aboveBarData: BarAreaData(
// //                   show: true,
// //                   color: aboveLineColor,
// //                   cutOffY: endValue,
// //                   applyCutOffY: true,
// //                 ),
// //                 dotData: const FlDotData(
// //                   show: true,
// //                 ),
// //               ),
// //               LineChartBarData(
// //                 spots: [
// //                   FlSpot(0, startValue),
// //                   FlSpot(11, endValue),
// //                 ],
// //                 color: Colors.transparent,
// //               ),
// //               LineChartBarData(
// //                 spots: invalidSpots,
// //                 color: Colors.redAccent,
// //                 barWidth: 4,
// //               ),
// //             ],
// //             minY: 0,
// //             titlesData: FlTitlesData(
// //               show: true,
// //               topTitles: const AxisTitles(
// //                 sideTitles: SideTitles(showTitles: false),
// //               ),
// //               rightTitles: const AxisTitles(
// //                 sideTitles: SideTitles(showTitles: false),
// //               ),
// //               bottomTitles: AxisTitles(
// //                 sideTitles: SideTitles(
// //                   showTitles: true,
// //                   reservedSize: 18,
// //                   interval: 1,
// //                   getTitlesWidget: bottomTitleWidgets,
// //                 ),
// //               ),
// //               leftTitles: AxisTitles(
// //                 axisNameSize: 20,
// //                 axisNameWidget: const Text(
// //                   'kWh Readings',
// //                   style: TextStyle(color: AppColors.contentColorBlack, fontWeight: FontWeight.w800),
// //                 ),
// //                 sideTitles: SideTitles(
// //                   showTitles: true,
// //                   interval: 1,
// //                   reservedSize: 40,
// //                   getTitlesWidget: leftTitleWidgets,
// //                 ),
// //               ),
// //             ),
// //             borderData: FlBorderData(
// //               show: true,
// //               border: Border.all(
// //                 color: AppColors.itemsBackground,
// //               ),
// //             ),
// //             gridData: FlGridData(
// //               show: true,
// //               drawVerticalLine: false,
// //               horizontalInterval: 1,
// //               checkToShowHorizontalLine: (double value) {
// //                 return value == 1 || value == 3 || value == 5 || value == 7;
// //               },
// //             ),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// // class LineChartEMeter extends StatefulWidget {
// //   final Color mainLineColor;
// //   final List<FlSpot> eMeterSpots;
// //   final bool isLoading;
// //   final double currentMonth;
// //   final double screenWidth;
// //   final double screenHeight;
// //
// //   const LineChartEMeter({
// //     super.key,
// //     this.mainLineColor = Colors.yellow,
// //     required this.eMeterSpots,
// //     required this.isLoading,
// //     required this.currentMonth,
// //     required this.screenWidth,
// //     required this.screenHeight,
// //   });
// //
// //   @override
// //   _LineChartEMeterState createState() => _LineChartEMeterState();
// // }
// //
// // class _LineChartEMeterState extends State<LineChartEMeter> {
// //   bool isLocalLoading = true;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Mimic the 5-second delay as in the water chart
// //     Future.delayed(Duration(seconds: 5), () {
// //       if (mounted) {
// //         setState(() {
// //           isLocalLoading = false;
// //         });
// //       }
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (isLocalLoading || widget.isLoading) {
// //       return Center(child: CircularProgressIndicator());
// //     } else if (widget.eMeterSpots.isEmpty) {
// //       return const Center(child: Text("No electricity data available."));
// //     }
// //
// //     double maxY = widget.eMeterSpots.isNotEmpty
// //         ? widget.eMeterSpots.map((spot) => spot.y).reduce(max) * 1.2
// //         : 10;
// //     maxY = maxY < 10 ? 10 : maxY;
// //     double minY = 0.0;
// //
// //     return AspectRatio(
// //       aspectRatio: 1.15,
// //       child: Container(
// //         color: Colors.white,
// //         child: LineChart(
// //           LineChartData(
// //             minY: minY,
// //             maxY: maxY,
// //             lineTouchData: const LineTouchData(enabled: true),
// //             extraLinesData: ExtraLinesData(
// //               verticalLines: <VerticalLine>[
// //                 VerticalLine(
// //                     x: widget.currentMonth,
// //                     color: Colors.greenAccent,
// //                     dashArray: [4, 4]),
// //               ],
// //             ),
// //             lineBarsData: [
// //               LineChartBarData(
// //                 spots: widget.eMeterSpots,
// //                 isCurved: false,
// //                 barWidth: 4,
// //                 color: widget.mainLineColor,
// //                 belowBarData: BarAreaData(
// //                     show: false, color: widget.mainLineColor.withOpacity(0.3)),
// //                 aboveBarData: BarAreaData(
// //                     show: false, color: widget.mainLineColor.withOpacity(0.1)),
// //                 dotData: const FlDotData(show: true),
// //               ),
// //               LineChartBarData(
// //                 spots: invalidSpots,
// //                 isCurved: false,
// //                 barWidth: 4,
// //                 color: Colors.red, // Different color for invalid spots
// //                 dotData: const FlDotData(show: true),
// //                 belowBarData: BarAreaData(show: false),
// //                 aboveBarData: BarAreaData(show: false),
// //               ) // Handle invalid spots if necessary
// //             ],
// //             titlesData: buildTitlesData(maxY),
// //             gridData: const FlGridData(
// //               show: true,
// //               drawVerticalLine: false,
// //             ),
// //             borderData: FlBorderData(show: true),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   FlTitlesData buildTitlesData(double maxY) {
// //     return FlTitlesData(
// //       bottomTitles: AxisTitles(
// //         sideTitles: SideTitles(
// //           showTitles: true,
// //           reservedSize: 30,
// //           interval: 1,
// //           getTitlesWidget: bottomTitleWidgets,
// //         ),
// //       ),
// //       leftTitles: AxisTitles(
// //         axisNameSize: 20,
// //         axisNameWidget: const Padding(
// //           padding: EdgeInsets.only(bottom: 1),
// //           child: Text(
// //             'kWh Readings',
// //             style: TextStyle(
// //               color: AppColors.contentColorBlack,
// //               fontWeight: FontWeight.w800,
// //             ),
// //           ),
// //         ),
// //         sideTitles: SideTitles(
// //           showTitles: true,
// //           reservedSize: 50,
// //           interval: 1,
// //           getTitlesWidget: leftTitleWidgets,
// //         ),
// //       ),
// //       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
// //     );
// //   }
// //
// //   Widget bottomTitleWidgets(double value, TitleMeta meta) {
// //     const List<String> months = [
// //       'Jan',
// //       'Feb',
// //       'Mar',
// //       'Apr',
// //       'May',
// //       'Jun',
// //       'Jul',
// //       'Aug',
// //       'Sep',
// //       'Oct',
// //       'Nov',
// //       'Dec'
// //     ];
// //     String text = months[value.toInt() % months.length];
// //     return Text(text,
// //         style: TextStyle(
// //             fontSize: 10,
// //             color: Colors.yellow[800],
// //             fontWeight: FontWeight.bold));
// //   }
// //
// //   Widget leftTitleWidgets(double value, TitleMeta meta) {
// //     String label = '${value.toStringAsFixed(0)} kWh';
// //     return Text(label,
// //         style: TextStyle(
// //             color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w600));
// //   }
// // }
//
class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}
