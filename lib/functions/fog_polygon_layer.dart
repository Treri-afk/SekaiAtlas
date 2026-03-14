import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../functions/map_functions.dart';

class FogPolygonLayer extends StatefulWidget {
  final List<DistrictPolygon> districts;

  const FogPolygonLayer({super.key, required this.districts});

  @override
  State<FogPolygonLayer> createState() => _FogPolygonLayerState();
}

class _FogPolygonLayerState extends State<FogPolygonLayer>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<Color?> _colorAnim;

  // Polygons précalculés — ne sont reconstruits que si districts change
  List<Polygon> _discoveredPolygons = [];
  List<List<LatLng>> _fogPoints = []; // on stocke juste les points du fog

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _colorAnim = ColorTween(
      begin: const Color(0xFF1A1A1A),
      end: const Color(0xFF3A3A3A),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _buildPolygonCache();
  }

  @override
  void didUpdateWidget(FogPolygonLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalcule seulement si les districts changent
    if (oldWidget.districts != widget.districts) {
      _buildPolygonCache();
    }
  }

  void _buildPolygonCache() {
    _discoveredPolygons = widget.districts
        .where((d) => d.discovered)
        .map((d) => Polygon(
              points: d.points,
              color: Colors.blue.withOpacity(0.3),
              borderColor: Colors.blue,
              borderStrokeWidth: 1.5,
            ))
        .toList();

    _fogPoints = widget.districts
        .where((d) => !d.discovered)
        .map((d) => d.points)
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Reconstruit seulement les polygons fog avec la nouvelle couleur
        final fogPolygons = _fogPoints.map((points) => Polygon(
          points: points,
          color: _colorAnim.value!,
          borderColor: const Color(0xFF111111),
          borderStrokeWidth: 1.0,
        )).toList();

        return Stack(
          children: [
            if (_discoveredPolygons.isNotEmpty)
              PolygonLayer(polygons: _discoveredPolygons),
            if (fogPolygons.isNotEmpty)
              PolygonLayer(polygons: fogPolygons),
          ],
        );
      },
    );
  }
}