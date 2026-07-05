import 'package:flutter/material.dart';

class GreenCrewTextField extends StatelessWidget {
  const GreenCrewTextField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.suffixText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? suffixText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
      ),
    );
  }
}
