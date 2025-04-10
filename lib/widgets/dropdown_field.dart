import 'package:flutter/material.dart';

class DropdownField extends StatelessWidget {
  final List<DropdownMenuItem> items;
  final String hint;
  final dynamic value;
  final Function(dynamic) onChanged;
  final Widget icon;
  final String? Function(dynamic)? validator;

  const DropdownField({
    Key? key,
    required this.items,
    required this.hint,
    this.value,
    required this.onChanged,
    required this.icon,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: icon,
        ),
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      items: items,
      value: value,
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.arrow_drop_down),
      isExpanded: true,
      dropdownColor: Colors.white,
    );
  }
}