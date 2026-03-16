import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/AventureEnCours.dart';
import 'package:sekai_atlas/features/Friends.dart';
import 'package:sekai_atlas/features/ListAventure.dart';
import 'package:sekai_atlas/features/ListeAventurier.dart';
import 'package:sekai_atlas/features/AventureNotifier.dart';
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
    // Se recharge automatiquement sur toute création / suppression d'aventure
    AdventureNotifier.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AdventureNotifier.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final pid = Supabase.instance.client.auth.currentUser?.id;
      if (pid == null) throw 'Non connecté';
      final u = await fetchUserByProviderId(pid);
      final f = await fetchFriends(u["id"]);
      final a = await fetchAdventure(u["id"]);
      if (!mounted) return;
      setState(() {
        actualUser = u;
        friends    = f;
        adventures = a;
        isLoading  = false;
      });
    } catch (e) {
      debugPrint('Erreur: $e');
      if (mounted) setState(() => isLoading = false);
    }
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
                      // Plus de callbacks à passer — AventureEnCours écoute
                      // AdventureNotifier directement
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
                    backgroundImage: actualUser["avatar_url"] != null
                        ? NetworkImage(actualUser["avatar_url"])
                        : null,
                    child: actualUser["avatar_url"] == null
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
                      Text(
                        actualUser["username"] ?? 'Aventurier',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kText,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimary.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 11, color: kPrimary),
                            const SizedBox(width: 5),
                            const Text(
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
                      Row(
                        children: [
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
                        ],
                      ),
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
//  WIDGETS INTERNES
// ─────────────────────────────────────────────

class _GlowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
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
            Text(
              title,
              style: const TextStyle(
                color: kText, fontSize: 15,
                fontWeight: FontWeight.w800, letterSpacing: 0.3,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(
                color: kTextDim, fontSize: 11, letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary.withOpacity(0.35), Colors.transparent],
              ),
            ),
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
          Text(
            '$value $label',
            style: const TextStyle(
              fontSize: 11, color: kTextMid, fontWeight: FontWeight.w600,
            ),
          ),
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
                  colors: [Colors.transparent, kPrimary.withOpacity(0.3)],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '✦',
              style: TextStyle(color: kPrimary.withOpacity(0.5), fontSize: 14),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.3), Colors.transparent],
                ),
              ),
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
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HexPainter(color: color),
    );
  }
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