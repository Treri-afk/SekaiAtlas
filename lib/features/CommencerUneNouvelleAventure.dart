import 'package:flutter/material.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class CommencerUneNouvelleAventureForm {
  static void show(BuildContext context, {required List? users}) {
    final formKey  = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final selected = List<bool>.filled(users?.length ?? 0, false);

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          decoration: const BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _Header(
                onClose: () => Navigator.pop(ctx),
                onValidate: () {
                  if (formKey.currentState!.validate()) Navigator.pop(ctx);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(text: 'NOM DE LA QUÊTE'),
                        const SizedBox(height: 8),
                        _RpgField(
                          ctrl: nameCtrl,
                          hint: 'Ex : La Forêt des Âmes Perdues',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel(text: 'DESCRIPTION'),
                        const SizedBox(height: 8),
                        _RpgField(
                          ctrl: descCtrl,
                          hint: 'Décrivez votre aventure…',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),
                        _FieldLabel(text: 'RECRUTER DES ALLIÉS'),
                        const SizedBox(height: 12),
                        if (users == null || users.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kEmerald.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: kTextDim, size: 16),
                                const SizedBox(width: 10),
                                const Text(
                                  'Aucun allié disponible',
                                  style: TextStyle(color: kTextMid, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: users.length,
                            itemBuilder: (_, i) {
                              final user = users[i];
                              final sel  = selected[i];
                              return GestureDetector(
                                onTap: () => setS(() => selected[i] = !selected[i]),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: sel
                                            ? const LinearGradient(
                                                colors: [kEmerald, kCyan])
                                            : null,
                                        border: sel
                                            ? null
                                            : Border.all(
                                                color: kEmerald.withOpacity(0.2),
                                                width: 2,
                                              ),
                                        boxShadow: sel
                                            ? [
                                                BoxShadow(
                                                  color: kCyan.withOpacity(0.45),
                                                  blurRadius: 14,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: CircleAvatar(
                                        radius: 27,
                                        backgroundColor: kBgCard,
                                        backgroundImage:
                                            user['avatar_url'] != null
                                                ? NetworkImage(user['avatar_url'])
                                                : null,
                                        child: user['avatar_url'] == null
                                            ? const Icon(Icons.person,
                                                color: kTextMid)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      () {
                                        final n = user['username'] ?? '';
                                        return n.length > 8 ? '${n.substring(0, 7)}…' : n;
                                      }(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: sel ? kCyan : kTextMid,
                                        fontWeight: sel
                                            ? FontWeight.w800
                                            : FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (sel)
                                      const Icon(Icons.check_circle,
                                          size: 13, color: kCyan),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets internes ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onClose, onValidate;
  const _Header({required this.onClose, required this.onValidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: kEmerald.withOpacity(0.18))),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: kEmerald.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kEmerald.withOpacity(0.2)),
                  ),
                  child: Icon(Icons.close, size: 18, color: kTextMid.withOpacity(0.7)),
                ),
              ),
              const SizedBox(width: 12),
              Text('✦', style: TextStyle(color: kEmerald, fontSize: 15)),
              const SizedBox(width: 8),
              const Text(
                'NOUVELLE AVENTURE',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900,
                  color: kText, letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onValidate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kEmerald, kCyan]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kEmerald.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text(
                    'CRÉER',
                    style: TextStyle(
                      color: kBg, fontWeight: FontWeight.w900,
                      fontSize: 13, letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kEmerald, kCyan],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: kTextDim, letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RpgField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  const _RpgField({
    required this.ctrl,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: kText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kTextMid.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: kBgCard,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: maxLines > 1 ? 14 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kEmerald, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}