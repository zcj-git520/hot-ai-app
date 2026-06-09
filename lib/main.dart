import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hot_ai_app/app.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final boxes = await openAppBoxes();
  runApp(ProviderScope(
    overrides: [appBoxesProvider.overrideWithValue(boxes)],
    child: const HotAiApp(),
  ));
}
