import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
      await GoogleSignIn.instance.initialize(
        serverClientId: webClientId,
      );

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
          user.userMetadata?['full_name'] ?? 'Utilisateur',  // username
          user.userMetadata?['avatar_url'] ?? '',             // avatar_url
          'google',                                           // provider
          user.id,                                            // provider_id
        );
      }

      // Déconnexion immédiate pour désactiver la reconnexion automatique
      // TODO : supprime ces deux lignes quand tu veux activer la reconnexion
      //await GoogleSignIn.instance.signOut();
      //await supabase.auth.signOut();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.map,
                size: 80,
                color: Color.fromARGB(255, 23, 252, 164),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bienvenue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 48),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.network(
                        'https://developers.google.com/identity/images/g-logo.png',
                        height: 24,
                        width: 24,
                      ),
                      label: const Text(
                        'Continuer avec Google',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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