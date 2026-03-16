import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CommencerUneNouvelleAventure.dart';
import 'package:sekai_atlas/features/AventureDetailPopup.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/features/AventureNotifier.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AventureEnCours extends StatefulWidget {
  const AventureEnCours({Key? key}) : super(key: key);

  @override
  State<AventureEnCours> createState() => _AventureEnCoursState();

  static _AventureEnCoursState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AventureEnCoursState>();
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
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut),
    );
    // Se recharge automatiquement quand n'importe quelle page crée/supprime une aventure
    AdventureNotifier.instance.addListener(reload);
    reload();
  }

  @override
  void dispose() {
    AdventureNotifier.instance.removeListener(reload);
    _pulseCtrl?.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    try {
      final pid = Supabase.instance.client.auth.currentUser?.id;
      if (pid == null) throw 'Non connecté';
      final u = await fetchUserByProviderId(pid);
      final f = await fetchFriends(u["id"]);
      final d = await adventureRunning(u["id"]);
      if (!mounted) return;
      setState(() {
        friend    = f;
        users     = d.isNotEmpty ? d[0]["result"]["players"] : [];
        adventure = d.isNotEmpty ? d[0]["result"]["adventure"] : null;
        loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading   = false;
        users     = [];
        friend    = [];
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
          child: CircularProgressIndicator(color: kPrimary, strokeWidth: 2.5),
        ),
      );
    }
    final noAdventure = adventure == null || adventure!["is_running"] == 0;
    return noAdventure ? _buildEmpty() : _buildActive();
  }

  Widget _buildEmpty() {
    return GestureDetector(
      onTap: () => CommencerUneNouvelleAventureForm.show(
        context,
        users: friend,
        // Un seul appel notifie toutes les pages abonnées
        onSuccess: () => AdventureNotifier.instance.notify(),
      ),
      child: Container(
        height: 160,
        decoration: _cardDecor(dashed: true),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pulseAnim != null)
                AnimatedBuilder(
                  animation: _pulseAnim!,
                  builder: (_, __) => Transform.scale(
                    scale: _pulseAnim!.value,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kPrimary.withOpacity(0.1),
                        border: Border.all(color: kPrimary, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: kPrimary.withOpacity(0.2), blurRadius: 16),
                        ],
                      ),
                      child: const Icon(Icons.add, color: kPrimary, size: 26),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'COMMENCER UNE AVENTURE',
                style: TextStyle(
                  color: kPrimary, fontSize: 11,
                  fontWeight: FontWeight.w900, letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Partez à la conquête du monde',
                style: TextStyle(color: kTextMid.withOpacity(0.7), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActive() {
    final playersList = List<dynamic>.from(users ?? []);

    return GestureDetector(
      onTap: () => AventureDetailPopup.show(
        context,
        adventure: Map<String, dynamic>.from(adventure! as Map),
        players: playersList,
        showTerminate: true,
        // La suppression notifie aussi toutes les pages abonnées
        onTerminated: () => AdventureNotifier.instance.notify(),
      ),
      child: Container(
        decoration: _cardDecor(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kPrimary.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'EN COURS',
                        style: TextStyle(
                          color: kPrimary, fontSize: 10,
                          fontWeight: FontWeight.w900, letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimary.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.chevron_right, color: kPrimary, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              adventure?["name"] ?? 'Aventure',
              style: const TextStyle(
                color: kText, fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: 0.3,
              ),
            ),
            if (adventure?["description"] != null) ...[
              const SizedBox(height: 4),
              Text(
                adventure!["description"],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kTextMid.withOpacity(0.8), fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary.withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (users != null && users!.isNotEmpty)
              Row(
                children: [
                  SizedBox(
                    height: 32,
                    width: (users!.length.clamp(0, 5) * 16.0) + 20,
                    child: Stack(
                      children: List.generate(
                        users!.length.clamp(0, 5),
                        (i) => Positioned(
                          left: i * 16.0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kPrimary, width: 2),
                              boxShadow: [
                                BoxShadow(color: kPrimary.withOpacity(0.2), blurRadius: 4),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: kBgCard2,
                              backgroundImage: users![i]["image"] != null &&
                                      users![i]["image"] != ""
                                  ? NetworkImage(users![i]["image"])
                                  : null,
                              child: users![i]["image"] == null || users![i]["image"] == ""
                                  ? const Icon(Icons.person, size: 13, color: kTextMid)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${users!.length} aventurier${users!.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: kTextMid, fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor({bool dashed = false}) {
    return BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: dashed ? kPrimary.withOpacity(0.25) : kPrimary.withOpacity(0.18),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(color: kPrimary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
        BoxShadow(color: kText.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    );
  }
}