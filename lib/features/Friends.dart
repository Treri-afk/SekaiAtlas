import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/CopyField.dart';
import 'package:sekai_atlas/features/FriendCodeField.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsPopUp {
  static void show(BuildContext rootContext) async {
    final pid = Supabase.instance.client.auth.currentUser?.id;
    if (pid == null) return;
    final u = await fetchUserByProviderId(pid);
    final friendCode = u["friend_code"] ?? 'Aucun code';
    if (!rootContext.mounted) return;

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: rootContext,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: kEmerald.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: kEmerald.withOpacity(0.15)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kEmerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kEmerald.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.people, color: kEmerald, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ALLIANCE',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900,
                        color: kText, letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: kEmerald.withOpacity(0.15)),
                        ),
                        child: Icon(Icons.close, size: 16,
                            color: kTextMid.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AllianceSection(
                      label: 'MON CODE AVENTURIER',
                      icon: Icons.qr_code,
                      child: CopyField(text: friendCode),
                    ),
                    const SizedBox(height: 24),
                    _AllianceSection(
                      label: 'INVITER UN AVENTURIER',
                      icon: Icons.person_search,
                      child: const FriendCodeField(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Nom unique pour éviter tout conflit
class _AllianceSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _AllianceSection({
    required this.label,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: kEmerald),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: kTextDim, letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}