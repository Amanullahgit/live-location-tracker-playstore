import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:live_tracker/detail.dart';
import 'package:live_tracker/models/checkinternet.dart';
import 'package:live_tracker/models/snackbar.dart';

class HomeBody extends StatefulWidget {
  final BoxDecoration _decoration;
  final String _deviceID;

  HomeBody(this._decoration, this._deviceID);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  List pairsList = [];

  @override
  void initState() {
    super.initState();

    getPairs();
  }

  @override
  Widget build(BuildContext context) {
    return pairsList.isEmpty
        ? Center(
            child: Text('no pairs'),
          )
        : Expanded(
            child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users_info')
                .where('id', whereIn: pairsList)
                .snapshots(includeMetadataChanges: true),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return pairWidget(snapshot);
            },
          ));
  }

  Widget pairWidget(AsyncSnapshot<QuerySnapshot> snapshot) {
    return AnimationLimiter(
      child: ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: Duration(milliseconds: 700),
              child: SlideAnimation(
                child: FadeInAnimation(
                  child: Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: widget._decoration.copyWith(boxShadow: [
                        BoxShadow(
                            offset: Offset(0, 1),
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 3)
                      ]),
                      child: ListTile(
                          title: Text(
                            snapshot.data!.docs[index]['name'].toString(),
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                          subtitle: Text(
                            'status: ${snapshot.data!.docs[index]['status']}',
                            style: TextStyle(fontSize: 16),
                          ),
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 28,
                                color: snapshot.data!.docs[index]['status'] ==
                                        'active'
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.directions,
                              color: Colors.blue,
                            ),
                            onPressed: snapshot.data!.docs[index]['status'] ==
                                    'active'
                                ? () async {
                                    if (await InternetStatus().checkInternet) {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: (context) => DetailPage(
                                                    snapshot.data!.docs[index]
                                                        ['id'],
                                                  )));
                                      getPairs();
                                    } else {}
                                  }
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        ShowSnack('user location is off')
                                            .snackBar);
                                  },
                          ))),
                ),
              ),
            );
          }),
    );
  }

  Future getPairs() async {
    pairsList.clear();
    if (await InternetStatus().checkInternet) {
      await FirebaseFirestore.instance
          .collection(widget._deviceID)
          .doc('pairs')
          .get()
          .then((value) {
        print('value ${value.data()}');
        if (value.exists) {
          value.data()!.forEach((key, value) {
            pairsList.add(key);
          });
        }
      });

      setState(() {});
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(ShowSnack('check your internet!').snackBar);
    }
  }

  // Future<void> _getLocation() async {
  //   try {
  //     location.enableBackgroundMode(enable: true);
  //     location.changeSettings(
  //         interval: 100, accuracy: loc.LocationAccuracy.high);

  //     final loc.LocationData _locationResult = await location.getLocation();

  //     setState(() {
  //       _location = _locationResult;
  //     });
  //   } on Exception catch (err) {
  //     print(err);
  //   }
  // }
}
