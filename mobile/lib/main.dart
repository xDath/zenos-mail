import 'package:flutter/material.dart';

import 'screens/mail_shell.dart';
import 'theme/zenos_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZenosMailApp());
}

class ZenosMailApp extends StatelessWidget {
  const ZenosMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zenos Mail',
      debugShowCheckedModeBanner: false,
      theme: buildZenosTheme(),
      home: const MailShell(),
    );
  }
}
