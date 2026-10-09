import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
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

    expect(find.text('Catatan akhir peluncuran'), findsOneWidget);
    expect(find.text('Anda Purnama'), findsOneWidget);
    expect(find.text('(anda@purnama.id)'), findsOneWidget);
    expect(find.textContaining('/ 0'), findsNothing);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller?.text,
      isEmpty,
    );

    await tester.enterText(find.byType(TextField).first, 'delivery');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(find.text('Monthly delivery report'), findsOneWidget);
    expect(find.text('Catatan akhir peluncuran'), findsNothing);
  });

  testWidgets('compose offers saved and manual sender identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ZenosMailApp(home: MailShell(useDemoData: true)),
    );

    await tester.tap(find.text('Tulis'));
    await tester.pump();

    expect(find.text('Nama pengirim'), findsOneWidget);
    expect(find.text('Alamat pengirim'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('hello@zenos.studio'), findsWidgets);
    expect(find.text('inbox@alte.codes'), findsOneWidget);
    expect(find.text('Masukkan alamat lain…'), findsOneWidget);
  });

  testWidgets('settings exposes sender profiles without section numbers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ZenosMailApp(home: MailShell(useDemoData: true)),
    );

    await tester.tap(find.text('Pengaturan'));
    await tester.pump();

    expect(find.text('hello@zenos.studio'), findsOneWidget);
    expect(find.text('inbox@alte.codes'), findsOneWidget);
    expect(find.text('Tambah profil email'), findsOneWidget);
    expect(find.textContaining('/ 0'), findsNothing);
  });

  testWidgets('HTML email content uses the rich renderer', (tester) async {
    final message = MailMessage(
      id: 'html-message',
      senderName: 'Ana Lucina',
      senderAddress: 'admin@scamy.com',
      recipients: const ['hello@zenos.studio'],
      subject: 'Welcome MotherFather',
      preview: 'aku sayang mamah dan papah',
      body: 'aku sayang mamah dan papah',
      html:
          '<p>aku sayang mamah dan papah</p><img src="data:image/png;base64,iVBORw0KGgo=" />',
      receivedAt: DateTime(2026, 10, 9),
    );
    await tester.pumpWidget(
      ZenosMailApp(home: MessageDetailScreen(message: message)),
    );
    await tester.pump();

    expect(find.byType(HtmlWidget), findsOneWidget);
  });
}
