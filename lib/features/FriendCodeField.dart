import 'package:flutter/material.dart';

class FriendCodeField extends StatefulWidget {
  const FriendCodeField({super.key});

  @override
  State<FriendCodeField> createState() => _FriendCodeFieldState();
}

class _FriendCodeFieldState extends State<FriendCodeField> {

  final TextEditingController controller = TextEditingController();

  bool sent = false;

  void sendCode() async {

    String code = controller.text;

    if (code.isEmpty) return;

    // ici tu mettras ton appel API plus tard
    print("Code envoyé : $code");

    setState(() {
      sent = true;
    });

    controller.clear();

    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() {
        sent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return TextField(
      controller: controller,

      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Code ami',

        suffixIcon: IconButton(
          onPressed: sendCode,

          icon: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),

            child: sent
                ? Icon(
                    Icons.check,
                    key: ValueKey("check"),
                    color: Colors.green,
                  )
                : Icon(
                    Icons.send,
                    key: ValueKey("send"),
                  ),
          ),
        ),
      ),
    );
  }
}