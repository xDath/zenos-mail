class MailMessage {
  const MailMessage({
    required this.id,
    required this.senderName,
    required this.senderAddress,
    required this.recipients,
    required this.subject,
    required this.preview,
    required this.body,
    this.html = '',
    required this.receivedAt,
    this.isUnread = false,
    this.hasAttachment = false,
  });

  final String id;
  final String senderName;
  final String senderAddress;
  final List<String> recipients;
  final String subject;
  final String preview;
  final String body;
  final String html;
  final DateTime receivedAt;
  final bool isUnread;
  final bool hasAttachment;

  factory MailMessage.fromJson(Map<String, dynamic> json) {
    final from = (json['from'] ?? '').toString();
    final parsedSender = _parseSender(from);
    final text = (json['text'] ?? json['body'] ?? '').toString();
    final preview = (json['preview'] ?? '').toString();
    final attachments = json['attachments'];
    return MailMessage(
      id: (json['id'] ?? '').toString(),
      senderName: parsedSender.$1,
      senderAddress: parsedSender.$2,
      recipients: _stringList(json['to']),
      subject: (json['subject'] ?? '(tanpa subjek)').toString(),
      preview: preview.isNotEmpty ? preview : _makePreview(text),
      body: text,
      html: (json['html'] ?? '').toString(),
      receivedAt:
          DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      isUnread: json['is_read'] != true,
      hasAttachment: attachments is List && attachments.isNotEmpty,
    );
  }

  bool matches(String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return [
      senderName,
      senderAddress,
      ...recipients,
      subject,
      preview,
      body,
    ].any((value) => value.toLowerCase().contains(query));
  }

  bool belongsTo(String domain) {
    if (domain == 'all') return true;
    return recipients.any(
      (address) => address.toLowerCase().endsWith('@${domain.toLowerCase()}'),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.isNotEmpty) return [value];
  return const [];
}

(String, String) _parseSender(String value) {
  final match = RegExp(r'^\s*(.*?)\s*<([^>]+)>\s*$').firstMatch(value);
  if (match != null) {
    final address = match.group(2) ?? value;
    final name = (match.group(1) ?? '').replaceAll('"', '').trim();
    return (name.isEmpty ? address.split('@').first : name, address);
  }
  return (value.contains('@') ? value.split('@').first : value, value);
}

String _makePreview(String value) {
  final normalized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.length <= 180) return normalized;
  return '${normalized.substring(0, 177)}…';
}

final demoInbox = <MailMessage>[
  MailMessage(
    id: 'mail-001',
    senderName: 'Anda Purnama',
    senderAddress: 'anda@purnama.id',
    recipients: const ['hello@zenos.studio'],
    subject: 'Catatan akhir peluncuran',
    preview: 'Daftar perubahan sudah siap untuk tim studio.',
    body:
        'Halo,\n\nDaftar perubahan sudah siap untuk tim studio. '
        'Silakan periksa versi terakhir sebelum peluncuran.\n\nTerima kasih,\nAnda',
    receivedAt: DateTime(2026, 10, 8, 10, 42),
    isUnread: true,
  ),
  MailMessage(
    id: 'mail-002',
    senderName: 'Mira Santoso',
    senderAddress: 'mira@studio-karsa.com',
    recipients: const ['inbox@alte.codes'],
    subject: 'Referensi visual Andalusia',
    preview: 'Palet arsitektur dan ritme halaman ada di lampiran.',
    body:
        'Palet arsitektur dan ritme halaman Andalusia ada di lampiran. '
        'Materinya bisa menjadi referensi untuk presentasi pekan depan.',
    receivedAt: DateTime(2026, 10, 7, 17, 18),
    hasAttachment: true,
  ),
  MailMessage(
    id: 'mail-003',
    senderName: 'Studio Karsa',
    senderAddress: 'project@studiokarsa.co',
    recipients: const ['mail@zenos.studio'],
    subject: 'Konfirmasi jadwal ulasan',
    preview: 'Apakah Anda tersedia Kamis pukul 14.00 WIB?',
    body:
        'Apakah Anda tersedia Kamis pukul 14.00 WIB? '
        'Kami ingin meninjau hasil revisi bersama tim.',
    receivedAt: DateTime(2026, 10, 6, 14, 5),
  ),
  MailMessage(
    id: 'mail-004',
    senderName: 'Resend',
    senderAddress: 'updates@resend.com',
    recipients: const ['ops@alte.codes'],
    subject: 'Monthly delivery report',
    preview: 'Your delivery report for September is ready.',
    body: 'Your delivery report for September is ready to review.',
    receivedAt: DateTime(2026, 10, 4, 9, 12),
  ),
];
