import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hot_ai_app/core/storage/hive_init.dart';

void main() {
  test('initHive + openAppBoxes 后能读写', () async {
    final dir = Directory.systemTemp.createTempSync();
    final boxes = await openAppBoxes(path: dir.path);
    addTearDown(() async {
      await boxes.appMeta.clear();
      await boxes.closeAll();
      await dir.delete(recursive: true);
    });
    await boxes.appMeta.put('lang', 'zh');
    expect(boxes.appMeta.get('lang'), 'zh');
  });
}
