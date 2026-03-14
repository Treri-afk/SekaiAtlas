import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sekai_atlas/theme/rpg_theme.dart';

class CopyField extends StatefulWidget {
  final String text;
  const CopyField({super.key, required this.text});
  @override
  State<CopyField> createState() => _CopyFieldState();
}

class _CopyFieldState extends State<CopyField>
    with SingleTickerProviderStateMixin {
  bool _copied = false;
  AnimationController? _ctrl;
  Animation<double>? _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(_ctrl!);
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    _ctrl?.forward().then((_) => _ctrl?.reverse());
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim ?? const AlwaysStoppedAnimation(1.0),
      child: GestureDetector(
        onTap: _copy,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _copied ? kEmerald.withOpacity(0.1) : kBgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _copied ? kCyan : kEmerald.withOpacity(0.25),
              width: _copied ? 1.5 : 1,
            ),
            boxShadow: _copied
                ? [BoxShadow(color: kEmerald.withOpacity(0.18), blurRadius: 12)]
                : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _copied ? kCyan : kText,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _copied
                    ? const Icon(Icons.check_circle,
                        key: ValueKey('c'), color: kCyan, size: 20)
                    : Icon(Icons.copy_all,
                        key: const ValueKey('x'),
                        color: kEmerald.withOpacity(0.7),
                        size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}