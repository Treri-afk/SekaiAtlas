import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import '../functions/map_functions.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final MapController _mapController;
  List<_PhotoMarker> _photoMarkers = [];
  bool _loadingPhotos = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadPhotos();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() => _loadingPhotos = true);
    try {
      final photos = await fetchAllPhotos();
      debugPrint('[map] ${photos.length} photos récupérées');
      final markers = photos
          .where((p) {
            final lat = double.tryParse(p["latitude"]?.toString() ?? '');
            final lng = double.tryParse(p["longitude"]?.toString() ?? '');
            return lat != null && lng != null;
          })
          .map((p) => _PhotoMarker(
                lat:              double.parse(p["latitude"].toString()),
                lng:              double.parse(p["longitude"].toString()),
                imageUrl:         p["image_url"]?.toString()       ?? '',
                username:         p["username"]?.toString()        ?? '',
                adventureName:    p["adventure_name"]?.toString()  ?? '',
                createdAt:        p["created_at"]?.toString()      ?? '',
                caption:          p["description"]?.toString()     ?? '',
                badgeName:        p["badge_name"]?.toString(),
                badgeDescription: p["badge_description"]?.toString(),
                poiName:          p["poi_name"]?.toString(),
                poiRarity:        p["poi_rarity"]?.toString(),
              ))
          .toList();
      debugPrint('[map] ${markers.length} photos avec coordonnées');
      if (mounted) setState(() => _photoMarkers = markers);
    } catch (e) {
      debugPrint('[map] erreur chargement photos : $e');
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'legendaire': return const Color(0xFFE8A020);
      case 'rare':       return const Color(0xFF5B8DD9);
      default:           return kTextMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(35.6762, 139.6503),
              initialZoom: 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sekaiatlas.map',
              ),
              MarkerLayer(
                markers: _photoMarkers.map((m) => Marker(
                  point: LatLng(m.lat, m.lng),
                  width: 52,
                  height: 62,
                  child: GestureDetector(
                    onTap: () => _showPhotoPopup(context, m),
                    child: _PhotoPin(
                      imageUrl: m.imageUrl,
                      hasBadge: m.badgeName != null,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),

          if (_loadingPhotos)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kBorder),
                    boxShadow: [BoxShadow(color: kText.withOpacity(0.08), blurRadius: 8)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
                    const SizedBox(width: 8),
                    const Text('Chargement des photos…',
                      style: TextStyle(color: kTextMid, fontSize: 12)),
                  ]),
                ),
              ),
            ),

          if (!_loadingPhotos && _photoMarkers.isNotEmpty)
            Positioned(
              top: 56, left: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimary.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.1), blurRadius: 8)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.photo_library_outlined, color: kPrimary, size: 14),
                    const SizedBox(width: 6),
                    Text('${_photoMarkers.length} photo${_photoMarkers.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),

          Positioned(
            right: 16, bottom: 32,
            child: Column(
              children: [
                _MapButton(icon: Icons.refresh, onTap: _loadPhotos),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.add,
                  onTap: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom + 1)),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.remove,
                  onTap: () => _mapController.move(
                    _mapController.camera.center, _mapController.camera.zoom - 1)),
                const SizedBox(height: 8),
                _MapButton(icon: Icons.my_location,
                  onTap: () => _mapController.move(const LatLng(35.6762, 139.6503), 5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoPopup(BuildContext context, _PhotoMarker m) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 8, 20,
                    MediaQuery.of(context).padding.bottom + 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Badge / profil ───────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimary.withOpacity(0.18)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: kPrimary.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.emoji_events_outlined, color: kPrimary, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.username,
                              style: const TextStyle(color: kText, fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                            const Text('Aventurier',
                              style: TextStyle(color: kTextDim, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kPrimary.withOpacity(0.25)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.local_fire_department, color: kPrimary, size: 12),
                            const SizedBox(width: 4),
                            Flexible(child: Text(m.adventureName,
                              style: const TextStyle(color: kPrimary, fontSize: 11,
                                  fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── Photo cliquable ──────────────────
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black87,
                        pageBuilder: (_, __, ___) => _FullScreenPhoto(imageUrl: m.imageUrl),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      )),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              m.imageUrl,
                              height: 500,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 280, color: kBgCard2,
                                child: const Center(child: Icon(
                                    Icons.broken_image_outlined, color: kTextMid, size: 40)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10, right: 10,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Description ──────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPrimary.withOpacity(0.15)),
                      ),
                      child: m.caption.isNotEmpty
                          ? Text(
                              m.caption,
                              style: const TextStyle(
                                color: kText, fontSize: 14, height: 1.5),
                            )
                          : Row(children: [
                              const Icon(Icons.edit_off_outlined, color: kTextDim, size: 14),
                              const SizedBox(width: 8),
                              const Text('Aucune description',
                                style: TextStyle(color: kTextDim, fontSize: 13,
                                    fontStyle: FontStyle.italic)),
                            ]),
                    ),
                    const SizedBox(height: 12),

                    // ── Badge POI ────────────────────────────────
                    if (m.badgeName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kAccent.withOpacity(0.35), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: kAccent.withOpacity(0.15),
                                border: Border.all(color: kAccent.withOpacity(0.4)),
                              ),
                              child: const Icon(Icons.emoji_events, color: kAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.star, color: kAccent, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      m.badgeName!,
                                      style: const TextStyle(
                                        color: kText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (m.poiRarity != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _rarityColor(m.poiRarity!).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: _rarityColor(m.poiRarity!).withOpacity(0.4)),
                                        ),
                                        child: Text(
                                          m.poiRarity!,
                                          style: TextStyle(
                                            color: _rarityColor(m.poiRarity!),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ]),
                                  if (m.badgeDescription != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      m.badgeDescription!,
                                      style: const TextStyle(color: kTextMid, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Coordonnées ──────────────────────
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.place_outlined, color: kTextDim, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'lat: ${m.lat.toStringAsFixed(5)}, lng: ${m.lng.toStringAsFixed(5)}',
                        style: const TextStyle(color: kTextDim, fontSize: 11),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MODÈLE
// ─────────────────────────────────────────────
class _PhotoMarker {
  final double lat, lng;
  final String imageUrl, username, adventureName, createdAt, caption;
  final String? badgeName, badgeDescription, poiName, poiRarity;

  const _PhotoMarker({
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.username,
    required this.adventureName,
    required this.createdAt,
    this.caption = '',
    this.badgeName,
    this.badgeDescription,
    this.poiName,
    this.poiRarity,
  });
}

// ─────────────────────────────────────────────
//  PIN PHOTO
// ─────────────────────────────────────────────
class _PhotoPin extends StatelessWidget {
  final String imageUrl;
  final bool hasBadge;
  const _PhotoPin({required this.imageUrl, this.hasBadge = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasBadge ? kAccent : kPrimary,
                  width: hasBadge ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (hasBadge ? kAccent : kPrimary).withOpacity(0.35),
                    blurRadius: 8, offset: const Offset(0, 3),
                  ),
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                ],
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: kBgCard2,
                          child: const Icon(Icons.photo_outlined, color: kPrimary, size: 20),
                        ))
                    : Container(color: kBgCard2,
                        child: const Icon(Icons.photo_outlined, color: kPrimary, size: 20)),
              ),
            ),
            CustomPaint(
              size: const Size(10, 8),
              painter: _PinTipPainter(color: hasBadge ? kAccent : kPrimary),
            ),
          ],
        ),
        // Icône badge en haut à droite du pin, légèrement superposé
        if (hasBadge)
          Positioned(
            top: -4, right: 10,
            child: Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                color: kAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [BoxShadow(color: kAccent.withOpacity(0.4), blurRadius: 6)],
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  FULL SCREEN PHOTO
// ─────────────────────────────────────────────
class _FullScreenPhoto extends StatelessWidget {
  final String imageUrl;
  const _FullScreenPhoto({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null
                    ? child
                    : const Center(child: CircularProgressIndicator(color: kPrimary)),
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PIN TIP
// ─────────────────────────────────────────────
class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({this.color = kPrimary});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
//  BOUTON CARTE
// ─────────────────────────────────────────────
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kBorder),
          boxShadow: [BoxShadow(color: kText.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: kPrimary, size: 22),
      ),
    );
  }
}