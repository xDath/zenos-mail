import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/sender_profile.dart';

class SenderProfileStore {
  SenderProfileStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'zenos_sender_profiles';
  final FlutterSecureStorage _storage;

  Future<List<SenderProfile>> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return builtInSenderProfiles;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return builtInSenderProfiles;
      final custom = decoded
          .whereType<Map>()
          .map(
            (item) => SenderProfile.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (profile) => profile.name.isNotEmpty && _isEmail(profile.email),
          )
          .where(
            (profile) => !builtInSenderProfiles.any(
              (builtIn) => builtIn.email == profile.email,
            ),
          )
          .toList();
      return [...builtInSenderProfiles, ...custom];
    } catch (_) {
      return builtInSenderProfiles;
    }
  }

  Future<void> save(List<SenderProfile> profiles) async {
    final custom = profiles
        .where((profile) => !profile.isBuiltIn)
        .map((profile) => profile.toJson())
        .toList();
    await _storage.write(key: _storageKey, value: jsonEncode(custom));
  }
}

bool isValidSenderEmail(String value) => _isEmail(value.trim());

bool _isEmail(String value) => RegExp(
  r'^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$',
  caseSensitive: false,
).hasMatch(value);
