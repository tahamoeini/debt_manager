import 'package:flutter/material.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const DebtManagerApp());
}
