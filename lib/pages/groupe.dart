import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/AventureEnCours.dart';
import 'package:sekai_atlas/features/Friends.dart';
import 'package:sekai_atlas/features/ListAventure.dart';
import 'package:sekai_atlas/features/ListeAventurier.dart';
import 'package:sekai_atlas/features/AventureNotifier.dart';
import 'package:sekai_atlas/features/FriendNotifier.dart';        // ← nouveau
import 'package:sekai_atlas/pages/parametrePage.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../functions/api_call.dart';

class GroupePage extends StatefulWidget {
  const GroupePage({Key? key}) : super(key: key);
  @override
  State<GroupePage> createState() => _GroupePageState();
}

class _GroupePageState extends State<GroupePage> with TickerProviderStateMixin {
  Map<String, dynamic> actualUser = {};
  List<dynamic> friends    = [];
  List<dynamic> adventures = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 [GroupePage] initState — abonnement AdventureNotifier + FriendNotifier');
    AdventureNotifier.instance.addListener(_load);
    FriendNotifier.instance.addListener(_load);   // ← écoute les ajouts d'amis
    _load();
  }

  @override
  void dispose() {
    debugPrint('🏠 [GroupePage] dispose — désabonnement');
    AdventureNotifier.instance.removeListener(_load);
    FriendNotifier.instance.removeListener(_load); // ← nettoyage
    super.dispose();
  }

  Future<void> _load() async {
    debugPrint('🏠 [GroupePage] _load — début');
    final pid = Supabase.instance.client.auth.currentUser?.id;
    if (pid == null) {
      debugPrint('🔴 [GroupePage] _load — pas d\'utilisateur connecté');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    // 1. Récupère l'utilisateur — bloquant
    Map<String, dynamic> u;
    try {
      u = await fetchUserByProviderId(pid);
      debugPrint('🏠 [GroupePage] user chargé → id=${u["id"]} username=${u["username"]}');
    } catch (e) {
      debugPrint('🔴 [GroupePage] erreur fetchUser : $e');
      if (mounted) setState(() => isLoading = false);
      return;
    }

    // 2. Friends & adventures en parallèle
    debugPrint('🏠 [GroupePage] chargement friends + adventures en parallèle');
    final results = await Future.wait([
      fetchFriends(u["id"]).catchError((e) {
        debugPrint('🔴 [GroupePage] erreur fetchFriends : $e');
        return <dynamic>[];
      }),
      fetchAdventure(u["id"]).catchError((e) {
        debugPrint('🔴 [GroupePage] erreur fetchAdventure : $e');
        return <dynamic>[];
      }),
    ]);

    if (!mounted) return;

    debugPrint('🏠 [GroupePage] _load ✅ — ${results[0].length} ami(s) / ${results[1].length} aventure(s)');
    setState(() {
      actualUser = u;
      friends    = results[0];
      adventures = results[1];
      isLoading  = false;
    });
  }

  void _showBadgesModal(BuildContext context) async {
    final userId = actualUser["id"] as int?;
    if (userId == null) return;
    debugPrint('🏠 [GroupePage] ouverture modal badges userId=$userId');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BadgesModal(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: kPrimary, strokeWidth: 3),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 190,
                  pinned: true,
                  backgroundColor: kBg,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: _GlowButton(
                        icon: Icons.settings_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => ParametresPage(user: actualUser)),
                        ),
                        color: kTextMid,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: _GlowButton(
                        icon: Icons.emoji_events,
                        onTap: () => _showBadgesModal(context),
                        color: kAccent,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 6),
                      child: _GlowButton(
                        icon: Icons.person_add_alt_1,
                        onTap: () => FriendsPopUp.show(context),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(child: const _RpgDivider()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 60),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const _SectionLabel(title: 'Aventure en cours', sub: 'quête active'),
                      const SizedBox(height: 12),
                      const AventureEnCours(),
                      const SizedBox(height: 32),
                      _SectionLabel(title: 'Mes aventures', sub: '${adventures.length} quêtes'),
                      const SizedBox(height: 12),
                      ListeAventure(adventures: adventures),
                      const SizedBox(height: 32),
                      _SectionLabel(title: 'La guilde', sub: '${friends.length} membres'),
                      const SizedBox(height: 12),
                      ListeAventurier(users: friends),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: kBg),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.07), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            right: -10, top: 10,
            child: _GeometricDecor(size: 150, color: kPrimary.withOpacity(0.09)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 72, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimary, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: kBgCard2,
                    backgroundImage: actualUser["avatar_url"] != null &&
                            actualUser["avatar_url"].toString().isNotEmpty
                        ? NetworkImage(actualUser["avatar_url"])
                        : null,
                    child: actualUser["avatar_url"] == null ||
                            actualUser["avatar_url"].toString().isEmpty
                        ? const Icon(Icons.person, color: kTextMid, size: 32)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Builder(builder: (context) {
                        debugPrint('🏠 [GroupePage] header rebuild — username=${actualUser["username"]}');
                        return Text(
                          actualUser["username"]?.toString() ?? 'Aventurier',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: kText,
                            letterSpacing: 0.4,
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimary.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.auto_awesome, size: 11, color: kPrimary),
                            SizedBox(width: 5),
                            Text(
                              'Membre de la guilde',
                              style: TextStyle(
                                fontSize: 11,
                                color: kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        _MiniStat(
                          icon: Icons.shield,
                          value: '${friends.length}',
                          label: 'alliés',
                        ),
                        const SizedBox(width: 8),
                        _MiniStat(
                          icon: Icons.map,
                          value: '${adventures.length}',
                          label: 'quêtes',
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS INTERNES (inchangés)
// ─────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _GlowButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? kPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: c.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title, sub;
  const _SectionLabel({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(
                color: kText, fontSize: 15,
                fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            Text(sub,
              style: const TextStyle(
                color: kTextDim, fontSize: 11, letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.35), Colors.transparent])),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _MiniStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPrimary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kPrimary),
          const SizedBox(width: 4),
          Text('$value $label',
            style: const TextStyle(
              fontSize: 11, color: kTextMid, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RpgDivider extends StatelessWidget {
  const _RpgDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, kPrimary.withOpacity(0.3)])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('✦',
              style: TextStyle(color: kPrimary.withOpacity(0.5), fontSize: 14)),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.3), Colors.transparent])),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeometricDecor extends StatelessWidget {
  final double size;
  final Color color;
  const _GeometricDecor({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size, size),
    painter: _HexPainter(color: color),
  );
}

class _HexPainter extends CustomPainter {
  final Color color;
  const _HexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = size.height / 2;
    for (int r = 1; r <= 3; r++) {
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = (i * 60 - 30) * 3.14159265 / 180;
        final x = cx + r * 22.0 * _cos(angle);
        final y = cy + r * 22.0 * _sin(angle);
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  double _cos(double a) {
    a = a % (2 * 3.14159265);
    double r = 1, t = 1;
    for (int i = 1; i <= 12; i++) {
      t *= -a * a / ((2 * i - 1) * (2 * i));
      r += t;
    }
    return r;
  }

  double _sin(double a) {
    a = a % (2 * 3.14159265);
    double r = a, t = a;
    for (int i = 1; i <= 12; i++) {
      t *= -a * a / ((2 * i) * (2 * i + 1));
      r += t;
    }
    return r;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
//  BADGES MODAL (inchangé)
// ─────────────────────────────────────────────

class _BadgesModal extends StatefulWidget {
  final int userId;
  const _BadgesModal({required this.userId});

  @override
  State<_BadgesModal> createState() => _BadgesModalState();
}

class _BadgesModalState extends State<_BadgesModal> {
  List<dynamic> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    debugPrint('🏅 [_BadgesModal] chargement badges userId=${widget.userId}');
    try {
      final badges = await fetchUserBadges(widget.userId);
      debugPrint('🏅 [_BadgesModal] ${badges.length} badge(s) reçu(s)');
      if (mounted) setState(() { _badges = badges; _loading = false; });
    } catch (e) {
      debugPrint('🔴 [_BadgesModal] erreur : $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _rarityColor(String? rarity) {
    switch (rarity) {
      case 'legendaire': return const Color(0xFFE8A020);
      case 'rare':       return const Color(0xFF5B8DD9);
      default:           return kTextMid;
    }
  }

  String _rarityLabel(String? rarity) {
    switch (rarity) {
      case 'legendaire': return '★ Légendaire';
      case 'rare':       return '◆ Rare';
      default:           return '· Commun';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: kAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccent.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.emoji_events, color: kAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mes badges',
                      style: TextStyle(
                        color: kText, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(
                      '${_badges.length} badge${_badges.length > 1 ? "s" : ""} '
                      'débloqué${_badges.length > 1 ? "s" : ""}',
                      style: const TextStyle(color: kTextDim, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kBorder),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _badges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.explore_off_outlined,
                                color: kTextDim, size: 48),
                            const SizedBox(height: 12),
                            const Text('Aucun badge pour l\'instant',
                              style: TextStyle(color: kTextMid, fontSize: 14)),
                            const SizedBox(height: 6),
                            const Text(
                              'Prends des photos près des POI pour en débloquer !',
                              style: TextStyle(color: kTextDim, fontSize: 12),
                              textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16, 12, 16,
                          MediaQuery.of(context).padding.bottom + 16),
                        itemCount: _badges.length,
                        itemBuilder: (_, i) {
                          final b      = _badges[i];
                          final rarity = b['rarity']?.toString() ?? b['poi_rarity']?.toString();
                          final color  = _rarityColor(rarity);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withOpacity(0.3), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: color.withOpacity(0.4)),
                                  ),
                                  child: Icon(Icons.emoji_events,
                                      color: color, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(
                                            b['badge_name']?.toString() ?? '',
                                            style: const TextStyle(
                                              color: kText,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: color.withOpacity(0.35)),
                                          ),
                                          child: Text(
                                            _rarityLabel(rarity),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ]),
                                      if (b['badge_description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          b['badge_description'].toString(),
                                          style: const TextStyle(
                                            color: kTextMid,
                                            fontSize: 12, height: 1.4)),
                                      ],
                                      const SizedBox(height: 6),
                                      Row(children: [
                                        const Icon(Icons.place_outlined,
                                            color: kTextDim, size: 11),
                                        const SizedBox(width: 4),
                                        Text(
                                          b['name']?.toString() ?? '',
                                          style: const TextStyle(
                                              color: kTextDim, fontSize: 11)),
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}