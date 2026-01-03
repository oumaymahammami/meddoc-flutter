import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'shared/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Load locale data for date formatting (fixes LocaleDataException)
  await initializeDateFormatting();
  await LocalNotificationService.instance.init();
  await LocalNotificationService.instance.requestPermission();

  runApp(const ProviderScope(child: MedDocApp()));
}
