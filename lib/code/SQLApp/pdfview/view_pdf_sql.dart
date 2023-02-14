import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PDFViewPage extends StatefulWidget {
  final String url;
  final String name;

  const PDFViewPage({
    required this.url, required this.name,
  });

  @override
  _PDFViewPageState createState() => _PDFViewPageState();
}

class _PDFViewPageState extends State<PDFViewPage>{
  bool loading = true;
  late final File pdfDocument;
  
  loadPdf()async{
    pdfDocument = await File.fromUri(Uri.parse(widget.url));
  }

  late PDFViewController controller;
  int pages = 0;
  int indexPage = 0;

  @override
  void initState(){
    super.initState();
    loadPdf();
  }

  @override
  Widget build(BuildContext context){

    final text = '${indexPage + 1} of $pages';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.green,
        actions: pages >= 2
            ? [
          Center(child: Text(text)),
          IconButton(
            icon: Icon(Icons.chevron_left, size: 32),
            onPressed: () {
              final page = indexPage == 0 ? pages : indexPage - 1;
              controller.setPage(page);
            },
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, size: 32),
            onPressed: () {
              final page = indexPage == pages - 1 ? 0 : indexPage + 1;
              controller.setPage(page);
            },
          ),
        ]
            : null,
      ),
      body: PDFView(
        filePath: widget.url,
        // autoSpacing: false,
        // swipeHorizontal: true,
         pageSnap: false,
         pageFling: false,
        onRender: (pages) => setState(() => this.pages = pages!),
        onViewCreated: (controller) =>
            setState(() => this.controller = controller),
        onPageChanged: (indexPage, _) =>
            setState(() => this.indexPage = indexPage!),
      ),
    );
  }
}