import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Modèle pour un district avec son état de découverte
class DistrictPolygon {
  final List<LatLng> points;
  final bool discovered;

  DistrictPolygon({required this.points, this.discovered = false});
}

// ─── NOUVELLES FONCTIONS AVEC DistrictPolygon ───────────────────────────────

Future<List<DistrictPolygon>> createDistrictsForPrefecture(String prefectureCode) async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = assetManifest.listAssets();

  final files = allAssets
      .where((path) => path.startsWith('assets/geojson/$prefectureCode/') && path.endsWith('.json'))
      .toList();

  print("${files.length} fichiers trouvés pour la préfecture $prefectureCode");

  List<DistrictPolygon> allDistricts = [];

  for (String filePath in files) {
    final districts = await createDistrictForFile(filePath);
    allDistricts.addAll(districts);
  }

  return allDistricts;
}

Future<List<DistrictPolygon>> createDistrictForFile(String geojsonPath) async {
  String geojsonString = await loadGeojson(geojsonPath);
  final data = jsonDecode(geojsonString);
  List features = data["features"];
  List<DistrictPolygon> districts = [];

  for (var feature in features) {
    final geometry = feature["geometry"];
    final type = geometry["type"];

    if (type == "Polygon") {
      List coords = geometry["coordinates"][0];
      List<LatLng> points = coords.map<LatLng>((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      )).toList();
      districts.add(DistrictPolygon(points: points));

    } else if (type == "MultiPolygon") {
      for (var poly in geometry["coordinates"]) {
        for (var ring in poly) {
          List<LatLng> points = (ring as List).map<LatLng>((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          )).toList();
          districts.add(DistrictPolygon(points: points));
        }
      }
    } else {
      print("Type ignoré : $type dans $geojsonPath");
    }
  }
  return districts;
}

// ─── ANCIENNES FONCTIONS CONSERVÉES (utilisées ailleurs) ────────────────────

Future<List<Polygon>> createPolygonsAllPrefecture() async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = assetManifest.listAssets();

  final files = allAssets
      .where((path) =>
          path.contains('/prefectures/'))
      .toList();

  print("${files.length} fichiers trouvés pour le pays");

  List<Polygon> allPolygons = [];

  for (String filePath in files) {
    final polygons = await createPolygonForDistrict(filePath);
    allPolygons.addAll(polygons);
  }

  return allPolygons;
}

Future<List<Polygon>> createPolygonsForCountry() async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = assetManifest.listAssets();

  final files = allAssets
      .where((path) =>
          path.startsWith('assets/geojson/') &&
          path.endsWith('.json') &&
          !path.contains('/custom/') &&
          !path.contains('/prefectures/'))
      .toList();

  print("${files.length} fichiers trouvés pour le pays");

  List<Polygon> allPolygons = [];

  for (String filePath in files) {
    final polygons = await createPolygonForDistrict(filePath);
    allPolygons.addAll(polygons);
  }

  return allPolygons;
}

Future<List<Polygon>> createPolygonsForPrefecture(String prefectureCode) async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = assetManifest.listAssets();

  final files = allAssets
      .where((path) => path.startsWith('assets/geojson/$prefectureCode/') && path.endsWith('.json'))
      .toList();

  print("${files.length} fichiers trouvés pour la préfecture $prefectureCode");

  List<Polygon> allPolygons = [];

  for (String filePath in files) {
    final polygons = await createPolygonForDistrict(filePath);
    allPolygons.addAll(polygons);
  }

  return allPolygons;
}

Future<List<Polygon>> createPolygonForDistrict(String geojsonPath) async {
  String geojsonString = await loadGeojson(geojsonPath);
  final data = jsonDecode(geojsonString);
  List features = data["features"];
  List<Polygon> polygons = [];

  for (var feature in features) {
    final geometry = feature["geometry"];
    final type = geometry["type"];

    if (type == "Polygon") {
      List coords = geometry["coordinates"][0];
      List<LatLng> points = coords.map<LatLng>((c) => LatLng(
        (c[1] as num).toDouble(),
        (c[0] as num).toDouble(),
      )).toList();
      polygons.add(Polygon(
        points: points,
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 1.5,
      ));

    } else if (type == "MultiPolygon") {
      for (var poly in geometry["coordinates"]) {
        for (var ring in poly) {
          List coords = ring;
          List<LatLng> points = coords.map<LatLng>((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          )).toList();
          polygons.add(Polygon(
            points: points,
            color: Colors.blue.withOpacity(0.3),
            borderColor: Colors.blue,
            borderStrokeWidth: 1.5,
          ));
        }
      }
    } else {
      print("Type ignoré : $type dans $geojsonPath");
    }
  }
  return polygons;
}

// ─── UTILITAIRE ─────────────────────────────────────────────────────────────

Future<String> loadGeojson(String path) async {
  final geojsonString = await rootBundle.loadString(path);
  return geojsonString;
}