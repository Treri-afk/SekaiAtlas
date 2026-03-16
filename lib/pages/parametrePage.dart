import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
//  PAGE PARAMÈTRES
// ─────────────────────────────────────────────
class ParametresPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ParametresPage({super.key, required this.user});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  // ── Toggles notifications ──
  bool _notifNouvellePhoto     = true;
  bool _notifNouvelAventurier  = true;
  bool _notifBadge             = true;
  bool _notifAventureTerminee  = false;
  bool _notifRappelAventure    = true;

  // ── Toggles apparence / confidentialité ──
  bool _profilPublic           = true;
  bool _afficherLocalisation   = false;
  bool _afficherBadgesSurCarte = true;

  // ── Code ami affiché ──
  String get _friendCode => widget.user["friend_code"]?.toString() ?? '—';
  String get _username   => widget.user["username"]?.toString()    ?? 'Aventurier';
  String get _avatarUrl  => widget.user["avatar_url"]?.toString()  ?? '';
  String get _email {
    return Supabase.instance.client.auth.currentUser?.email ?? '—';
  }

  void _copyFriendCode() {
    Clipboard.setData(ClipboardData(text: _friendCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Text('Code copié !'),
        ]),
        backgroundColor: kSuccess,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showEditUsernameDialog() {
    final ctrl = TextEditingController(text: _username);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier le pseudo',
                style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: kText),
                decoration: InputDecoration(
                  hintText: 'Nouveau pseudo…',
                  hintStyle: const TextStyle(color: kTextDim),
                  filled: true,
                  fillColor: kBgCard,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kPrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogCtx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kBgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Center(child: Text('Annuler',
                        style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // TODO : appeler API de mise à jour du pseudo
                      Navigator.of(dialogCtx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Pseudo mis à jour'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Center(child: Text('Enregistrer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: kError.withOpacity(0.4), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: kError.withOpacity(0.1), shape: BoxShape.circle,
                  border: Border.all(color: kError.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_forever_outlined, color: kError, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Supprimer le compte ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text('Cette action est définitive. Toutes tes photos, aventures et badges seront supprimés.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMid, fontSize: 13, height: 1.4)),
              const SizedBox(height: 24),
              Container(height: 1, color: kBorder),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogCtx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: kBgCard, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Center(child: Text('Annuler',
                        style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(dialogCtx).pop();
                      // TODO : appel API suppression compte
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: kError, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: kError.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Center(child: Text('Supprimer',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: kBorder, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.1), shape: BoxShape.circle,
                  border: Border.all(color: kPrimary.withOpacity(0.3)),
                ),
                child: const Icon(Icons.logout_outlined, color: kPrimary, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Se déconnecter ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: kText, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text('Tu pourras te reconnecter à tout moment.',
                textAlign: TextAlign.center,
                style: TextStyle(color: kTextMid, fontSize: 13)),
              const SizedBox(height: 24),
              Container(height: 1, color: kBorder),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogCtx).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: kBgCard, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBorder),
                      ),
                      child: const Center(child: Text('Annuler',
                        style: TextStyle(color: kTextMid, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(dialogCtx).pop();
                      await Supabase.instance.client.auth.signOut();
                      if (!mounted) return;
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: kPrimary, borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Center(child: Text('Déconnexion',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegalPage(String title, String content) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _LegalPage(title: title, content: content),
    ));
  }

  // ── BUILD ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: kBg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: kBgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: kBorder),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: kTextMid, size: 16),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Section : Profil ──
                _SectionHeader(label: 'Profil', icon: Icons.person_outline),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.edit_outlined,
                    label: 'Modifier le pseudo',
                    value: _username,
                    onTap: _showEditUsernameDialog,
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.image_outlined,
                    label: 'Changer la photo de profil',
                    onTap: () {
                      // TODO : picker d'image + upload Supabase
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Fonctionnalité bientôt disponible'),
                          backgroundColor: kBgCard2,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.mail_outline,
                    label: 'Adresse e-mail',
                    value: _email,
                    onTap: null,
                    trailing: _LockedBadge(),
                  ),
                ]),

                const SizedBox(height: 8),

                // ── Code ami ──
                _SettingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: kPrimary.withOpacity(0.25)),
                            ),
                            child: const Icon(Icons.tag, color: kPrimary, size: 16),
                          ),
                          const SizedBox(width: 12),
                          const Text('Ton code ami',
                            style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kPrimary.withOpacity(0.25)),
                          ),
                          child: Row(children: [
                            Text(
                              _friendCode,
                              style: const TextStyle(
                                color: kPrimary, fontSize: 20,
                                fontWeight: FontWeight.w900, letterSpacing: 3,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _copyFriendCode,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: kPrimary.withOpacity(0.3)),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.copy_outlined, color: kPrimary, size: 14),
                                  const SizedBox(width: 5),
                                  const Text('Copier',
                                    style: TextStyle(color: kPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Partage ce code à tes amis pour qu\'ils puissent te rejoindre.',
                          style: TextStyle(color: kTextDim, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section : Notifications ──
                _SectionHeader(label: 'Notifications', icon: Icons.notifications_outlined),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsToggle(
                    icon: Icons.photo_outlined,
                    label: 'Nouvelles photos',
                    subtitle: 'Quand un ami poste une photo',
                    value: _notifNouvellePhoto,
                    onChanged: (v) => setState(() => _notifNouvellePhoto = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.person_add_outlined,
                    label: 'Nouvel aventurier',
                    subtitle: 'Quand quelqu\'un rejoint ton aventure',
                    value: _notifNouvelAventurier,
                    onChanged: (v) => setState(() => _notifNouvelAventurier = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.emoji_events_outlined,
                    label: 'Badge débloqué',
                    subtitle: 'Quand tu découvres un nouveau lieu',
                    value: _notifBadge,
                    onChanged: (v) => setState(() => _notifBadge = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.flag_outlined,
                    label: 'Aventure terminée',
                    subtitle: 'Quand une aventure prend fin',
                    value: _notifAventureTerminee,
                    onChanged: (v) => setState(() => _notifAventureTerminee = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.access_time_outlined,
                    label: 'Rappel d\'aventure',
                    subtitle: 'Si aucune photo depuis 48h',
                    value: _notifRappelAventure,
                    onChanged: (v) => setState(() => _notifRappelAventure = v),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section : Confidentialité ──
                _SectionHeader(label: 'Confidentialité', icon: Icons.lock_outline),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsToggle(
                    icon: Icons.public_outlined,
                    label: 'Profil public',
                    subtitle: 'Visible par tous les utilisateurs',
                    value: _profilPublic,
                    onChanged: (v) => setState(() => _profilPublic = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.location_on_outlined,
                    label: 'Afficher ma localisation',
                    subtitle: 'Sur la carte publique',
                    value: _afficherLocalisation,
                    onChanged: (v) => setState(() => _afficherLocalisation = v),
                  ),
                  _SettingsDivider(),
                  _SettingsToggle(
                    icon: Icons.star_outline,
                    label: 'Badges sur la carte',
                    subtitle: 'Afficher les badges sur tes pins',
                    value: _afficherBadgesSurCarte,
                    onChanged: (v) => setState(() => _afficherBadgesSurCarte = v),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section : À propos ──
                _SectionHeader(label: 'À propos', icon: Icons.info_outline),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.shield_outlined,
                    label: 'Politique de confidentialité',
                    onTap: () => _showLegalPage('Politique de confidentialité', _privacyPolicy),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.gavel_outlined,
                    label: 'Conditions d\'utilisation',
                    onTap: () => _showLegalPage('Conditions d\'utilisation', _termsOfService),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.cookie_outlined,
                    label: 'Politique des cookies',
                    onTap: () => _showLegalPage('Politique des cookies', _cookiePolicy),
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.code_outlined,
                    label: 'Licences open source',
                    onTap: () => showLicensePage(context: context, applicationName: 'Sekai Atlas'),
                  ),
                  _SettingsDivider(),
                  _InfoTile(icon: Icons.tag_outlined, label: 'Version',    value: '1.0.0'),
                  _SettingsDivider(),
                  _InfoTile(icon: Icons.build_outlined, label: 'Build',    value: '2025.1'),
                  _SettingsDivider(),
                  _InfoTile(icon: Icons.language_outlined, label: 'Région', value: 'France'),
                ]),

                const SizedBox(height: 24),

                // ── Section : Support ──
                _SectionHeader(label: 'Support', icon: Icons.help_outline),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.bug_report_outlined,
                    label: 'Signaler un bug',
                    onTap: () {
                      // TODO : ouvrir formulaire de rapport
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Merci pour ton retour !'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.star_rate_outlined,
                    label: 'Noter l\'application',
                    onTap: () {
                      // TODO : ouvrir store
                    },
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.mail_outline,
                    label: 'Nous contacter',
                    value: 'contact@sekaiatlas.app',
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'contact@sekaiatlas.app'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Email copié !'),
                          backgroundColor: kSuccess,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section : Compte ──
                _SectionHeader(label: 'Compte', icon: Icons.manage_accounts_outlined),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsTile(
                    icon: Icons.logout_outlined,
                    label: 'Se déconnecter',
                    labelColor: kPrimary,
                    onTap: _showLogoutDialog,
                  ),
                  _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.delete_forever_outlined,
                    label: 'Supprimer mon compte',
                    labelColor: kError,
                    onTap: _showDeleteAccountDialog,
                  ),
                ]),

                const SizedBox(height: 32),

                // ── Footer ──
                Center(
                  child: Column(children: [
                    Text('Sekai Atlas',
                      style: TextStyle(color: kPrimary.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('Fait avec ❤️ — v1.0.0',
                      style: TextStyle(color: kTextDim, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('© 2025 Sekai Atlas. Tous droits réservés.',
                      style: TextStyle(color: kTextDim, fontSize: 10)),
                  ]),
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header profil ──────────────────────────
  Widget _buildProfileHeader() {
    return Container(
      decoration: const BoxDecoration(color: kBg),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -30,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary, width: 2.5),
                        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.25), blurRadius: 14, spreadRadius: 1)],
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: kBgCard2,
                        backgroundImage: _avatarUrl.isNotEmpty ? NetworkImage(_avatarUrl) : null,
                        child: _avatarUrl.isEmpty
                            ? const Icon(Icons.person, color: kTextMid, size: 34) : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2, right: 2,
                      child: GestureDetector(
                        onTap: _showEditUsernameDialog,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: kPrimary, shape: BoxShape.circle,
                            border: Border.all(color: kBg, width: 2),
                            boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 6)],
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900, color: kText, letterSpacing: 0.4),
                      ),
                      const SizedBox(height: 4),
                      Text(_email,
                        style: const TextStyle(color: kTextDim, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimary.withOpacity(0.25)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_outlined, size: 11, color: kPrimary),
                          const SizedBox(width: 5),
                          const Text('Compte vérifié',
                            style: TextStyle(fontSize: 11, color: kPrimary, fontWeight: FontWeight.w600)),
                        ]),
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
//  PAGE LÉGALE
// ─────────────────────────────────────────────
class _LegalPage extends StatelessWidget {
  final String title, content;
  const _LegalPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: kTextMid, size: 16),
            ),
          ),
        ),
        title: Text(title,
          style: const TextStyle(color: kText, fontSize: 15, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kPrimary.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, color: kPrimary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Dernière mise à jour : 1er janvier 2025',
                    style: const TextStyle(color: kPrimary, fontSize: 12)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text(content,
              style: const TextStyle(color: kTextMid, fontSize: 13, height: 1.7)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  WIDGETS INTERNES
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 2),
      child: Row(children: [
        Icon(icon, color: kPrimary, size: 14),
        const SizedBox(width: 7),
        Text(label.toUpperCase(),
          style: const TextStyle(
            color: kPrimary, fontSize: 11,
            fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ]),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(height: 1, color: kBorder.withOpacity(0.6)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color? labelColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.labelColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: (labelColor ?? kPrimary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (labelColor ?? kPrimary).withOpacity(0.2)),
            ),
            child: Icon(icon, color: labelColor ?? kPrimary, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: TextStyle(
                    color: labelColor ?? kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  )),
                if (value != null)
                  Text(value!,
                    style: const TextStyle(color: kTextDim, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (trailing != null) trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right, color: kTextDim.withOpacity(0.5), size: 18),
        ]),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimary.withOpacity(0.2)),
          ),
          child: Icon(icon, color: kPrimary, size: 16),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
              if (subtitle != null)
                Text(subtitle!,
                  style: const TextStyle(color: kTextDim, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: kPrimary,
          activeTrackColor: kPrimary.withOpacity(0.3),
          inactiveThumbColor: kTextDim,
          inactiveTrackColor: kBgCard2,
        ),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kPrimary.withOpacity(0.15)),
          ),
          child: Icon(icon, color: kTextMid, size: 15),
        ),
        const SizedBox(width: 14),
        Text(label,
          style: const TextStyle(color: kText, fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
          style: const TextStyle(color: kTextDim, fontSize: 13)),
      ]),
    );
  }
}

class _LockedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kBgCard2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline, color: kTextDim, size: 11),
        const SizedBox(width: 4),
        const Text('Verrouillé', style: TextStyle(color: kTextDim, fontSize: 10)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  TEXTES LÉGAUX
// ─────────────────────────────────────────────

const String _privacyPolicy = '''
1. INTRODUCTION

Sekai Atlas ("nous", "notre", "l'application") s'engage à protéger la vie privée de ses utilisateurs. Cette politique décrit comment nous collectons, utilisons et partageons vos informations personnelles.

2. DONNÉES COLLECTÉES

Nous collectons les données suivantes :
• Informations de compte : nom d'utilisateur, adresse e-mail, photo de profil
• Données de localisation : coordonnées GPS au moment de la prise de photo (uniquement si vous l'autorisez)
• Contenu utilisateur : photos, descriptions, commentaires publiés dans l'application
• Données d'utilisation : pages visitées, fonctionnalités utilisées, durée des sessions

3. UTILISATION DES DONNÉES

Vos données sont utilisées pour :
• Fournir et améliorer les services de l'application
• Afficher vos photos sur la carte communautaire
• Gérer les aventures et les badges
• Vous envoyer des notifications si vous y avez consenti
• Assurer la sécurité de la plateforme

4. PARTAGE DES DONNÉES

Nous ne vendons jamais vos données personnelles à des tiers. Vos photos et votre pseudo peuvent être visibles par les autres utilisateurs si votre profil est défini comme public.

5. CONSERVATION DES DONNÉES

Vos données sont conservées tant que votre compte est actif. En cas de suppression du compte, vos données sont effacées sous 30 jours.

6. VOS DROITS

Conformément au RGPD, vous disposez des droits suivants :
• Droit d'accès à vos données
• Droit de rectification
• Droit à l'effacement ("droit à l'oubli")
• Droit à la portabilité
• Droit d'opposition

Pour exercer ces droits, contactez-nous à : privacy@sekaiatlas.app

7. SÉCURITÉ

Vos données sont stockées de manière sécurisée via Supabase avec chiffrement en transit (HTTPS/TLS) et au repos.

8. CONTACT

Pour toute question relative à la protection de vos données personnelles, contactez notre délégué à la protection des données à : dpo@sekaiatlas.app
''';

const String _termsOfService = '''
1. ACCEPTATION DES CONDITIONS

En utilisant Sekai Atlas, vous acceptez les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'application.

2. DESCRIPTION DU SERVICE

Sekai Atlas est une application mobile permettant de partager des photos géolocalisées lors d'aventures avec des amis, de découvrir des lieux d'intérêt (POI) et de débloquer des badges.

3. CRÉATION DE COMPTE

Pour utiliser Sekai Atlas, vous devez créer un compte. Vous êtes responsable de la confidentialité de vos identifiants et de toutes les activités effectuées depuis votre compte.

4. CONTENU UTILISATEUR

En publiant du contenu sur Sekai Atlas, vous :
• Garantissez être l'auteur ou détenir les droits sur ce contenu
• Accordez à Sekai Atlas une licence d'utilisation non exclusive pour afficher ce contenu dans l'application
• Acceptez de ne pas publier de contenu illégal, offensant, ou portant atteinte à des tiers

5. COMPORTEMENT INTERDIT

Il est interdit de :
• Harceler, menacer ou intimider d'autres utilisateurs
• Publier du contenu à caractère sexuel, violent ou discriminatoire
• Utiliser l'application à des fins commerciales non autorisées
• Tenter de contourner les mesures de sécurité
• Créer des comptes multiples pour contourner des sanctions

6. SUSPENSION ET RÉSILIATION

Nous nous réservons le droit de suspendre ou supprimer tout compte violant ces conditions, sans préavis ni remboursement.

7. LIMITATION DE RESPONSABILITÉ

Sekai Atlas ne peut être tenu responsable des dommages indirects, accessoires ou consécutifs liés à l'utilisation de l'application.

8. MODIFICATIONS

Ces conditions peuvent être modifiées à tout moment. Les utilisateurs seront informés des modifications importantes par notification dans l'application.

9. DROIT APPLICABLE

Les présentes conditions sont régies par le droit français. Tout litige sera soumis à la juridiction des tribunaux français compétents.
''';

const String _cookiePolicy = '''
1. QU'EST-CE QU'UN COOKIE ?

Un cookie est un petit fichier texte stocké sur votre appareil lors de l'utilisation d'une application ou d'un site web.

2. COOKIES UTILISÉS PAR SEKAI ATLAS

Cookies essentiels (obligatoires) :
• Token d'authentification : maintient votre session active
• Préférences de l'application : thème, langue, paramètres locaux

Cookies analytiques (optionnels) :
• Statistiques d'utilisation anonymisées pour améliorer l'application
• Suivi des fonctionnalités les plus utilisées

3. GESTION DES COOKIES

Les cookies essentiels ne peuvent pas être désactivés car ils sont nécessaires au fonctionnement de l'application.

Les cookies analytiques peuvent être désactivés depuis les paramètres de confidentialité de votre appareil.

4. DURÉE DE CONSERVATION

• Cookies de session : supprimés à la fermeture de l'application
• Token d'authentification : 30 jours (renouvelé automatiquement)
• Préférences : jusqu'à la désinstallation de l'application

5. CONTACT

Pour toute question sur notre utilisation des cookies : cookies@sekaiatlas.app
''';