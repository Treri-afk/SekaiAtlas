import 'package:flutter/material.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendCodeField extends StatefulWidget {
  const FriendCodeField({super.key});

  @override
  State<FriendCodeField> createState() => _FriendCodeFieldState();
}

class _FriendCodeFieldState extends State<FriendCodeField> {

  final TextEditingController controller = TextEditingController();
  bool sent = false;
  bool hasError = false;
  String errorMessage = '';

  void sendCode() async {
    String code = controller.text;
    if (code.isEmpty) return;

    try {
      // Récupère l'utilisateur connecté via Supabase
      final providerId = Supabase.instance.client.auth.currentUser?.id;
      if (providerId == null) throw Exception('Utilisateur non connecté');

      final connectedUser = await fetchUserByProviderId(providerId);
      final userId = connectedUser["id"];

      // Appel API addFriend
      await addFriend(code, userId);

      setState(() {
        sent = true;
        hasError = false;
        errorMessage = '';
      });

      controller.clear();

      await Future.delayed(Duration(seconds: 1));

      if (mounted) {
        setState(() => sent = false);
      }

    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey,
              ),
            ),
            labelText: 'Code ami',
            suffixIcon: IconButton(
              onPressed: sendCode,
              icon: AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: sent
                    ? Icon(Icons.check, key: ValueKey("check"), color: Colors.green)
                    : Icon(Icons.send, key: ValueKey("send")),
              ),
            ),
          ),
        ),

        // Message d'erreur
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}