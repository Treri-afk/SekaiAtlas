import 'package:flutter/material.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

const _cardGradients = [
  [Color(0xFF0A3D1A), Color(0xFF0D5C22)],
  [Color(0xFF0A2A3D), Color(0xFF0D4060)],
  [Color(0xFF2A0A3D), Color(0xFF3D0D5C)],
  [Color(0xFF3D280A), Color(0xFF5C3E0D)],
  [Color(0xFF3D0A1A), Color(0xFF5C0D28)],
];

class ListeAventure extends StatelessWidget {
  final List<dynamic>? adventures;
  const ListeAventure({Key? key, this.adventures}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (adventures == null || adventures!.isEmpty) {
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
            Icon(Icons.map_outlined, color: kTextMid, size: 16),
            SizedBox(width: 8),
            Text(
              'Aucune aventure pour le moment',
              style: TextStyle(color: kTextMid, fontSize: 13),
            ),
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
          final adv  = adventures![i];
          final grad = _cardGradients[i % _cardGradients.length];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 168,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: grad,
                ),
                border: Border.all(color: kEmerald.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: grad[1].withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Motif points
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CustomPaint(painter: _AdventureDotsPainter()),
                    ),
                  ),
                  // Lueur accent
                  Positioned(
                    top: -20, right: -20,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [kCyan.withOpacity(0.1), Colors.transparent],
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: kEmerald.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: kEmerald.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'QUÊTE',
                            style: TextStyle(
                              color: kEmerald, fontSize: 9,
                              fontWeight: FontWeight.w900, letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          adv["name"] ?? 'Sans nom',
                          style: const TextStyle(
                            color: kText, fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_ios,
                                size: 10,
                                color: kCyan.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                color: kCyan.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
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

class _AdventureDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF2ECC71).withOpacity(0.07);
    for (double x = 0; x < size.width; x += 16) {
      for (double y = 0; y < size.height; y += 16) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}