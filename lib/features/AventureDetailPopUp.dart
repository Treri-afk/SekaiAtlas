import 'package:flutter/material.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class AventureDetailPopup {
  static void show(
    BuildContext context, {
    required Map<String, dynamic> adventure,
    List<dynamic>? players,
    bool showTerminate = false,
    VoidCallback? onTerminated,
  }) {
    debugPrint('🎭 [AventureDetailPopup] show → adventure=${adventure["name"]} id=${adventure["id"]} showTerminate=$showTerminate');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AventureDetailSheet(
        adventure: adventure,
        players: players,
        showTerminate: showTerminate,
        onTerminated: onTerminated,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MODÈLE PHOTO ENRICHI
// ─────────────────────────────────────────────
class _PhotoData {
  final String imageUrl;
  final String? description;
  final String? username;
  final String? avatarUrl;
  final String? poiName;
  final String? badgeName;
  final String? badgeDescription;
  final String? poiRarity;
  final String createdAt;

  const _PhotoData({
    required this.imageUrl,
    this.description,
    this.username,
    this.avatarUrl,
    this.poiName,
    this.badgeName,
    this.badgeDescription,
    this.poiRarity,
    required this.createdAt,
  });

  factory _PhotoData.fromMap(Map<String, dynamic> m) {
    final badgeNameRaw = m['badge_name']?.toString();
    final poiNameRaw   = m['poi_name']?.toString();

    debugPrint('🎭 [_PhotoData.fromMap] id=${m["id"]} '
        'image_url=${m["image_url"]} '
        'username=${m["username"]} '
        'poi_name=$poiNameRaw '
        'badge_name=$badgeNameRaw '
        'poi_rarity=${m["poi_rarity"]} '
        'badge_description=${m["badge_description"]}');

    // On considère qu'un badge/POI est présent seulement si la string n'est pas vide
    final hasBadge = badgeNameRaw != null && badgeNameRaw.isNotEmpty;
    final hasPoi   = poiNameRaw   != null && poiNameRaw.isNotEmpty;

    if (!hasBadge && m['poi_id'] != null) {
      debugPrint('⚠️  [_PhotoData.fromMap] photo id=${m["id"]} a un poi_id=${m["poi_id"]} '
          'mais badge_name est absent/vide — le join POI a peut-être échoué côté API');
    }

    return _PhotoData(
      imageUrl:         m['image_url']?.toString()         ?? '',
      description:      m['description']?.toString(),
      username:         m['username']?.toString(),
      avatarUrl:        m['avatar_url']?.toString(),
      poiName:          hasPoi   ? poiNameRaw   : null,
      badgeName:        hasBadge ? badgeNameRaw : null,
      badgeDescription: m['badge_description']?.toString(),
      poiRarity:        m['poi_rarity']?.toString(),
      createdAt:        m['created_at']?.toString()         ?? '',
    );
  }
}

// ─────────────────────────────────────────────
//  SHEET PRINCIPALE
// ─────────────────────────────────────────────
class _AventureDetailSheet extends StatefulWidget {
  final Map<String, dynamic> adventure;
  final List<dynamic>? players;
  final bool showTerminate;
  final VoidCallback? onTerminated;

  const _AventureDetailSheet({
    required this.adventure,
    this.players,
    this.showTerminate = false,
    this.onTerminated,
  });

  @override
  State<_AventureDetailSheet> createState() => _AventureDetailSheetState();
}

class _AventureDetailSheetState extends State<_AventureDetailSheet> {
  List<_PhotoData> _photos  = [];
  List<dynamic>   _players  = [];
  bool _loadingPhotos  = true;
  bool _loadingPlayers = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🎭 [_AventureDetailSheet] initState → adventure=${widget.adventure["name"]} id=${widget.adventure["id"]}');
    _loadPhotos();
    if (widget.players != null) {
      debugPrint('🎭 [_AventureDetailSheet] players fournis directement : ${widget.players!.length}');
      _players        = List<dynamic>.from(widget.players!);
      _loadingPlayers = false;
    } else {
      debugPrint('🎭 [_AventureDetailSheet] players non fournis → chargement async');
      _loadPlayers();
    }
  }

  Future<void> _loadPlayers() async {
    debugPrint('🎭 [_AventureDetailSheet] _loadPlayers → adventure_id=${widget.adventure["id"]}');
    try {
      final id           = widget.adventure['id'] as int;
      final participants = await fetchAdventureParticipants(id);
      debugPrint('🎭 [_AventureDetailSheet] _loadPlayers → ${participants.length} participant(s) reçu(s)');
      for (final p in participants) {
        debugPrint('🎭 [_AventureDetailSheet]   participant : ${p["username"]} id=${p["id"]}');
      }
      if (!mounted) return;
      setState(() { _players = participants; _loadingPlayers = false; });
    } catch (e, stack) {
      debugPrint('🔴 [_AventureDetailSheet] _loadPlayers erreur : $e');
      debugPrint('🔴 [_AventureDetailSheet] stack : $stack');
      if (!mounted) return;
      setState(() => _loadingPlayers = false);
    }
  }

  Future<void> _loadPhotos() async {
    final id = widget.adventure['id'] as int;
    debugPrint('🎭 [_AventureDetailSheet] _loadPhotos → adventure_id=$id');
    try {
      final raw = await fetchAdventurePhotos(id);
      debugPrint('🎭 [_AventureDetailSheet] _loadPhotos → ${raw.length} photo(s) brute(s)');

      if (!mounted) return;

      int withBadge = 0;
      int withPoi   = 0;
      int noImage   = 0;

      final photos = <_PhotoData>[];
      for (final p in raw) {
        final imageUrl = p['image_url']?.toString() ?? '';
        if (imageUrl.isEmpty) {
          noImage++;
          debugPrint('🎭 [_AventureDetailSheet] photo id=${p["id"]} ignorée (image_url vide)');
          continue;
        }
        final data = _PhotoData.fromMap(Map<String, dynamic>.from(p));
        if (data.badgeName != null) withBadge++;
        if (data.poiName   != null) withPoi++;
        photos.add(data);
      }

      debugPrint('🎭 [_AventureDetailSheet] _loadPhotos ✅ '
          '${photos.length} photos retenues | '
          'ignorées (sans image): $noImage | '
          'avec badge: $withBadge | '
          'avec POI: $withPoi');

      setState(() {
        _photos        = photos;
        _loadingPhotos = false;
      });
    } catch (e, stack) {
      debugPrint('🔴 [_AventureDetailSheet] _loadPhotos erreur : $e');
      debugPrint('🔴 [_AventureDetailSheet] stack : $stack');
      if (!mounted) return;
      setState(() => _loadingPhotos = false);
    }
  }

  // ── Helpers stats ──────────────────────────
  int get _joursActifs {
    try {
      final d = DateTime.parse(widget.adventure['created_at']);
      return DateTime.now().difference(d).inDays + 1;
    } catch (_) { return 0; }
  }

  String get _dateDebut {
    try {
      final d = DateTime.parse(widget.adventure['created_at']);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  int get _lieuxVisites {
    final ids = _photos
        .where((p) => p.poiName != null && p.poiName!.isNotEmpty)
        .map((p) => p.poiName!)
        .toSet();
    debugPrint('🎭 [stats] _lieuxVisites : ${ids.length} lieux distincts');
    return ids.length;
  }

  int get _photosAvecDescription =>
      _photos.where((p) => p.description != null && p.description!.isNotEmpty).length;

  int get _badgesDebloques {
    final badges = _photos
        .where((p) => p.badgeName != null && p.badgeName!.isNotEmpty)
        .map((p) => p.badgeName!)
        .toSet();
    debugPrint('🎭 [stats] _badgesDebloques : ${badges.length}');
    return badges.length;
  }

  String get _dernierePhoto {
    if (_photos.isEmpty) return '—';
    try {
      final d = DateTime.parse(_photos.first.createdAt);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}';
    } catch (_) { return '—'; }
  }

  Color _rarityColor(String? rarity) {
    switch (rarity) {
      case 'legendaire': return const Color(0xFFE8A020);
      case 'rare':       return const Color(0xFF5B8DD9);
      default:           return kTextMid;
    }
  }

  // ── Build ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 4),
            child: Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RpgSectionTitle(label: "Photos de l'aventure", icon: Icons.photo_library_outlined),
                  const SizedBox(height: 12),
                  _buildPhotos(context),
                  const SizedBox(height: 28),
                  const _RpgSectionTitle(label: 'Aventuriers', icon: Icons.shield_outlined),
                  const SizedBox(height: 12),
                  _buildPlayers(),
                  const SizedBox(height: 28),
                  const _RpgSectionTitle(label: 'Statistiques', icon: Icons.bar_chart),
                  const SizedBox(height: 12),
                  _buildStats(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Terminate ──────────────────────────────
  void _showTerminateDialog(BuildContext context) {
    debugPrint('🎭 [_AventureDetailSheet] _showTerminateDialog → ${widget.adventure["name"]}');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _TerminateDialog(
        adventureName: widget.adventure['name'] ?? 'cette aventure',
        onConfirm: () async {
          Navigator.pop(dialogCtx);
          await _terminateAdventure(context);
        },
      ),
    );
  }

  Future<void> _terminateAdventure(BuildContext context) async {
    final id = widget.adventure['id'] as int;
    debugPrint('🎭 [_AventureDetailSheet] _terminateAdventure → id=$id');
    try {
      await terminateAdventure(id);
      debugPrint('🎭 [_AventureDetailSheet] aventure $id terminée ✅');
      if (!mounted) return;
      Navigator.pop(context);
      widget.onTerminated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aventure terminée ✓'), backgroundColor: kSuccess),
      );
    } catch (e, stack) {
      debugPrint('🔴 [_AventureDetailSheet] _terminateAdventure erreur : $e');
      debugPrint('🔴 [_AventureDetailSheet] stack : $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: kError),
      );
    }
  }

  // ── Header ─────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kPrimary.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.local_fire_department, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adventure['name'] ?? 'Aventure',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText),
                ),
                if (widget.adventure['description'] != null &&
                    widget.adventure['description'].toString().isNotEmpty)
                  Text(widget.adventure['description'],
                    style: TextStyle(fontSize: 12, color: kTextMid.withOpacity(0.8)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kPrimary.withOpacity(0.35)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 5, height: 5,
                decoration: const BoxDecoration(color: kPrimary, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('EN COURS',
                style: TextStyle(color: kPrimary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ]),
          ),
          const SizedBox(width: 8),
          if (widget.showTerminate) ...[
            GestureDetector(
              onTap: () => _showTerminateDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kError.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.flag_outlined, color: kError, size: 14),
                  const SizedBox(width: 5),
                  Text('Terminer', style: TextStyle(color: kError, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: kBgCard, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Icon(Icons.close, size: 16, color: kTextMid.withOpacity(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photos ─────────────────────────────────
  Widget _buildPhotos(BuildContext context) {
    debugPrint('🎭 [_buildPhotos] _loadingPhotos=$_loadingPhotos photos=${_photos.length}');

    if (_loadingPhotos) {
      return Container(
        height: 220,
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withOpacity(0.15))),
        child: const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
      );
    }
    if (_photos.isEmpty) {
      return const _RpgEmptyState(label: "Aucune photo postée pour l'instant");
    }

    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.82),
        itemCount: _photos.length,
        onPageChanged: (i) {
          final photo = _photos[i];
          debugPrint('🎭 [_buildPhotos] page $i → badge=${photo.badgeName} poi=${photo.poiName}');
        },
        itemBuilder: (ctx, i) {
          final photo = _photos[i];
          debugPrint('🎭 [_buildPhotos] build item $i → '
              'imageUrl=${photo.imageUrl} '
              'badgeName=${photo.badgeName} '
              'poiRarity=${photo.poiRarity}');

          return GestureDetector(
            onTap: () {
              debugPrint('🎭 [_buildPhotos] tap photo $i → ouverture fullscreen viewer');
              Navigator.of(context).push(PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.black87,
                pageBuilder: (_, __, ___) => _FullScreenViewer(photos: _photos, initialIndex: i),
                transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
              ));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: photo.badgeName != null ? kAccent.withOpacity(0.5) : kPrimary.withOpacity(0.2),
                  width: photo.badgeName != null ? 1.5 : 1,
                ),
                boxShadow: [BoxShadow(
                  color: (photo.badgeName != null ? kAccent : kPrimary).withOpacity(0.12),
                  blurRadius: 10, offset: const Offset(0, 3),
                )],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(photo.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, err, ___) {
                        debugPrint('🔴 [_buildPhotos] erreur image $i : $err url=${photo.imageUrl}');
                        return Container(
                          color: kBgCard2,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: kTextMid, size: 32)),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (photo.badgeName != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _rarityColor(photo.poiRarity).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _rarityColor(photo.poiRarity).withOpacity(0.5)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.star, color: _rarityColor(photo.poiRarity), size: 9),
                                  const SizedBox(width: 4),
                                  Text(photo.badgeName!,
                                    style: TextStyle(
                                      color: _rarityColor(photo.poiRarity),
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (photo.description != null && photo.description!.isNotEmpty)
                              Text(
                                photo.description!,
                                style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (photo.username != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                const Icon(Icons.person_outline, color: Colors.white54, size: 11),
                                const SizedBox(width: 3),
                                Text(photo.username!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Players ────────────────────────────────
  Widget _buildPlayers() {
    debugPrint('🎭 [_buildPlayers] _loadingPlayers=$_loadingPlayers players=${_players.length}');

    if (_loadingPlayers) {
      return Container(
        height: 88,
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withOpacity(0.15))),
        child: const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
      );
    }
    if (_players.isEmpty) {
      return const _RpgEmptyState(label: 'Aucun participant');
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final p   = _players[i];
          final img = p['image'];
          debugPrint('🎭 [_buildPlayers] participant $i : ${p["username"]} avatar=$img');
          return Column(children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary, width: 2),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.18), blurRadius: 8)],
              ),
              child: CircleAvatar(
                radius: 28, backgroundColor: kBgCard2,
                backgroundImage: img != null && img != '' ? NetworkImage(img) : null,
                child: img == null || img == ''
                    ? const Icon(Icons.person, color: kTextMid, size: 22) : null,
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: 64,
              child: Text(p['username'] ?? '',
                textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w600)),
            ),
          ]);
        },
      ),
    );
  }

  // ── Stats ──────────────────────────────────
  Widget _buildStats() {
    final stats = [
      _StatData(icon: Icons.calendar_today_outlined, label: 'Début',        value: _dateDebut),
      _StatData(icon: Icons.bolt_outlined,            label: 'Jours actifs', value: '$_joursActifs j'),
      _StatData(icon: Icons.people_outline,           label: 'Participants', value: '${_players.length}'),
      _StatData(icon: Icons.photo_outlined,           label: 'Photos',       value: '${_photos.length}'),
      _StatData(icon: Icons.place_outlined,           label: 'Lieux visités',value: '$_lieuxVisites'),
      _StatData(icon: Icons.emoji_events_outlined,    label: 'Badges',       value: '$_badgesDebloques'),
      _StatData(icon: Icons.chat_bubble_outline,      label: 'Décrites',     value: '$_photosAvecDescription'),
      _StatData(icon: Icons.photo_camera_outlined,    label: 'Dernière photo',value: _dernierePhoto),
      _StatData(icon: Icons.group_outlined,           label: 'Photos/membre',
        value: _players.isNotEmpty
            ? (_photos.length / _players.length).toStringAsFixed(1)
            : '—'),
    ];

    debugPrint('🎭 [_buildStats] photos=${_photos.length} players=${_players.length} '
        'lieux=$_lieuxVisites badges=$_badgesDebloques described=$_photosAvecDescription');

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.05),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          decoration: BoxDecoration(
            color: kBgCard, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kPrimary.withOpacity(0.18)),
            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(s.icon, color: kPrimary, size: 20),
            const SizedBox(height: 6),
            Text(s.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 2),
            Text(s.label,
              style: const TextStyle(fontSize: 9, color: kTextDim),
              textAlign: TextAlign.center),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
//  TERMINATE DIALOG
// ─────────────────────────────────────────────
class _TerminateDialog extends StatelessWidget {
  final String adventureName;
  final VoidCallback onConfirm;
  const _TerminateDialog({required this.adventureName, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kError.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: kError.withOpacity(0.1), shape: BoxShape.circle,
                border: Border.all(color: kError.withOpacity(0.3)),
              ),
              child: const Icon(Icons.flag, color: kError, size: 26),
            ),
            const SizedBox(height: 16),
            const Text('Terminer l\'aventure ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText)),
            const SizedBox(height: 10),
            Text(
              'Voulez-vous vraiment terminer "$adventureName" ? Cette action est irréversible.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(height: 1, color: kBorder),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: kBgCard, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Center(child: Text('Annuler',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMid))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: kError, borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: kError.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Center(child: Text('Terminer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FULLSCREEN VIEWER avec description + badge
// ─────────────────────────────────────────────
class _FullScreenViewer extends StatefulWidget {
  final List<_PhotoData> photos;
  final int initialIndex;
  const _FullScreenViewer({required this.photos, required this.initialIndex});

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late int _current;
  late PageController _ctrl;
  bool _showInfo = true;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl    = PageController(initialPage: widget.initialIndex);
    debugPrint('🖼️  [_FullScreenViewer] initState → index=$_current / ${widget.photos.length}');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color _rarityColor(String? rarity) {
    switch (rarity) {
      case 'legendaire': return const Color(0xFFE8A020);
      case 'rare':       return const Color(0xFF5B8DD9);
      default:           return kTextMid;
    }
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_current];
    debugPrint('🖼️  [_FullScreenViewer] build → index=$_current '
        'badge=${photo.badgeName} poi=${photo.poiName} rarity=${photo.poiRarity}');

    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => setState(() => _showInfo = !_showInfo),
        child: Stack(
          children: [
            // ── Carrousel photos ──
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.photos.length,
              onPageChanged: (i) {
                setState(() => _current = i);
                final p = widget.photos[i];
                debugPrint('🖼️  [_FullScreenViewer] page changée → $i '
                    'badge=${p.badgeName} poi=${p.poiName}');
              },
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 0.5, maxScale: 4.0,
                child: Center(
                  child: Image.network(widget.photos[i].imageUrl, fit: BoxFit.contain,
                    loadingBuilder: (_, child, p) => p == null ? child
                        : const Center(child: CircularProgressIndicator(color: kPrimary)),
                    errorBuilder: (_, err, ___) {
                      debugPrint('🔴 [_FullScreenViewer] erreur image $i : $err url=${widget.photos[i].imageUrl}');
                      return const Center(child: Icon(Icons.broken_image_outlined, color: kTextMid, size: 48));
                    },
                  ),
                ),
              ),
            ),

            // ── Barre haut ──
            if (_showInfo)
              Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                          child: Text('${_current + 1} / ${widget.photos.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

            // ── Panneau bas : infos photo ──
            if (_showInfo)
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    20, 32, 20, MediaQuery.of(context).padding.bottom + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge POI
                      if (photo.badgeName != null) ...[
                        Builder(builder: (_) {
                          debugPrint('🖼️  [_FullScreenViewer] affichage badge → '
                              'badge=${photo.badgeName} desc=${photo.badgeDescription} '
                              'rarity=${photo.poiRarity}');
                          return const SizedBox.shrink();
                        }),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _rarityColor(photo.poiRarity).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _rarityColor(photo.poiRarity).withOpacity(0.5)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.emoji_events, color: _rarityColor(photo.poiRarity), size: 14),
                            const SizedBox(width: 6),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(photo.badgeName!,
                                style: TextStyle(
                                  color: _rarityColor(photo.poiRarity),
                                  fontSize: 12, fontWeight: FontWeight.w800,
                                )),
                              if (photo.badgeDescription != null)
                                Text(photo.badgeDescription!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 10),
                      ] else ...[
                        Builder(builder: (_) {
                          debugPrint('🖼️  [_FullScreenViewer] ℹ️  pas de badge (poi=${photo.poiName})');
                          return const SizedBox.shrink();
                        }),
                      ],

                      // Nom du POI
                      if (photo.poiName != null) ...[
                        Row(children: [
                          const Icon(Icons.place_outlined, color: Colors.white54, size: 13),
                          const SizedBox(width: 5),
                          Text(photo.poiName!,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                        const SizedBox(height: 6),
                      ],

                      // Description
                      if (photo.description != null && photo.description!.isNotEmpty) ...[
                        Text(
                          photo.description!,
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Auteur + date
                      Row(children: [
                        if (photo.avatarUrl != null && photo.avatarUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(photo.avatarUrl!),
                            backgroundColor: kBgCard2,
                          )
                        else
                          const CircleAvatar(
                            radius: 12, backgroundColor: kBgCard2,
                            child: Icon(Icons.person, size: 12, color: kTextMid),
                          ),
                        const SizedBox(width: 8),
                        Text(photo.username ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(_formatDate(photo.createdAt),
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              ),

            if (!_showInfo)
              const Positioned(
                bottom: 24, left: 0, right: 0,
                child: Center(
                  child: Text('Appuie pour afficher les infos',
                    style: TextStyle(color: Colors.white24, fontSize: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS COMMUNS
// ─────────────────────────────────────────────
class _RpgSectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;
  const _RpgSectionTitle({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kPrimary.withOpacity(0.25))),
        child: Icon(icon, color: kPrimary, size: 15),
      ),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: kText, letterSpacing: 0.3)),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1,
        decoration: BoxDecoration(gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.25), Colors.transparent])))),
    ]);
  }
}

class _RpgEmptyState extends StatelessWidget {
  final String label;
  const _RpgEmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: kBgCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimary.withOpacity(0.15))),
      child: Center(child: Text(label, style: const TextStyle(color: kTextMid, fontSize: 13))),
    );
  }
}

class _StatData {
  final IconData icon;
  final String label, value;
  const _StatData({required this.icon, required this.label, required this.value});
}