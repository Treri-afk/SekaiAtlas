import 'package:flutter/material.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class UserPopup {
  static void show(BuildContext context, Map user) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: kEmerald.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 30),
            // Avatar halo
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 128, height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [kEmerald.withOpacity(0.14), Colors.transparent],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kEmerald, kCyan],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kEmerald.withOpacity(0.4),
                        blurRadius: 24,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: kBgCard2,
                    backgroundImage:
                        user["avatar_url"] != null && user["avatar_url"] != ''
                            ? NetworkImage(user["avatar_url"])
                            : null,
                    child: user["avatar_url"] == null || user["avatar_url"] == ''
                        ? const Icon(Icons.person, size: 44, color: kTextMid)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              user["username"] ?? 'Aventurier',
              style: const TextStyle(
                fontSize: 23, fontWeight: FontWeight.w900,
                color: kText, letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: kEmerald.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kEmerald.withOpacity(0.35)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌿', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 6),
                  Text(
                    'Aventurier de la guilde',
                    style: TextStyle(
                      color: kEmerald, fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            // Séparateur
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, kEmerald.withOpacity(0.3)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '✦',
                    style: TextStyle(color: kEmerald.withOpacity(0.5), fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kEmerald.withOpacity(0.3), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PopupBtn(
                    icon: Icons.message_outlined,
                    label: 'Message',
                    onTap: () {},
                    primary: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PopupBtn(
                    icon: Icons.group_add_outlined,
                    label: 'Inviter',
                    onTap: () {},
                    primary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _PopupBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(colors: [kEmerald, kCyan])
              : null,
          color: primary ? null : kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: primary ? null : Border.all(color: kEmerald.withOpacity(0.25)),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: kEmerald.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: primary ? kBg : kTextMid),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: primary ? kBg : kTextMid,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}