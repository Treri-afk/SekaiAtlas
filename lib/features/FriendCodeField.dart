import 'package:flutter/material.dart';
import 'package:sekai_atlas/functions/api_call.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendCodeField extends StatefulWidget {
  const FriendCodeField({super.key});
  @override
  State<FriendCodeField> createState() => _FriendCodeFieldState();
}

class _FriendCodeFieldState extends State<FriendCodeField> {
  final _ctrl = TextEditingController();
  bool _sent = false, _loading = false, _hasError = false;
  String _errMsg = '';

  Future<void> _send() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _loading = true; _hasError = false; });
    try {
      final pid = Supabase.instance.client.auth.currentUser?.id;
      if (pid == null) throw Exception('Non connecté');
      final u = await fetchUserByProviderId(pid);
      await addFriend(code, u["id"]);
      if (!mounted) return;
      setState(() { _sent = true; _loading = false; });
      _ctrl.clear();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _sent = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
        _errMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasError
                  ? Colors.red.withOpacity(0.5)
                  : kEmerald.withOpacity(0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(
                    color: kText, fontSize: 14, letterSpacing: 0.5,
                  ),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Code aventurier…',
                    hintStyle:
                        TextStyle(color: kTextMid.withOpacity(0.4)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _loading ? null : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46, height: 46,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _sent
                          ? [Colors.green, const Color(0xFF00C853)]
                          : [kEmerald, kCyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (_sent ? Colors.green : kEmerald)
                            .withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            color: kBg, strokeWidth: 2,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _sent
                              ? const Icon(Icons.check,
                                  key: ValueKey('c'),
                                  color: kBg, size: 20)
                              : const Icon(Icons.send,
                                  key: ValueKey('s'),
                                  color: kBg, size: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 12, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _errMsg,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}