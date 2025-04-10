import 'package:flutter/material.dart';

class PrioritySelector extends StatelessWidget {
  final String? selectedPriorityId;
  final Function(String) onChanged;

  const PrioritySelector({
    Key? key,
    this.selectedPriorityId,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PriorityOption(
            color: Colors.green,
            label: 'Priorité 1',
            isSelected: selectedPriorityId == '1',
            onTap: () => onChanged('1'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PriorityOption(
            color: Colors.orange,
            label: 'Priorité 2',
            isSelected: selectedPriorityId == '2',
            onTap: () => onChanged('2'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PriorityOption(
            color: Colors.red,
            label: 'Priorité 3',
            isSelected: selectedPriorityId == '3',
            onTap: () => onChanged('3'),
          ),
        ),
      ],
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriorityOption({
    Key? key,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}