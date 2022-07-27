import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
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
  Completer<GoogleMapController> _controller = Completer();
  var officeList = [];

  Location location = new Location();

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);
    final googleOffices = await locations.getGoogleOffices();

    setState(() {
      _markers.clear();
      officeList = googleOffices.offices;
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
                child: OfficeList(
                    markers: _markers,
                    controller: _controller,
                    googleOffices: officeList)),
            Flexible(
              flex: 6,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(0, 0),
                  zoom: 17,
                ),
                markers: _markers.values.toSet(),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            var position = await fetchLocation();
            final GoogleMapController controller = await _controller.future;
            controller.animateCamera(CameraUpdate.newLatLng(
                LatLng(position.latitude, position.longitude)));

            setState(() {
              _markers["myLocation"] = Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: LatLng(position.latitude, position.longitude));
            });
          },
          label: const Text("Current Location"),
          icon: const Icon(Icons.location_history),
        ),
      ),
    );
  }

  // Future<Position> _determinePosition() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //
  //   if (!serviceEnabled) {
  //     return Future.error('Location services are disabled');
  //   }
  //
  //   permission = await Geolocator.checkPermission();
  //
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //
  //     if (permission == LocationPermission.denied) {
  //       return Future.error("Location permission denied");
  //     }
  //   }
  //
  //   if (permission == LocationPermission.deniedForever) {
  //     return Future.error('Location permissions are permanently denied');
  //   }
  //
  //   Position position = await Geolocator.getCurrentPosition();
  //
  //   return position;
  // }

  fetchLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData _currentPosition = await location.getLocation();
    location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _currentPosition = currentLocation;
        // getAddress(_currentPosition.latitude, _currentPosition.longitude)
        //     .then((value) {
        //   setState(() {
        //     _address = "${value.first.addressLine}";
        //   });
        // });
      });
    });
    return _currentPosition;
  }

  //deprecated
  // getAddress(double lat, double lang) async {
  //   final coordinates = new Coordinates(latitude, longitude);
  //  var address =
  //       await Geocoder.local.findAddressesFromCoordinates(coordinates);
  //   return address;
  // }
  //
}

class OfficeList extends StatelessWidget {
  const OfficeList({
    Key? key,
    required Map<String, Marker> markers,
    required Completer<GoogleMapController> controller,
    googleOffices,
  })  : _markers = markers,
        _controller = controller,
        _googleOffices = googleOffices,
        super(key: key);

  final Map<String, Marker> _markers;
  final Completer<GoogleMapController> _controller;
  final dynamic _googleOffices;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) => const Divider(
        indent: 4,
        color: Colors.white,
      ),
      scrollDirection: Axis.horizontal,
      itemCount: _markers.length,
      itemBuilder: (ctx, index) {
        return Container(
          // padding: EdgeInsets.only(left: 10),
          alignment: Alignment.centerLeft,
          color: Colors.green[700],
          width: MediaQuery.of(ctx).size.width * 0.9,
          height: MediaQuery.of(ctx).size.height * 0.1,
          child: OfficeListTile(
              marker: _markers.values.elementAt(index),
              mapController: _controller,
              office: _googleOffices[index]),
        );
      },
    );
  }
}

class OfficeListTile extends StatefulWidget {
  const OfficeListTile({
    Key? key,
    required this.marker,
    required this.mapController,
    required this.office,
  }) : super(key: key);

  final Marker marker;
  final Completer<GoogleMapController> mapController;
  final office;

  @override
  _OfficeListTileState createState() => _OfficeListTileState();
}

class _OfficeListTileState extends State<OfficeListTile> {
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
      title: Text(
        widget.marker.infoWindow.title ?? "",
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        widget.marker.infoWindow.snippet?.replaceAll("\n", " ") ?? "",
        style: const TextStyle(
          color: Colors.white,
        ),
        maxLines: 3,
      ),
      leading: Container(
        child: widget.office.image.isNotEmpty
            ? CircleAvatar(
                backgroundImage: NetworkImage(widget.office.image),
              )
            : Container(),
        width: 60,
        height: 60,
      ),
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
