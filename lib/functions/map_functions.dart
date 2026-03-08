import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';


Future<List<Polygon>> createPolygonsForCountry() async {
  final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final allAssets = assetManifest.listAssets();

  // Récupère tous les fichiers geojson des préfectures (exclut custom et prefectures)
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
  // Méthode officielle Flutter pour lister les assets
   final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  
  // Affiche TOUS les assets pour débugger
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
        for (var ring in poly) { // ← boucle sur tous les anneaux
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
      // ← type inconnu
      print("Type ignoré : $type dans $geojsonPath");
    }
  }
  return polygons;
}

Future<String> loadGeojson(String path) async {
  final geojsonString = await rootBundle.loadString(path);
  return geojsonString;
}