import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/UserPopup.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class ListeAventurier extends StatelessWidget {
  final List<dynamic>? users;
  const ListeAventurier({Key? key, this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (users == null || users!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kEmerald.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: kTextMid, size: 16),
            SizedBox(width: 8),
            Text(
              'Aucun aventurier pour le moment',
              style: TextStyle(color: kTextMid, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final user = users![i];
          return GestureDetector(
            onTap: () => UserPopup.show(context, user),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kEmerald, kCyan],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kEmerald.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      color: kBgCard2,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: kBgCard2,
                      backgroundImage:
                          user["avatar_url"] != null && user["avatar_url"] != ''
                              ? NetworkImage(user["avatar_url"])
                              : null,
                      child:
                          user["avatar_url"] == null || user["avatar_url"] == ''
                              ? const Icon(Icons.person,
                                  color: kTextMid, size: 24)
                              : null,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 68,
                  child: Text(
                    user["username"] ?? '',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: kTextMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}