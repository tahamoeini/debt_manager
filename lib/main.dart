import 'package:flutter/material.dart';
import 'app.dart';
import 'core/db/database_helper.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.refreshOverdueInstallments(DateTime.now());
  await NotificationService().init();
  runApp(const DebtManagerApp());
}
