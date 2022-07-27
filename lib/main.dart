import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'src/locations.dart' as locations;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, Marker> _markers = {};
  // late final GoogleMapController _controller;
  Completer<GoogleMapController> _controller = Completer();

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    // _controller = controller;
    final googleOffices = await locations.getGoogleOffices();
    setState(() {
      _markers.clear();
      for (final office in googleOffices.offices) {
        final marker = Marker(
          markerId: MarkerId(office.name),
          position: LatLng(office.lat, office.lng),
          infoWindow: InfoWindow(
            title: office.name,
            snippet: office.address,
          ),
        );
        _markers[office.name] = marker;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Google Office Locations'),
          backgroundColor: Colors.green[700],
        ),
        body: Column(
          children: [
            Flexible(
                flex: 1,
                child: ListView.separated(
                  separatorBuilder: (BuildContext context, int index) =>  const Divider(
                    indent: 4,
                    color: Colors.white,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _markers.length,
                  itemBuilder: (ctx, index) {
                    return Container(
                      padding: EdgeInsets.only(left: 10),
                      alignment: Alignment.centerLeft,
                      color: Colors.green[700],
                      width: MediaQuery.of(ctx).size.width * 0.9,
                      height: MediaQuery.of(ctx).size.height * 0.1,
                      child: StoreListTile(
                        marker: _markers.values.elementAt(index),
                        mapController: _controller,
                      ),
                    );
                  },
                )),
            Flexible(
              flex: 6,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 50,
                ),
                markers: _markers.values.toSet(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreListTile extends StatefulWidget {
  const StoreListTile({
    Key? key,
    required this.marker,
    required this.mapController,
  }) : super(key: key);

  final Marker marker;
  final Completer<GoogleMapController> mapController;

  @override
  _StoreListTileState createState() => _StoreListTileState();
}

class _StoreListTileState extends State<StoreListTile> {
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.marker.infoWindow.title ?? "", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
      subtitle: Text(widget.marker.infoWindow.snippet?.replaceAll("\n", " ") ?? "" ,style: TextStyle(color: Colors.white,),maxLines: 3,),
      // leading:SizedBox.shrink(),
      onTap: () async {
        final GoogleMapController controller =
            await widget.mapController.future;
        controller
            .animateCamera(CameraUpdate.newLatLng(widget.marker.position));

        /*  await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                widget.marker.position.latitude,
                widget.marker.position.longitude,
              ),
              zoom: 16,
            ),
          ),
        );*/
      },
    );
  }
}
