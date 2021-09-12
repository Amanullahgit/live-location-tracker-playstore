import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:live_tracker/models/snackbar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:live_tracker/scan.dart';
import 'models/checkinternet.dart';
import 'widgets/home/body.dart';
import 'widgets/home/header.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  late AndroidDeviceInfo androidInfo;
  String deviceName = '';
  String user_id = '';
  String status = '';
  bool noInternet = false;
  BoxDecoration _containerDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.3),
          spreadRadius: 3,
          blurRadius: 3,
          offset: Offset(0, 0), // changes position of shadow
        ),
      ]);

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.qr_code_scanner_rounded),
        onPressed: noInternet
            ? () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(ShowSnack('check your internet!').snackBar);
              }
            : () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ScannerScreen(user_id)));
                setState(() {});
              },
      ),
      body: noInternet
          ? Center(child: Text('I need Internet Connection!'))
          : Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  status.isEmpty
                      ? Container(
                          decoration: _containerDecoration,
                        )
                      : HomeHeader(
                          _containerDecoration, deviceName, user_id, status),
                  SizedBox(
                    height: 10,
                  ),
                  user_id.isEmpty
                      ? Container()
                      : HomeBody(_containerDecoration, user_id),
                ],
              ),
            ),
    );
  }

  getDeviceInfo() async {
    androidInfo = await deviceInfo.androidInfo;

    setState(() {
      deviceName = androidInfo.host!;
      user_id = androidInfo.androidId!;
    });
    if (await InternetStatus().checkInternet) {
      getUserInfo();
    } else {
      noInternet = true;
    }
  }

  getUserInfo() async {
    try {
      await FirebaseFirestore.instance
          .collection('users_info')
          .doc(user_id)
          .get()
          .onError((error, stackTrace) {
        print(error);
        print(stackTrace);
        return setUserInfo();
      }).then((value) {
        if (value.exists) {
          setState(() {
            deviceName = value.data()!['name'];
            status = value.data()!['status'];
          });
        } else {
          setUserInfo();
        }
      });
    } catch (e) {
      print('from getUserInfo: $e');
    }
  }

  setUserInfo() async {
    try {
      await FirebaseFirestore.instance
          .collection('users_info')
          .doc(user_id)
          .set({'name': deviceName, 'status': 'inactive', 'id': user_id});
      getDeviceInfo();
    } catch (e) {
      print('from setUserInfo: $e');
    }
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      // Permission.locationAlways,
      Permission.location,
      Permission.storage,
      Permission.camera,
    ].request();
    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.location]!.isGranted &&
        // statuses[Permission.locationAlways]!.isGranted &&
        statuses[Permission.storage]!.isGranted) {
      getDeviceInfo();
    } else if (statuses[Permission.camera]!.isDenied ||
        statuses[Permission.location]!.isDenied ||
        // statuses[Permission.locationAlways]!.isDenied ||
        statuses[Permission.storage]!.isDenied) {
      _requestPermission();
    }
    print(statuses);
  }
}
