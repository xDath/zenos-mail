# Zenos Mail for Android

Flutter client for the existing Zenos Mail backend. The current build establishes the approved inbox, detail, compose, sent, and settings interface with a dark editorial theme derived from the supplied reference.

## Current state

- Android project builds and installs.
- Inbox search is case-insensitive across sender, recipient, subject, preview, and body.
- Domain filtering supports `zenos.studio` and `alte.codes`.
- Message detail, compose, sent, and settings flows are navigable.
- The inbox currently uses local fixture data while authentication, persistence, and push delivery are connected to the Vercel backend.

## Run

```powershell
C:\src\flutter\bin\flutter.bat pub get
C:\src\flutter\bin\flutter.bat run
```

## Verify

```powershell
C:\src\flutter\bin\flutter.bat analyze
C:\src\flutter\bin\flutter.bat test
C:\src\flutter\bin\flutter.bat build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.
