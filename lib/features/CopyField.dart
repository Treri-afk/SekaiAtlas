import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyField extends StatefulWidget {
  final String text;

  const CopyField({super.key, required this.text});

  @override
  State<CopyField> createState() => _CopyFieldState();
}

class _CopyFieldState extends State<CopyField> {

  bool copied = false;

  void copyText() async {

    await Clipboard.setData(
      ClipboardData(text: widget.text),
    );

    setState(() {
      copied = true;
    });

    await Future.delayed(Duration(seconds: 1));

    if (mounted) {
      setState(() {
        copied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return InkWell(
      onTap: copyText,
      borderRadius: BorderRadius.circular(10),

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),

        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),

        child: Row(
          children: [

            Expanded(
              child: Text(
                widget.text,
                style: TextStyle(fontSize: 16),
              ),
            ),

            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: copied
                  ? Icon(Icons.check, key: ValueKey("check"), color: Colors.green)
                  : Icon(Icons.copy, key: ValueKey("copy")),
            )

          ],
        ),
      ),
    );
  }
}