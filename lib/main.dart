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
              child: PageView.builder(
                  controller: PageController(viewportFraction: 0.8),
                  scrollDirection: Axis.horizontal,
                  itemCount: _markers.length,
                  // onPageChanged: (index) {
                  // },
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        SingleChildScrollView(
                          child: InkWell(
                            onTap: () async {
                              // await _controller.animateCamera(
                              //     CameraUpdate.newLatLng(
                              //         _markers.values.elementAt(index).position));
                              //

                              final GoogleMapController controller =
                                  await _controller.future;
                              controller.animateCamera(CameraUpdate.newLatLng(
                                  _markers.values.elementAt(index).position));
                            },
                            child: Container(
                              color: Colors.green[700],
                              width: MediaQuery.of(context).size.width - 87,
                              height: MediaQuery.of(context).size.height * 0.1,
                              child: Center(
                                child: Text(
                                  _markers.values
                                      .elementAt(index)
                                      .infoWindow
                                      .title
                                      .toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  }),
            ),
            Flexible(
              flex: 7,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 30,
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
