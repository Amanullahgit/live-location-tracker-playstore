import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:live_tracker/home.dart';
import 'package:live_tracker/models/checkinternet.dart';
import 'package:live_tracker/models/snackbar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrscan/qrscan.dart' as scanner;

class ScannerScreen extends StatefulWidget {
  final String user_id;
  ScannerScreen(this.user_id);

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool generate = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Scan To Pair'),
          leading: IconButton(
            icon: Icon(Icons.keyboard_arrow_left_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: QrImage(
                data: widget.user_id,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                      child: TextButton(
                    child: Text('Generate'),
                    onPressed: () {
                      setState(() {
                        generate = true;
                      });
                    },
                  )),
                  Container(
                      child: TextButton(
                    child: Text('Scan'),
                    onPressed: () {
                      setState(() {
                        generate = false;
                      });
                      _scanPhoto();
                    },
                  )),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future _scanPhoto() async {
    await Permission.camera.request();
    String barcode = (await scanner.scan())!;
    if (barcode == null) {
      print('nothing return.');
    } else {
      if (await InternetStatus().checkInternet) {
        await FirebaseFirestore.instance
            .collection(widget.user_id)
            .doc('pairs')
            .set({barcode: true}, SetOptions(merge: true));
        await FirebaseFirestore.instance
            .collection(barcode)
            .doc('pairs')
            .set({widget.user_id: true}, SetOptions(merge: true)).whenComplete(
                () => Navigator.of(context).pop());
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(ShowSnack('check your internet!').snackBar);
      }
    }
  }
}
