import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:municipal_services/code/ImageUploading/image_zoom_page.dart';
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
  const PropertyTrend({super.key, required this.addressTarget, required this.districtId, required this.municipalityId,required this.isLocalMunicipality,this.isLocalUser=false, required this.handlesWater,
    required this.handlesElectricity, });
  final String districtId;
  final String municipalityId;
  final String addressTarget;
  final bool isLocalMunicipality;
  final bool isLocalUser;
  final bool handlesWater;
  final bool handlesElectricity;
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
List<double> electricityReadings = [];
List<FlSpot> electricityMeterSpots = [];
List<FlSpot> invalidElectricitySpots = [];
bool isLoadingWater = false;
bool isLoadingElectricity = false;

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


    if (widget.handlesElectricity && !widget.handlesWater) {
      showElectricityGraph = true;
    } else {
      showElectricityGraph = false;
    }

    // 🔁 Now load the appropriate graph data
    if (showElectricityGraph) {
      getElectricityReadings();
    } else {
      getWaterReadings();
    }


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
        Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 0),
            child: Card(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Captured Consumption Trend',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                if (widget.handlesWater && widget.handlesElectricity)
                    Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !showElectricityGraph ? Colors.blue : Colors.grey.shade300,
                          foregroundColor: !showElectricityGraph ? Colors.white : Colors.black,
                          elevation: !showElectricityGraph ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.water_drop),
                        label: const Text("Water"),
                        onPressed: () async {
                          if (mounted) {
                            setState(() {
                              showElectricityGraph = false;
                              isLoadingWater = true;
                            });
                            await getWaterReadings();
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: showElectricityGraph ? Colors.orange : Colors.grey.shade300,
                          foregroundColor: showElectricityGraph ? Colors.white : Colors.black,
                          elevation: showElectricityGraph ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.bolt),
                        label: const Text("Electricity"),
                        onPressed: () async {
                          if (mounted) {
                            setState(() {
                              showElectricityGraph = true;
                              isLoadingElectricity = true;
                            });
                            await getElectricityReadings();
                          }
                        },
                      ),
                    ],
                  ),
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
                          ? const CircularProgressIndicator()
                          : (showElectricityGraph
                          ? LineChartElectricityMeter(
                        electricityLineColor: Colors.orange,
                        electricityMeterSpots: electricityMeterSpots,
                        invalidElectricitySpots: invalidElectricitySpots,
                        isLoading: isLoading,
                        currentMonth: currentMonth,
                        screenWidth: MediaQuery.of(context).size.width,
                        screenHeight: MediaQuery.of(context).size.height,
                      )
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
                          if(widget.handlesWater)...[
                          Text(
                            'Account Number: ${documentSnapshot['accountNumber']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          ],
                          if(widget.handlesElectricity)...[
                            Text(
                              'Account Number: ${documentSnapshot['electricityAccountNumber']}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                            ),
                          ],
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
    if (mounted) {
      setState(() {
        isLoading = true; // Start loading data
      });
    }

    waterReadings.clear();  // Clear previous data
    waterMeterSpots.clear(); // Clear previous spots
    invalidWaterSpots.clear(); // Clear invalid spots
    double lastValidReading = 0.0;

    int currentYear = DateTime.now().year;
    int previousYear = currentYear - 1;

    try {
      for (int i = 0; i < months.length; i++) {
        String yearToUse = currentYear.toString(); // Default to current year

        // Special case: If it's January, fetch the previous year's December reading
        if (months[i] == "December") {
          if (DateTime.now().month == 1) {
            yearToUse = previousYear.toString(); // Use last year's December
          } else {
            yearToUse = currentYear.toString(); // Use current year’s December
          }
        }

        // 🔹 Firestore Path Debugging
        String firestorePath = "$yearToUse/${months[i]}/${widget.addressTarget.trim()}";
        print("📌 Constructed Firestore Path: $_consumptionCollection/$firestorePath");

        var propertyDoc = await _consumptionCollection
            .doc(yearToUse) // Use the correct year folder
            .collection(months[i]) // Access the month
            .doc(widget.addressTarget.trim()) // Directly reference the property address document
            .get();

        if (propertyDoc.exists) {
          var firstDocData = propertyDoc.data();
          print("✅ Data Found for ${months[i]} ($yearToUse): $firstDocData");

          var readingStr = firstDocData?['water_meter_reading'] ?? '0';
          double reading = double.tryParse(readingStr) ?? 0.0;

          print("📊 Parsed Reading for ${months[i]} ($yearToUse): $reading");

          if (reading > 1000) {
            reading = log(reading); // Apply log scaling if needed
          }

          if (reading > 0) {
            lastValidReading = reading;
            waterMeterSpots.add(FlSpot(i.toDouble(), reading));
          } else {
            invalidWaterSpots.add(FlSpot(i.toDouble(), lastValidReading));
          }

          waterReadings.add(lastValidReading);
        } else {
          // ❗ No data found for the month
          print("⚠️ No data found for $firestorePath");
          waterReadings.add(lastValidReading); // Use last valid reading
          invalidWaterSpots.add(FlSpot(i.toDouble(), lastValidReading));
        }
      }

      // 🔹 Debug the Water Meter Spots Data
      print("📊 Final Water Meter Spots: $waterMeterSpots");

      // Calculate the current month index (January = 0, February = 1, etc.)
      DateTime now = DateTime.now();
      int currentMonthIndex = now.month - 1; // Convert to zero-based index
      currentMonth = currentMonthIndex.toDouble(); // Set currentMonth for the vertical line

      prepareWaterReadings(); // Prepare graph data points

    } catch (e) {
      debugPrint("❌ Error fetching water readings: $e");
      if (waterReadings.isNotEmpty) {
        waterReadings.add(waterReadings.last);
      } else {
        waterReadings.add(0.0); // Default value if no data at all
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void prepareWaterReadings() {
    waterMeterSpots.clear();  // Clear previous spots
    for (int i = 0; i < waterReadings.length; i++) {
      double reading = waterReadings[i];
      waterMeterSpots.add(FlSpot(i.toDouble(), reading));
    }
    debugPrint('Water Meter Spots: $waterMeterSpots');
         if(mounted) { // Debug print spots for checking
           setState(() {});
         }
  }

  Future<void> getElectricityReadings() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    electricityReadings.clear();
    electricityMeterSpots.clear();
    invalidElectricitySpots.clear();
    double lastValidReading = 0.0;

    int currentYear = DateTime.now().year;
    int previousYear = currentYear - 1;

    try {
      for (int i = 0; i < months.length; i++) {
        String monthName = months[i];
        String yearToUse = (monthName == "December" && DateTime.now().month == 1)
            ? previousYear.toString()
            : currentYear.toString();

        String firestorePath = "$yearToUse/$monthName/${widget.addressTarget.trim()}";
        print("⚡ Fetching Electricity Data: $_consumptionCollection/$firestorePath");

        var propertyDoc = await _consumptionCollection
            .doc(yearToUse)
            .collection(monthName)
            .doc(widget.addressTarget.trim())
            .get();

        if (propertyDoc.exists) {
          var data = propertyDoc.data();
          var readingStr = data?['meter_reading'] ?? '0';
          double reading = double.tryParse(readingStr) ?? 0.0;

          if (reading > 1000) reading = log(reading);
          if (reading > 0) {
            lastValidReading = reading;
            electricityMeterSpots.add(FlSpot(i.toDouble(), reading));
          } else {
            invalidElectricitySpots.add(FlSpot(i.toDouble(), lastValidReading));
          }

          electricityReadings.add(lastValidReading);
        } else {
          // No document for this month – fill with last known value
          print("⚠️ No electricity data found for $firestorePath");
          electricityReadings.add(lastValidReading);
          invalidElectricitySpots.add(FlSpot(i.toDouble(), lastValidReading));
        }
      }

      // Generate final graph points to ensure 12 spots (Jan to Dec)
      electricityMeterSpots = electricityReadings
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();

      // Update the currentMonth index for vertical highlight
      DateTime now = DateTime.now();
      currentMonth = (now.month - 1).toDouble();
    } catch (e) {
      debugPrint("❌ Error fetching electricity readings: $e");
      if (electricityReadings.isEmpty) {
        electricityReadings.add(0.0);
        electricityMeterSpots.add(const FlSpot(0.0, 0.0));
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
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
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasValidData = widget.waterMeterSpots.isNotEmpty ||
        invalidWaterSpots.isNotEmpty;
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
                    color: widget.waterLineColor,
                    // Blue Line for valid data
                    belowBarData: BarAreaData(
                        show: false, color: Colors.blue.withOpacity(0.3)),
                    aboveBarData: BarAreaData(
                        show: false, color: Colors.blue.withOpacity(0.1)),
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: invalidWaterSpots,
                    // Red Line for missing data
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

  FlTitlesData buildTitlesData(double maxY) =>
      FlTitlesData(
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
      meta: meta, // ⬅️ pass the TitleMeta, not axisSide
      space: 4,
      child: Text(text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          )),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final label = '${value.toStringAsFixed(0)} kL';
    return SideTitleWidget(
      meta: meta,
      space: 10,
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

  class LineChartElectricityMeter extends StatefulWidget {
  final Color electricityLineColor;
  final List<FlSpot> electricityMeterSpots;
  final List<FlSpot> invalidElectricitySpots;
  final bool isLoading;
  final double currentMonth;
  final double screenWidth;
  final double screenHeight;

  const LineChartElectricityMeter({
    super.key,
    this.electricityLineColor = Colors.orange,
    required this.electricityMeterSpots,
    required this.invalidElectricitySpots,
    required this.isLoading,
    required this.currentMonth,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  _LineChartElectricityMeterState createState() => _LineChartElectricityMeterState();
}

class _LineChartElectricityMeterState extends State<LineChartElectricityMeter> {
  bool isLocalLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          isLocalLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasValidData = widget.electricityMeterSpots.isNotEmpty;
    if (isLocalLoading || widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (!hasValidData) {
      return const Center(child: Text("No electricity data available."));
    }

    double maxReading = widget.electricityMeterSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    double minReading = widget.electricityMeterSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double range = (maxReading - minReading).abs();
    range = range == 0 ? 1 : range;

    double maxY = range < 5 ? maxReading + 5 : maxReading * 1.2;
    maxY = maxY < 10 ? 10 : maxY;

    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        color: Colors.white,
        child: LineChart(
          LineChartData(
            minY: 0.0,
            maxY: maxY,
            lineTouchData: const LineTouchData(enabled: true),
            extraLinesData: ExtraLinesData(
              verticalLines: [
                VerticalLine(
                  x: widget.currentMonth,
                  color: Colors.greenAccent,
                  dashArray: [4, 4],
                ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: widget.electricityMeterSpots,
                isCurved: false,
                barWidth: 4,
                color: widget.electricityLineColor,
                belowBarData: BarAreaData(show: false),
                aboveBarData: BarAreaData(show: false),
                dotData: const FlDotData(show: true),
              ),
              LineChartBarData(
                spots: widget.invalidElectricitySpots,
                isCurved: false,
                barWidth: 4,
                color: Colors.red,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
                aboveBarData: BarAreaData(show: false),
              ),
            ],
            titlesData: _buildTitlesData(),
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: true),
          ),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData() => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: 1,
        getTitlesWidget: _bottomTitleWidgets,
      ),
    ),
    leftTitles: AxisTitles(
      axisNameSize: 20,
      axisNameWidget: const Padding(
        padding: EdgeInsets.only(bottom: 1),
        child: Text(
          'kWh',
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
        getTitlesWidget: _leftTitleWidgets,
      ),
    ),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
  );

  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String text = months[value.toInt() % months.length];
    return SideTitleWidget(
     meta:  meta,
      space: 4,
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta:  meta,
      space: 10,
      child: Text(
        '${value.toStringAsFixed(0)} kWh',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}



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
