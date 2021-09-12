import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:live_tracker/detail.dart';
import 'package:live_tracker/home.dart';
import 'package:live_tracker/scan.dart';

bool USE_FIRESTORE_EMULATOR = false;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (USE_FIRESTORE_EMULATOR) {
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  runApp(MaterialApp(
    home: MyApp(),
    theme: ThemeData(
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: Colors.black87),
        appBarTheme: AppBarTheme(color: Colors.black87)),
    debugShowCheckedModeBanner: false,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return HomePage();
  }
}
