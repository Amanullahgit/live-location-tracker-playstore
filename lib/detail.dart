import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String user_id;
  DetailPage(this.user_id);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late GoogleMapController _controller;
  bool _added = false;
  final loc.Location location = loc.Location();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: widget.user_id == null
            ? Center(child: CircularProgressIndicator())
            : StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('loc').snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (_added) {
                    mapMove(snapshot);
                  }
                  if (!snapshot.hasData || snapshot.data?.docs == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  return GoogleMap(
                    mapType: MapType.normal,
                    markers: {
                      Marker(
                        markerId: MarkerId('id'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueMagenta),
                        position: LatLng(
                            snapshot.data?.docs.singleWhere((element) =>
                                element.id == widget.user_id)['latitude'],
                            snapshot.data?.docs.singleWhere((element) =>
                                element.id == widget.user_id)['longitude']),
                      )
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                          snapshot.data?.docs.singleWhere((element) =>
                              element.id == widget.user_id)['latitude'],
                          snapshot.data?.docs.singleWhere((element) =>
                              element.id == widget.user_id)['longitude']),
                      zoom: 14.4746,
                    ),
                    onMapCreated: (GoogleMapController controller) async {
                      setState(() {
                        _controller = controller;
                        _added = true;
                      });
                    },
                  );
                }));
  }

  Future<void> mapMove(AsyncSnapshot<QuerySnapshot> snapshot) async {
    print('done to');
    await _controller
        .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(
          snapshot.data?.docs.singleWhere(
              (element) => element.id == widget.user_id)['latitude'],
          snapshot.data?.docs.singleWhere(
              (element) => element.id == widget.user_id)['longitude']),
      zoom: 14.4746,
    )));
  }
}
