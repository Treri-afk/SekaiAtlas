import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AventureEnCours extends StatefulWidget {
  const AventureEnCours({Key? key}) : super(key: key);
  @override
  State<AventureEnCours> createState() => _AventureEnCoursState();
}

class _AventureEnCoursState extends State<AventureEnCours>
    with TickerProviderStateMixin {
  List<dynamic>? users, friend;
  Map<String, dynamic>? adventure;
  bool loading = true;

  AnimationController? _pulseCtrl;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
    );
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final pid = Supabase.instance.client.auth.currentUser?.id;
      if (pid == null) throw 'Non connecté';
      final u = await fetchUserByProviderId(pid);
      final f = await fetchFriends(u["id"]);
      final d = await adventureRunning(u["id"]);
      if (!mounted) return;
      setState(() {
        friend = f;
        users = d.isNotEmpty ? d[0]["result"]["players"] : [];
        adventure = d.isNotEmpty ? d[0]["result"]["adventure"] : null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        users = [];
        friend = [];
        adventure = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 160,
        decoration: _cardDecor(),
        child: const Center(
          child: CircularProgressIndicator(color: kEmerald, strokeWidth: 2.5),
        ),
      );
    }
    final noAdventure = adventure == null || adventure!["is_running"] == 0;
    return noAdventure ? _buildEmpty() : _buildActive();
  }

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: () => CommencerUneNouvelleAventureForm.show(context, users: friend),
      child: Container(
        height: 160,
        decoration: _cardDecor(dashed: true),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(painter: _DotsPainter()),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_pulseAnim != null)
                    AnimatedBuilder(
                      animation: _pulseAnim!,
                      builder: (_, __) => Transform.scale(
                        scale: _pulseAnim!.value,
                        child: Container(
                          width: 54, height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kEmerald.withOpacity(0.1),
                            border: Border.all(color: kEmerald, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: kEmerald.withOpacity(0.3),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: kEmerald, size: 26),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Text(
                    'COMMENCER UNE AVENTURE',
                    style: TextStyle(
                      color: kEmerald, fontSize: 11,
                      fontWeight: FontWeight.w900, letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Partez à la conquête du monde',
                    style: TextStyle(color: kTextMid.withOpacity(0.55), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActive() {
    return Container(
      height: 205,
      decoration: _cardDecor(),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Fond dégradé
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A3D1A), Color(0xFF0D2B10), Color(0xFF0A1A0C)],
              ),
            ),
          ),
          // Motif points
          Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
          // Lueur accent coin haut droit
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kCyan.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge statut
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kEmerald.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kEmerald.withOpacity(0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(
                              color: kGlow,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'EN COURS',
                            style: TextStyle(
                              color: kEmerald, fontSize: 10,
                              fontWeight: FontWeight.w900, letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, color: kEmerald.withOpacity(0.4), size: 20),
                  ],
                ),
                const SizedBox(height: 14),
                // Nom aventure
                Text(
                  adventure?["name"] ?? 'Aventure',
                  style: const TextStyle(
                    color: kText, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: 0.3,
                  ),
                ),
                if (adventure?["description"] != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    adventure!["description"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: kTextMid.withOpacity(0.65), fontSize: 13),
                  ),
                ],
                const Spacer(),
                // Participants + XP
                Row(
                  children: [
                    if (users != null && users!.isNotEmpty) ...[
                      SizedBox(
                        height: 30,
                        width: (users!.length.clamp(0, 5) * 22.0) + 8,
                        child: Stack(
                          children: List.generate(
                            users!.length.clamp(0, 5),
                            (i) => Positioned(
                              left: i * 22.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kEmerald, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kEmerald.withOpacity(0.3),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 13,
                                  backgroundColor: kBgCard,
                                  backgroundImage: users![i]["avatar_url"] != null
                                      ? NetworkImage(users![i]["avatar_url"])
                                      : null,
                                  child: users![i]["avatar_url"] == null
                                      ? const Icon(Icons.person, size: 12, color: kTextMid)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${users!.length} aventurier${users!.length > 1 ? 's' : ''}',
                        style: const TextStyle(color: kTextMid, fontSize: 12),
                      ),
                    ],
                    const Spacer(),
                    // Barre XP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('XP',
                          style: TextStyle(color: kTextDim, fontSize: 9,
                            fontWeight: FontWeight.w800, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 72, height: 5,
                          decoration: BoxDecoration(
                            color: kBgCard2,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.6,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  colors: [kEmerald, kCyan],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kEmerald.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecor({bool dashed = false}) {
    return BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: dashed ? kEmerald.withOpacity(0.25) : kEmerald.withOpacity(0.18),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(color: kEmerald.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6)),
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4)),
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2ECC71).withOpacity(0.06);
    for (double x = 0; x < size.width; x += 18) {
      for (double y = 0; y < size.height; y += 18) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}