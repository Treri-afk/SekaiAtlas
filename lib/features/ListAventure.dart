import 'package:flutter/material.dart';
import 'package:sekai_atlas/features/AventureDetailPopup.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class ListeAventure extends StatelessWidget {
  final List<dynamic>? adventures;
  const ListeAventure({Key? key, this.adventures}) : super(key: key);

  static const _accents = [
    kPrimary,
    Color(0xFF8B5E0A),
    Color(0xFFB8780C),
    Color(0xFFA06010),
    Color(0xFF7A4F08),
  ];

  @override
  Widget build(BuildContext context) {
    if (adventures == null || adventures!.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimary.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(color: kText.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, color: kTextMid, size: 16),
            SizedBox(width: 8),
            Text('Aucune aventure pour le moment',
                style: TextStyle(color: kTextMid, fontSize: 13)),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: adventures!.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          // Cast explicite pour satisfaire le type Map<String, dynamic>
          final adv    = Map<String, dynamic>.from(adventures![i] as Map);
          final accent = _accents[i % _accents.length];
          return GestureDetector(
            onTap: () => AventureDetailPopup.show(context, adventure: adv),
            child: Container(
              width: 168,
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 4)),
                  BoxShadow(color: kText.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -10, right: -10,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [accent.withOpacity(0.08), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: accent.withOpacity(0.3)),
                          ),
                          child: Text('QUÊTE',
                            style: TextStyle(color: accent, fontSize: 9,
                                fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                        const Spacer(),
                        Text(
                          adv["name"] ?? 'Sans nom',
                          style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_ios, size: 10, color: accent.withOpacity(0.6)),
                            const SizedBox(width: 4),
                            Text('Voir les détails',
                              style: TextStyle(color: accent.withOpacity(0.7),
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}