import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sekai_atlas/main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final supabase = Supabase.instance.client;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn.instance.initialize(serverClientId: webClientId);
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) throw 'idToken est null';
      final clientAuth = await googleUser.authorizationClient
          .authorizeScopes(['email', 'profile']);
      final accessToken = clientAuth.accessToken;
      if (accessToken == null) throw 'accessToken est null';
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = response.user;
      if (user != null) {
        await createUser(
          user.userMetadata?['full_name'] ?? 'Aventurier',
          user.userMetadata?['avatar_url'] ?? '',
          'google',
          user.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: kError,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // Motif décoratif en fond
          Positioned.fill(child: CustomPaint(painter: _LoginBgPainter())),
          // Lueur centrale
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 340, height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [kPrimary.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icône + titre
                  Center(
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: kBgCard2,
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.map, size: 44, color: kPrimary),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'SekaiAtlas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: kText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explorez le monde, forgez votre légende',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: kTextMid,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Divider doré
                  Row(
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
                  const SizedBox(height: 48),
                  // Bouton Google
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: kPrimary),
                        )
                      : GestureDetector(
                          onTap: _signInWithGoogle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: kBgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: kBorder, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: kText.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                  height: 22, width: 22,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.account_circle, size: 22, color: kTextMid),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Continuer avec Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kText,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Text(
                    'En continuant, vous acceptez nos conditions d\'utilisation',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: kTextDim),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kPrimary.withOpacity(0.05)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}