import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mock_mobile/app.dart';
import 'package:mock_mobile/core/offline/offline_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineStorage.init();
  runApp(const ProviderScope(child: MockMobileApp()));
}
