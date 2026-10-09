import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mail_message.dart';
import '../models/sender_profile.dart';
import '../services/push_service.dart';
import '../services/sender_profile_store.dart';
import '../services/zenos_api.dart';
import '../theme/zenos_theme.dart';

class MailShell extends StatefulWidget {
  const MailShell({
    super.key,
    this.api,
    this.onLogout,
    this.useDemoData = false,
  });

  final ZenosApi? api;
  final VoidCallback? onLogout;
  final bool useDemoData;

  @override
  State<MailShell> createState() => _MailShellState();
}

class _MailShellState extends State<MailShell> {
  int _selectedIndex = 0;
  StreamSubscription<String>? _pushSubscription;
  bool _openingPush = false;
  final _profileStore = SenderProfileStore();
  List<SenderProfile> _senderProfiles = builtInSenderProfiles;

  @override
  void initState() {
    super.initState();
    _pushSubscription = PushService.instance.openedMessages.listen(
      _openPushMessage,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = PushService.instance.takePendingMessageId();
      if (id != null) _openPushMessage(id);
    });
    _loadSenderProfiles();
  }

  Future<void> _loadSenderProfiles() async {
    final profiles = await _profileStore.load();
    if (mounted) setState(() => _senderProfiles = profiles);
  }

  void _saveSenderProfiles(List<SenderProfile> profiles) {
    setState(() => _senderProfiles = profiles);
    unawaited(_profileStore.save(profiles).catchError((_) {}));
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openPushMessage(String id) async {
    if (_openingPush || widget.api == null || id.isEmpty) return;
    _openingPush = true;
    try {
      final message = await widget.api!.message(id);
      if (!mounted) return;
      setState(() => _selectedIndex = 0);
      await Navigator.of(context).push(
        _PortalRoute(
          builder: (_) => MessageDetailScreen(
            message: message,
            api: widget.api,
            senderProfiles: _senderProfiles,
          ),
        ),
      );
    } catch (_) {
      // Inbox remains usable if a stale notification references a removed email.
    } finally {
      _openingPush = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          InboxScreen(
            api: widget.api,
            useDemoData: widget.useDemoData,
            senderProfiles: _senderProfiles,
          ),
          SentScreen(api: widget.api, useDemoData: widget.useDemoData),
          ComposeScreen(api: widget.api, senderProfiles: _senderProfiles),
          SettingsScreen(
            api: widget.api,
            onLogout: widget.onLogout,
            senderProfiles: _senderProfiles,
            onSenderProfilesChanged: _saveSenderProfiles,
          ),
        ],
      ),
      bottomNavigationBar: _NavigationDock(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({
    super.key,
    this.api,
    this.useDemoData = false,
    this.senderProfiles = builtInSenderProfiles,
  });

  final ZenosApi? api;
  final bool useDemoData;
  final List<SenderProfile> senderProfiles;

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _domain = 'all';
  List<MailMessage> _messages = const [];
  bool _loading = true;
  String? _error;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final messages = widget.useDemoData || widget.api == null
          ? demoInbox
                .where(
                  (message) =>
                      message.belongsTo(_domain) && message.matches(_query),
                )
                .toList()
          : await widget.api!.messages(query: _query, domain: _domain);
      if (mounted) setState(() => _messages = messages);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Tidak dapat memuat email.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setQuery(String value) {
    setState(() => _query = value);
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 320), _load);
  }

  void _setDomain(String value) {
    setState(() => _domain = value);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final unread = _messages.where((message) => message.isUnread).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ZenosColors.amber,
        backgroundColor: ZenosColors.raised,
        onRefresh: () => _load(quiet: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _InboxHeader(
                unreadCount: unread,
                controller: _searchController,
                onQueryChanged: _setQuery,
                onClear: () {
                  _searchController.clear();
                  _setQuery('');
                },
                onRefresh: _load,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: _DomainSelector(
                  selected: _domain,
                  onSelected: _setDomain,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _query.trim().isEmpty
                            ? 'Email terbaru'
                            : 'Hasil untuk “${_query.trim()}”',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '${_messages.length} email',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (_loading && _messages.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null && _messages.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _InboxError(message: _error!, onRetry: _load),
              )
            else if (_messages.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyInbox(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                sliver: SliverList.separated(
                  itemCount: _messages.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => MailRow(
                    message: _messages[index],
                    query: _query,
                    onTap: () => Navigator.of(context).push(
                      _PortalRoute(
                        builder: (_) => MessageDetailScreen(
                          message: _messages[index],
                          api: widget.api,
                          senderProfiles: widget.senderProfiles,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InboxHeader extends StatelessWidget {
  const _InboxHeader({
    required this.unreadCount,
    required this.controller,
    required this.onQueryChanged,
    required this.onClear,
    required this.onRefresh,
  });

  final int unreadCount;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final Future<void> Function({bool quiet}) onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ZenosColors.secondaryGround,
        border: Border(bottom: BorderSide(color: ZenosColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: ZenosColors.ink,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset('assets/brand/zenos-logo.png'),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: ZenosColors.tealBright,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$unreadCount baru',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: 14),
              _SquareAction(
                icon: Icons.refresh_rounded,
                semanticLabel: 'Segarkan kotak masuk',
                onTap: () => onRefresh(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Cari semua email',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClear,
                      tooltip: 'Hapus pencarian',
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainSelector extends StatelessWidget {
  const _DomainSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const domains = [
      ('all', 'Semua'),
      ('zenos.studio', 'zenos.studio'),
      ('alte.codes', 'alte.codes'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final domain in domains) ...[
            _DomainButton(
              label: domain.$2,
              selected: selected == domain.$1,
              onTap: () => onSelected(domain.$1),
            ),
            if (domain != domains.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _DomainButton extends StatelessWidget {
  const _DomainButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? ZenosColors.ink : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? ZenosColors.ink : ZenosColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? ZenosColors.ground : ZenosColors.secondaryInk,
            ),
          ),
        ),
      ),
    );
  }
}

class MailRow extends StatelessWidget {
  const MailRow({
    super.key,
    required this.message,
    required this.query,
    required this.onTap,
  });

  final MailMessage message;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${message.senderName}, ${message.subject}',
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: message.isUnread
                        ? ZenosColors.amber
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: message.isUnread
                        ? null
                        : Border.all(color: ZenosColors.muted),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: HighlightedText(
                            message.senderName,
                            query: query,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '(${_compactEmail(message.senderAddress)})',
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ZenosColors.tealBright),
                        ),
                        const Spacer(),
                        if (message.hasAttachment) ...[
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 15,
                            color: ZenosColors.muted,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 9),
                    HighlightedText(
                      message.subject,
                      query: query,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 7),
                    HighlightedText(
                      message.preview,
                      query: query,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.recipients.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: ZenosColors.tealBright),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatDate(message.receivedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final now = DateTime.now();
    if (value.year == now.year &&
        value.month == now.month &&
        value.day == now.day) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day) {
      return 'Kemarin';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }
}

class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    super.key,
    required this.query,
    this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final needle = query.trim();
    if (needle.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final lowerText = text.toLowerCase();
    final lowerNeedle = needle.toLowerCase();
    final spans = <InlineSpan>[];
    var offset = 0;
    while (offset < text.length) {
      final match = lowerText.indexOf(lowerNeedle, offset);
      if (match < 0) {
        spans.add(TextSpan(text: text.substring(offset)));
        break;
      }
      if (match > offset) {
        spans.add(TextSpan(text: text.substring(offset, match)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match, match + needle.length),
          style: const TextStyle(
            color: ZenosColors.ink,
            decoration: TextDecoration.underline,
            decorationColor: ZenosColors.amber,
            decorationThickness: 2,
          ),
        ),
      );
      offset = match + needle.length;
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({
    super.key,
    required this.message,
    this.api,
    this.senderProfiles = builtInSenderProfiles,
  });

  final MailMessage message;
  final ZenosApi? api;
  final List<SenderProfile> senderProfiles;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  late MailMessage _message = widget.message;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.api != null && widget.message.id.isNotEmpty) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final message = await widget.api!.message(widget.message.id);
      await widget.api!.markRead(widget.message.id);
      if (mounted) setState(() => _message = message);
    } catch (_) {
      // The list payload remains readable when detail refresh fails.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: [
                  _SquareAction(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Kembali',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 34, height: 2, color: ZenosColors.amber),
                    const SizedBox(height: 26),
                    Text(
                      _message.subject,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 32),
                    _AddressBlock(message: _message),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 30),
                    if (_loading && _message.body.isEmpty)
                      const LinearProgressIndicator(minHeight: 2)
                    else
                      _EmailBody(message: _message),
                    if (_message.attachments.any(
                      (attachment) => !attachment.isInline,
                    )) ...[
                      const SizedBox(height: 34),
                      for (final attachment in _message.attachments.where(
                        (attachment) => !attachment.isInline,
                      ))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _AttachmentTile(attachment: attachment),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: ZenosColors.secondaryGround,
                border: Border(top: BorderSide(color: ZenosColors.hairline)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openComposer(forward: false),
                      style: FilledButton.styleFrom(
                        backgroundColor: ZenosColors.ink,
                        foregroundColor: ZenosColors.ground,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.reply_rounded),
                      label: const Text('Balas'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SquareAction(
                    icon: Icons.forward_rounded,
                    semanticLabel: 'Teruskan',
                    size: 52,
                    onTap: () => _openComposer(forward: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openComposer({required bool forward}) {
    final body = _message.body.isNotEmpty
        ? _message.body
        : _plainText(_message.html);
    final prefix = forward ? 'Fwd: ' : 'Re: ';
    final subject = _message.subject.startsWith(prefix)
        ? _message.subject
        : '$prefix${_message.subject}';
    final quoted = forward
        ? '\n\n--- Pesan diteruskan ---\nDari: ${_message.senderAddress}\nKepada: ${_message.recipients.join(', ')}\nSubjek: ${_message.subject}\n\n$body'
        : '\n\n--- Pesan sebelumnya ---\n$body';
    final initialFrom = _message.recipients.firstWhere(
      (address) => widget.senderProfiles.any(
        (profile) => profile.email.toLowerCase() == address.toLowerCase(),
      ),
      orElse: () => 'hello@zenos.studio',
    );
    Navigator.of(context).push(
      _PortalRoute(
        builder: (_) => Scaffold(
          body: ComposeScreen(
            api: widget.api,
            standalone: true,
            title: forward ? 'Teruskan' : 'Balas',
            initialFrom: initialFrom,
            initialTo: forward ? '' : _message.senderAddress,
            initialSubject: subject,
            initialBody: quoted,
            senderProfiles: widget.senderProfiles,
          ),
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.message});

  final MailMessage message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.senderName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          message.senderAddress,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'ke ${message.recipients.join(', ')}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ZenosColors.tealBright),
        ),
      ],
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment});

  final MailAttachment attachment;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: attachment.downloadUrl.isEmpty
          ? null
          : () => _launchExternal(attachment.downloadUrl),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ZenosColors.secondaryGround,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZenosColors.hairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: ZenosColors.amber),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.filename,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    attachment.downloadUrl.isEmpty
                        ? 'Lampiran pada email ini'
                        : 'Ketuk untuk membuka lampiran',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (attachment.downloadUrl.isNotEmpty)
              const Icon(Icons.open_in_new_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmailBody extends StatelessWidget {
  const _EmailBody({required this.message});

  final MailMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.html.isEmpty) {
      return SelectableText(
        message.body.isEmpty ? '(email kosong)' : message.body,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Theme(
            data: ThemeData.light(useMaterial3: true),
            child: HtmlWidget(
              _htmlWithInlineImages(message),
              onTapUrl: (url) async {
                await _launchExternal(url);
                return true;
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    super.key,
    this.api,
    this.standalone = false,
    this.title = 'Tulis email',
    this.initialFrom = 'hello@zenos.studio',
    this.initialTo = '',
    this.initialSubject = '',
    this.initialBody = '',
    this.senderProfiles = builtInSenderProfiles,
  });

  final ZenosApi? api;
  final bool standalone;
  final String title;
  final String initialFrom;
  final String initialTo;
  final String initialSubject;
  final String initialBody;
  final List<SenderProfile> senderProfiles;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  static const _manualSender = '__manual__';
  late String _senderChoice;
  late final TextEditingController _senderName;
  late final TextEditingController _manualFrom;
  late final TextEditingController _to;
  late final TextEditingController _subject;
  late final TextEditingController _body;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final selected = widget.senderProfiles.where(
      (profile) => profile.email == widget.initialFrom,
    );
    _senderChoice = selected.isEmpty ? _manualSender : widget.initialFrom;
    _senderName = TextEditingController(
      text: selected.isEmpty ? '' : selected.first.name,
    );
    _manualFrom = TextEditingController(
      text: selected.isEmpty ? widget.initialFrom : '',
    );
    _to = TextEditingController(text: widget.initialTo);
    _subject = TextEditingController(text: widget.initialSubject);
    _body = TextEditingController(text: widget.initialBody);
  }

  @override
  void didUpdateWidget(covariant ComposeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_senderChoice != _manualSender &&
        !widget.senderProfiles.any(
          (profile) => profile.email == _senderChoice,
        )) {
      _manualFrom.text = _senderChoice;
      _senderChoice = _manualSender;
    }
  }

  @override
  void dispose() {
    _senderName.dispose();
    _manualFrom.dispose();
    _to.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final from = _senderChoice == _manualSender
        ? _manualFrom.text.trim().toLowerCase()
        : _senderChoice;
    final senderName = _senderName.text.trim();
    final recipients = _to.text
        .split(RegExp(r'[,;\s]+'))
        .where((address) => address.trim().isNotEmpty)
        .toList();
    if (!isValidSenderEmail(from) ||
        senderName.isEmpty ||
        recipients.isEmpty ||
        _subject.text.trim().isEmpty ||
        _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi nama dan alamat pengirim, penerima, subjek, serta pesan.',
          ),
        ),
      );
      return;
    }
    if (widget.api == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode demo: email tidak dikirim.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.api!.send(
        from: from,
        senderName: senderName,
        to: recipients,
        subject: _subject.text.trim(),
        text: _body.text.trim(),
      );
      _to.clear();
      _subject.clear();
      _body.clear();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Email terkirim.')));
        if (widget.standalone) Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          widget.standalone
              ? _StandaloneComposeHeader(title: widget.title)
              : const _SectionHeader(title: 'Tulis email'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identitas pengirim',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _senderName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nama pengirim',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      '$_senderChoice-${widget.senderProfiles.length}',
                    ),
                    initialValue: _senderChoice,
                    decoration: const InputDecoration(
                      labelText: 'Alamat pengirim',
                    ),
                    dropdownColor: ZenosColors.raised,
                    items: [
                      for (final profile in widget.senderProfiles)
                        DropdownMenuItem(
                          value: profile.email,
                          child: Text(profile.email),
                        ),
                      const DropdownMenuItem(
                        value: _manualSender,
                        child: Text('Masukkan alamat lain…'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _senderChoice = value);
                      if (value != _manualSender) {
                        final profile = widget.senderProfiles.firstWhere(
                          (profile) => profile.email == value,
                        );
                        _senderName.text = profile.name;
                      }
                    },
                  ),
                  if (_senderChoice == _manualSender) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _manualFrom,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email pengirim manual',
                        hintText: 'nama@domain-terverifikasi.com',
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextField(
                    controller: _to,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Kepada'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Subjek'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _body,
                    minLines: 10,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      hintText: 'Tulis pesan…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        style: FilledButton.styleFrom(
                          backgroundColor: ZenosColors.amber,
                          foregroundColor: ZenosColors.ground,
                          minimumSize: const Size(128, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 19),
                        label: Text(_sending ? 'Mengirim' : 'Kirim'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SentScreen extends StatefulWidget {
  const SentScreen({super.key, this.api, this.useDemoData = false});

  final ZenosApi? api;
  final bool useDemoData;

  @override
  State<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends State<SentScreen> {
  List<MailMessage> _messages = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final messages = widget.useDemoData || widget.api == null
          ? demoInbox.reversed.take(3).toList()
          : await widget.api!.messages(direction: 'outbound');
      if (mounted) setState(() => _messages = messages);
    } catch (_) {
      if (mounted) setState(() => _messages = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _SectionHeader(
            title: 'Terkirim',
            action: _SquareAction(
              icon: Icons.refresh_rounded,
              semanticLabel: 'Segarkan email terkirim',
              onTap: _load,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _messages.isEmpty
                ? const _EmptyInbox()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      itemCount: _messages.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _messages[index].subject,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ke ${_messages[index].recipients.join(', ')}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.api,
    this.onLogout,
    this.senderProfiles = builtInSenderProfiles,
    this.onSenderProfilesChanged,
  });

  final ZenosApi? api;
  final VoidCallback? onLogout;
  final List<SenderProfile> senderProfiles;
  final ValueChanged<List<SenderProfile>>? onSenderProfilesChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _syncing = false;

  Future<void> _addSenderProfile() async {
    final name = TextEditingController();
    final email = TextEditingController();
    String? validationError;
    final profile = await showDialog<SenderProfile>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Profil email baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama pengirim'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Alamat email',
                  hintText: 'nama@domain.com',
                ),
              ),
              if (validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  validationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final normalizedEmail = email.text.trim().toLowerCase();
                if (name.text.trim().isEmpty ||
                    !isValidSenderEmail(normalizedEmail)) {
                  setDialogState(
                    () =>
                        validationError = 'Masukkan nama dan email yang valid.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  SenderProfile(name: name.text.trim(), email: normalizedEmail),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    if (profile == null || !mounted) return;
    if (widget.senderProfiles.any((item) => item.email == profile.email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat itu sudah ada di profil.')),
      );
      return;
    }
    widget.onSenderProfilesChanged?.call([...widget.senderProfiles, profile]);
  }

  void _removeSenderProfile(SenderProfile profile) {
    widget.onSenderProfilesChanged?.call(
      widget.senderProfiles
          .where((item) => item.email != profile.email)
          .toList(),
    );
  }

  Future<void> _logout() async {
    if (widget.api != null) {
      await PushService.instance.unregisterCurrentDevice(widget.api!);
    }
    await widget.api?.logout();
    widget.onLogout?.call();
  }

  Future<void> _syncArchive() async {
    if (_syncing || widget.api == null) return;
    setState(() => _syncing = true);
    try {
      final count = await widget.api!.syncArchive();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count email berhasil disinkronkan.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _SectionHeader(title: 'Pengaturan'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              children: [
                const _SettingsLabel('PROFIL PENGIRIM'),
                for (final profile in widget.senderProfiles)
                  _SettingsRow(
                    title: profile.name,
                    subtitle: profile.email,
                    statusColor: profile.isBuiltIn
                        ? ZenosColors.tealBright
                        : null,
                    trailing: profile.isBuiltIn
                        ? null
                        : IconButton(
                            onPressed: () => _removeSenderProfile(profile),
                            tooltip: 'Hapus profil',
                            icon: const Icon(Icons.close_rounded, size: 19),
                          ),
                  ),
                _SettingsRow(
                  title: 'Tambah profil email',
                  subtitle: 'Simpan nama dan alamat pengirim baru',
                  onTap: _addSenderProfile,
                  trailing: const Icon(
                    Icons.add_rounded,
                    color: ZenosColors.secondaryInk,
                  ),
                ),
                const SizedBox(height: 30),
                const _SettingsLabel('DOMAIN'),
                const _SettingsRow(
                  title: 'zenos.studio',
                  subtitle: 'Kirim dan terima aktif',
                  statusColor: ZenosColors.tealBright,
                ),
                const _SettingsRow(
                  title: 'alte.codes',
                  subtitle: 'Kirim dan terima aktif',
                  statusColor: ZenosColors.tealBright,
                ),
                const SizedBox(height: 30),
                const _SettingsLabel('NOTIFIKASI'),
                const _SettingsRow(
                  title: 'Email baru',
                  subtitle: 'Push Android aktif',
                  statusColor: ZenosColors.tealBright,
                ),
                const SizedBox(height: 30),
                const _SettingsLabel('ARSIP'),
                _SettingsRow(
                  title: 'Sinkronkan email lama',
                  subtitle: _syncing
                      ? 'Mengambil riwayat dari Resend…'
                      : 'Ambil hingga 100 email masuk terbaru',
                  onTap: _syncing ? null : _syncArchive,
                  trailing: _syncing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.sync_rounded,
                          color: ZenosColors.secondaryInk,
                        ),
                ),
                const SizedBox(height: 30),
                const _SettingsLabel('AKUN'),
                _SettingsRow(
                  title: 'Keluar dari perangkat ini',
                  subtitle: 'Sesi aplikasi akan dihapus',
                  onTap: _logout,
                  trailing: const Icon(
                    Icons.logout_rounded,
                    color: ZenosColors.secondaryInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: ZenosColors.secondaryGround,
        border: Border(bottom: BorderSide(color: ZenosColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.displaySmall),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class _StandaloneComposeHeader extends StatelessWidget {
  const _StandaloneComposeHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: const BoxDecoration(
        color: ZenosColors.secondaryGround,
        border: Border(bottom: BorderSide(color: ZenosColors.hairline)),
      ),
      child: Row(
        children: [
          _SquareAction(
            icon: Icons.arrow_back_rounded,
            semanticLabel: 'Kembali',
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ],
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: ZenosColors.amber,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.subtitle,
    this.statusColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color? statusColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 19),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ZenosColors.hairline)),
        ),
        child: Row(
          children: [
            if (statusColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _NavigationDock extends StatelessWidget {
  const _NavigationDock({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.inbox_outlined, Icons.inbox_rounded, 'Inbox'),
      (Icons.send_outlined, Icons.send_rounded, 'Terkirim'),
      (Icons.edit_outlined, Icons.edit_rounded, 'Tulis'),
      (Icons.tune_outlined, Icons.tune_rounded, 'Pengaturan'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: ZenosColors.secondaryGround,
        border: Border(top: BorderSide(color: ZenosColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _NavigationItem(
                    icon: selectedIndex == index
                        ? items[index].$2
                        : items[index].$1,
                    label: items[index].$3,
                    selected: selectedIndex == index,
                    emphasized: index == 2,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.emphasized,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool emphasized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? ZenosColors.ink : ZenosColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: emphasized ? 42 : 34,
              height: emphasized ? 36 : 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: emphasized
                    ? (selected ? ZenosColors.amber : ZenosColors.raised)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: emphasized && selected ? ZenosColors.ground : foreground,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ZenosColors.hairline),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 20, color: ZenosColors.secondaryInk),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 2, color: ZenosColors.tealBright),
            const SizedBox(height: 20),
            Text(
              'Tidak ada email',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata lain atau lihat semua alamat.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool quiet}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: ZenosColors.muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => onRetry(),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _compactEmail(String value) {
  final parts = value.trim().split('@');
  if (parts.length != 2 || value.length <= 32) return value;
  final local = parts.first;
  final domain = parts.last;
  final available = 32 - domain.length - 2;
  final keep = available.clamp(3, 10);
  final compactLocal = local.length <= keep
      ? local
      : '${local.substring(0, keep)}…';
  return '$compactLocal@$domain';
}

String _htmlWithInlineImages(MailMessage message) {
  var html = message.html;
  for (final attachment in message.attachments) {
    if (attachment.contentId.isEmpty || attachment.downloadUrl.isEmpty) {
      continue;
    }
    final contentId = attachment.contentId.replaceAll(RegExp(r'[<>]'), '');
    html = html.replaceAll(
      RegExp('cid:${RegExp.escape(contentId)}', caseSensitive: false),
      attachment.downloadUrl,
    );
  }
  return html;
}

Future<void> _launchExternal(String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || !{'http', 'https', 'mailto'}.contains(uri.scheme)) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _plainText(String html) {
  return html
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(
        RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
        ' ',
      )
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _PortalRoute<T> extends PageRouteBuilder<T> {
  _PortalRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}
