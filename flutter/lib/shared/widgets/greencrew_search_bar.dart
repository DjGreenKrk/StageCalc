import 'package:flutter/material.dart';

class GreenCrewSearchBar extends StatelessWidget {
  const GreenCrewSearchBar({required this.hintText, super.key, this.onChanged});

  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
      ),
    );
  }
}
