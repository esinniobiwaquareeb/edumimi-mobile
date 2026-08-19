import 'package:hive_flutter/hive_flutter.dart';

class OfflineStorage {
  static const practiceBoxName = 'offline_practice_v1';
  static const sessionBoxName = 'exam_sessions_v1';
  static const pendingBoxName = 'pending_submits_v1';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox<Map>(practiceBoxName),
      Hive.openBox<Map>(sessionBoxName),
      Hive.openBox<Map>(pendingBoxName),
    ]);
  }

  static Box<Map> get practiceBox => Hive.box<Map>(practiceBoxName);
  static Box<Map> get sessionBox => Hive.box<Map>(sessionBoxName);
  static Box<Map> get pendingBox => Hive.box<Map>(pendingBoxName);
}
