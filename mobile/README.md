# Zenos Mail for Android

Flutter client for the existing Zenos Mail backend. The current build establishes the approved inbox, detail, compose, sent, and settings interface with a dark editorial theme derived from the supplied reference.

## Current state

- Android project builds and installs.
- Inbox search is case-insensitive across sender, recipient, subject, preview, and body.
- Domain filtering supports `zenos.studio` and `alte.codes`.
- Message detail, compose, sent, and settings flows are navigable.
- Production mode authenticates against `https://zenos-mail.vercel.app`, stores its bearer token with Android secure storage, and reads/writes mail through the Vercel API.
- Firebase Cloud Messaging menampilkan push native, termasuk saat aplikasi berada di background. Mengetuk notifikasi membuka detail email yang benar.
- Balas dan teruskan membuka compose yang sudah terisi; tombol refresh dan urutan inbox berfungsi.
- Widget tests use local fixture data so UI and global search can be verified without production credentials.

## Run

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run
```

For a different backend, pass `--dart-define=ZENOS_API_URL=https://example.com`.

## Verify

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build apk --debug
C:\src\flutter\bin\flutter.bat build apk --release
```

Debug APK ditulis ke `build/app/outputs/flutter-apk/app-debug.apk`. Release APK ditulis ke `build/app/outputs/flutter-apk/app-release.apk` dan ditandatangani bila `android/key.properties` tersedia.
