import 'package:flutter/material.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
}
