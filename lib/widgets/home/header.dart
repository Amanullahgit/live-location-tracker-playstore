import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:launch_review/launch_review.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';
import 'package:live_tracker/models/checkinternet.dart';
import 'package:live_tracker/models/snackbar.dart';

class HomeHeader extends StatefulWidget {
  final BoxDecoration _decoration;
  late final String name;
  late final String user_id;
  late final String status;

  HomeHeader(this._decoration, this.name, this.user_id, this.status);

  @override
  _HomeHeaderState createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool isSwitched = false;
  TextEditingController _textEditingController = TextEditingController();
  String tempname = '';
  static const String instagramUrl = 'https://www.instagram.com/amanullah_ig';

  final loc.Location location = loc.Location();

  StreamSubscription<loc.LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    checkstatus();
    location.enableBackgroundMode(enable: true);
    location.changeSettings(interval: 100, accuracy: loc.LocationAccuracy.high);
  }

  checkstatus() async {
    if (widget.status == "active") {
      setState(() {
        isSwitched = true;
      });

      _listenLocation();
    } else {
      setState(() {
        isSwitched = false;
      });
      _stopListen();
    }
  }

  @override
  Widget build(BuildContext context) {
    print(isSwitched);
    print(widget.status);
    return Container(
      decoration: widget._decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    child:
                        tempname.isEmpty ? Text(widget.name) : Text(tempname),
                    margin: EdgeInsets.only(left: 10),
                  ),
                  TextButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return alertDialogForName();
                            });
                      },
                      child: Text('change'))
                ],
              ),
              IconButton(
                  icon: Icon(Icons.info_outline_rounded),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildAboutDialog(context),
                    );
                  })
            ],
          ),
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 4,
            child: isSwitched
                ? Image.asset(
                    './images/loc.png',
                  )
                : Image.asset('./images/loc_off.png'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Your Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Switch(
                value: isSwitched,
                onChanged: (value) async {
                  if (await InternetStatus().checkInternet) {
                    showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => WillPopScope(
                              onWillPop: () => Future.value(false),
                              child: Container(
                                  child: Center(
                                child: CircularProgressIndicator(),
                              )),
                            ));

                    if (value == true) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users_info')
                            .doc(widget.user_id)
                            .update({'status': 'active'});
                        _listenLocation();
                        setState(() {
                          isSwitched = value;
                          print(isSwitched);
                        });

                        Navigator.of(context).pop();
                      } catch (e) {
                        print(e);
                      }
                    } else {
                      try {
                        await FirebaseFirestore.instance
                            .collection('users_info')
                            .doc(widget.user_id)
                            .update({'status': 'inactive'});
                        _stopListen();
                        setState(() {
                          isSwitched = value;
                          print(isSwitched);
                        });

                        Navigator.of(context).pop();
                      } catch (e) {
                        print(e);
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        ShowSnack('check your internet!').snackBar);
                  }
                },
                activeColor: Colors.green,
              )
            ],
          ),
        ],
      ),
    );
  }

  changeName(String name) async {
    if (await InternetStatus().checkInternet) {
      await FirebaseFirestore.instance
          .collection('users_info')
          .doc(widget.user_id)
          .update({'name': name});
      FocusScope.of(context).unfocus();
      setState(() {
        tempname = _textEditingController.text;
      });
      setupTextField();
    } else {
      setupTextField();
      ScaffoldMessenger.of(context)
          .showSnackBar(ShowSnack('check your internet!').snackBar);
    }
  }

  setupTextField() {
    FocusScope.of(context).unfocus();
    _textEditingController.clear();
    Navigator.of(context).pop();
  }

  alertDialogForName() {
    return AlertDialog(
      title: Text('Change your name'),
      content: TextFormField(
        controller: _textEditingController,
        decoration: InputDecoration(labelText: 'Your name'),
        maxLength: 10,
        onFieldSubmitted: (val) {
          if (val.length < 1) {
            FocusScope.of(context).unfocus();
            _textEditingController.clear();
          } else {
            changeName(val);
          }
        },
      ),
      actions: [
        TextButton(
            onPressed: () {
              setupTextField();
            },
            child: Text('Cancel')),
        TextButton(
            onPressed: () {
              if (_textEditingController.text.length > 0) {
                changeName(_textEditingController.text);
              }
            },
            child: Text('Ok')),
      ],
    );
  }

  Future<void> _listenLocation() async {
    _locationSubscription =
        location.onLocationChanged.handleError((dynamic err) {
      if (err is PlatformException) {
        print(err);
      }
      _locationSubscription?.cancel();
      setState(() {
        _locationSubscription = null;
      });
    }).listen((loc.LocationData currentLocation) async {
      await FirebaseFirestore.instance
          .collection('loc')
          .doc(widget.user_id)
          .set({
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude
      }, SetOptions(merge: true));
    });
  }

  Future<void> _stopListen() async {
    _locationSubscription?.cancel();
    setState(() {
      _locationSubscription = null;
    });
  }

  Widget _buildAboutDialog(BuildContext context) {
    return new AlertDialog(
      title: const Text('About'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildAboutText(),
        ],
      ),
      actions: <Widget>[
        new TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Okay, got it!',
            style: TextStyle(color: Color(0xff01A7FF)),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutText() {
    return new RichText(
      text: new TextSpan(
        text:
            'Live Tracker allows you to share your live location with friends and your loved ones.\n\nthe app is written in flutter, and the source code is available at ',
        style: const TextStyle(color: Colors.black87),
        children: <TextSpan>[
          TextSpan(
            style: TextStyle(color: Colors.blue),
            text: 'Source code\n\n',
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openUrl(
                    'https://github.com/Amanullahgit/live-location-tracker-playstore');
              },
          ),
          TextSpan(text: 'Find more apps by LazyTechno '),
          TextSpan(
            style: TextStyle(color: Colors.blue),
            text: 'More Apps\n\n',
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openUrl(
                    'https://play.google.com/store/apps/developer?id=LazyTechNo');
              },
          ),
          const TextSpan(
              text:
                  'Your feedbacks are important for us, feel free to give us 5 star.\n\n'),
          TextSpan(
            style: TextStyle(color: Colors.blue, fontSize: 16),
            text: 'Rate App Now\n\n',
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                LaunchReview.launch(
                  writeReview: true,
                  androidAppId: "com.aaddev.live_tracker",
                );
              },
          ),
          TextSpan(
            style: TextStyle(color: Colors.blue, fontSize: 16),
            text: 'Follow me here',
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openUrl(instagramUrl);
              },
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    // Close the about dialog.

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
