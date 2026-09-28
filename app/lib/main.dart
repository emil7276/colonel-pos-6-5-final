import 'package:flutter/widgets.dart';
import 'app.dart';
import 'data/database.dart';

Future<void> main() async { WidgetsFlutterBinding.ensureInitialized(); await DB.database; runApp(const ColonelApp()); }
