import 'package:flutter/material.dart';
import 'package:hot_ai_app/core/theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: CategoryColors.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
