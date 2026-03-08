import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../functions/map_functions.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  List<Polygon> _districtPolygons = [];


  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadPolygons();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

 Future<void> _loadPolygons() async {
    final districts = await createPolygonsForPrefecture('13');
    setState(() {
      _districtPolygons = districts;
    });
  }
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(40.8566, 140.3522),
        initialZoom: 5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sekaiatlas.map',
        ),
        PolygonLayer(polygons: _districtPolygons),   // quartiers en dessous
      ],
    );
  }
}