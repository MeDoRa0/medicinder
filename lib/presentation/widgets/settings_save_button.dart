import 'package:flutter/material.dart';

class SettingsSaveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  const SettingsSaveButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(text)),
    );
  }
}
