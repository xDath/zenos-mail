import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenos_mail/main.dart';
import 'package:zenos_mail/models/mail_message.dart';
import 'package:zenos_mail/screens/mail_shell.dart';

void main() {
  test('global search covers sender, recipient, subject, and body', () {
    final message = demoInbox.first;

    expect(message.matches('Purnama'), isTrue);
    expect(message.matches('hello@zenos.studio'), isTrue);
    expect(message.matches('peluncuran'), isTrue);
    expect(message.matches('periksa versi'), isTrue);
    expect(message.matches('tidak ada'), isFalse);
  });

  testWidgets('inbox filters using one search field', (tester) async {
    await tester.pumpWidget(
      const ZenosMailApp(home: MailShell(useDemoData: true)),
    );

    expect(find.text('Kotak masuk'), findsOneWidget);
    expect(find.text('Catatan akhir peluncuran'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'delivery');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Monthly delivery report'), findsOneWidget);
    expect(find.text('Catatan akhir peluncuran'), findsNothing);
  });
}
