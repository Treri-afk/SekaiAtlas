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
  List<String> _photoUrls = [];
  List<dynamic> _players  = [];
  bool _loadingPhotos  = true;
  bool _loadingPlayers = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    if (widget.players != null) {
      _players         = List<dynamic>.from(widget.players!);
      _loadingPlayers  = false;
    } else {
      _loadPlayers();
    }
  }

  Future<void> _loadPlayers() async {
    try {
      final id           = widget.adventure["id"] as int;
      final participants = await fetchAdventureParticipants(id);
      if (!mounted) return;
      setState(() {
        _players        = participants;
        _loadingPlayers = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPlayers = false);
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final id     = widget.adventure["id"] as int;
      final photos = await fetchAdventurePhotos(id);
      if (!mounted) return;
      setState(() {
        _photoUrls = photos
            .where((p) => p["image_url"] != null && p["image_url"] != "")
            .map<String>((p) => p["image_url"] as String)
            .toList();
        _loadingPhotos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPhotos = false);
    }
  }

  int get _joursActifs {
    try {
      final d = DateTime.parse(widget.adventure["created_at"]);
      return DateTime.now().difference(d).inDays + 1;
    } catch (_) { return 0; }
  }

  String get _dateDebut {
    try {
      final d = DateTime.parse(widget.adventure["created_at"]);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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

  void _showTerminateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _TerminateDialog(
        adventureName: widget.adventure["name"] ?? 'cette aventure',
        onConfirm: () async {
          Navigator.pop(dialogCtx); // ferme le dialog
          await _terminateAdventure(context);
        },
      ),
    );
  }

  Future<void> _terminateAdventure(BuildContext context) async {
    try {
      final id = widget.adventure["id"] as int;
      await terminateAdventure(id);
      if (!mounted) return;
      Navigator.pop(context); // ferme le popup
      widget.onTerminated?.call(); // recharge AventureEnCours
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aventure terminée ✓'),
          backgroundColor: kSuccess,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: kError),
      );
    }
  }

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
                  widget.adventure["name"] ?? 'Aventure',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText),
                ),
                if (widget.adventure["description"] != null &&
                    widget.adventure["description"].toString().isNotEmpty)
                  Text(widget.adventure["description"],
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

  Widget _buildPhotos(BuildContext context) {
    if (_loadingPhotos) {
      return Container(
        height: 100,
        decoration: BoxDecoration(color: kBgCard, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withOpacity(0.15))),
        child: const Center(child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2)),
      );
    }
    if (_photoUrls.isEmpty) {
      return const _RpgEmptyState(label: "Aucune photo postée pour l'instant");
    }
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.75),
        itemCount: _photoUrls.length,
        itemBuilder: (ctx, i) => GestureDetector(
          onTap: () => Navigator.of(context).push(PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (_, __, ___) => _FullScreenViewer(urls: _photoUrls, initialIndex: i),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          )),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kPrimary.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
              image: DecorationImage(image: NetworkImage(_photoUrls[i]), fit: BoxFit.cover),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayers() {
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
          final img = p["image"];
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
              child: Text(p["username"] ?? '',
                textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: kTextMid, fontWeight: FontWeight.w600)),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildStats() {
    final stats = [
      _StatData(icon: Icons.calendar_today_outlined, label: 'Début',       value: _dateDebut),
      _StatData(icon: Icons.bolt_outlined,            label: 'Jours actifs',value: '$_joursActifs j'),
      _StatData(icon: Icons.people_outline,           label: 'Participants',value: '${_players.length}'),
      _StatData(icon: Icons.photo_outlined,           label: 'Photos',      value: '${_photoUrls.length}'),
      _StatData(icon: Icons.place_outlined,           label: 'Lieux',       value: '—'),
      _StatData(icon: Icons.emoji_events_outlined,    label: 'Objectifs',   value: '0 / 3'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.1),
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
            Text(s.label, style: const TextStyle(fontSize: 10, color: kTextDim)),
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
            // Icône
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: kError.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kError.withOpacity(0.3)),
              ),
              child: const Icon(Icons.flag, color: kError, size: 26),
            ),
            const SizedBox(height: 16),
            // Titre
            const Text(
              'Terminer l\'aventure ?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: kText),
            ),
            const SizedBox(height: 10),
            // Message
            Text(
              'Voulez-vous vraiment terminer "$adventureName" ? Cette action est irréversible.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: kTextMid, height: 1.4),
            ),
            const SizedBox(height: 24),
            // Divider
            Container(height: 1, color: kBorder),
            const SizedBox(height: 20),
            // Boutons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: kBgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorder),
                    ),
                    child: const Center(
                      child: Text('Annuler',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kTextMid)),
                    ),
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
                      color: kError,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: kError.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Center(
                      child: Text('Terminer',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
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

class _FullScreenViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullScreenViewer({required this.urls, required this.initialIndex});

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl    = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => InteractiveViewer(
            minScale: 0.5, maxScale: 4.0,
            child: Center(
              child: Image.network(widget.urls[i], fit: BoxFit.contain,
                loadingBuilder: (_, child, p) => p == null ? child
                    : const Center(child: CircularProgressIndicator(color: kPrimary))),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
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
                  child: Text('${_current + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

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