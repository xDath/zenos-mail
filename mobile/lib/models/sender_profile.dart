class SenderProfile {
  const SenderProfile({
    required this.name,
    required this.email,
    this.isBuiltIn = false,
  });

  final String name;
  final String email;
  final bool isBuiltIn;

  Map<String, dynamic> toJson() => {'name': name, 'email': email};

  factory SenderProfile.fromJson(Map<String, dynamic> json) => SenderProfile(
    name: (json['name'] ?? '').toString().trim(),
    email: (json['email'] ?? '').toString().trim().toLowerCase(),
  );
}

const builtInSenderProfiles = <SenderProfile>[
  SenderProfile(
    name: 'Zenos Studio',
    email: 'hello@zenos.studio',
    isBuiltIn: true,
  ),
  SenderProfile(name: 'Alte Codes', email: 'inbox@alte.codes', isBuiltIn: true),
];
