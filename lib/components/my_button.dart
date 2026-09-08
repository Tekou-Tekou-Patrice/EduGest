import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function()? onTap;

  const MyButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}
