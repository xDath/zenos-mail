import 'package:flutter/material.dart';

import '../models/mail_message.dart';
import '../theme/zenos_theme.dart';

class MailShell extends StatefulWidget {
  const MailShell({super.key});

  @override
  State<MailShell> createState() => _MailShellState();
}

class _MailShellState extends State<MailShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          InboxScreen(),
          SentScreen(),
          ComposeScreen(),
          SettingsScreen(),
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
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _searchController = TextEditingController(text: 'Anda');
  String _query = 'Anda';
  String _domain = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMessages = demoInbox
        .where(
          (message) => message.belongsTo(_domain) && message.matches(_query),
        )
        .toList();
    final unread = demoInbox.where((message) => message.isUnread).length;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: ZenosColors.amber,
        backgroundColor: ZenosColors.raised,
        onRefresh: () async =>
            Future<void>.delayed(const Duration(milliseconds: 450)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _InboxHeader(
                unreadCount: unread,
                controller: _searchController,
                onQueryChanged: (value) => setState(() => _query = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                child: _DomainSelector(
                  selected: _domain,
                  onSelected: (domain) => setState(() => _domain = domain),
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
                      '${visibleMessages.length} email',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    const _SquareAction(
                      icon: Icons.swap_vert_rounded,
                      semanticLabel: 'Urutkan email',
                    ),
                  ],
                ),
              ),
            ),
            if (visibleMessages.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyInbox(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                sliver: SliverList.separated(
                  itemCount: visibleMessages.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => MailRow(
                    message: visibleMessages[index],
                    query: _query,
                    onTap: () => Navigator.of(context).push(
                      _PortalRoute(
                        builder: (_) => MessageDetailScreen(
                          message: visibleMessages[index],
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
  });

  final int unreadCount;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

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
              const SizedBox(width: 14),
              const Text(
                'ZENOS',
                style: TextStyle(
                  color: ZenosColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Text(
                '.',
                style: TextStyle(
                  color: ZenosColors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const _SquareAction(
                icon: Icons.refresh_rounded,
                semanticLabel: 'Segarkan kotak masuk',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Kotak masuk',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
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
                  ],
                ),
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
                        Expanded(
                          child: HighlightedText(
                            message.senderName,
                            query: query,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (message.hasAttachment) ...[
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 15,
                            color: ZenosColors.muted,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          _formatDate(message.receivedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                    Text(
                      'ke ${message.recipients.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ZenosColors.tealBright,
                      ),
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
    final now = DateTime(2026, 10, 8);
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

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.message});

  final MailMessage message;

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
                  const Spacer(),
                  const _SquareAction(
                    icon: Icons.archive_outlined,
                    semanticLabel: 'Arsipkan',
                  ),
                  const SizedBox(width: 10),
                  const _SquareAction(
                    icon: Icons.more_horiz_rounded,
                    semanticLabel: 'Tindakan lainnya',
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
                      message.subject,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 32),
                    _AddressBlock(message: message),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 30),
                    Text(
                      message.body,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (message.hasAttachment) ...[
                      const SizedBox(height: 34),
                      const _AttachmentTile(),
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
                      onPressed: () {},
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
                  const _SquareAction(
                    icon: Icons.forward_rounded,
                    semanticLabel: 'Teruskan',
                    size: 52,
                  ),
                ],
              ),
            ),
          ],
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
  const _AttachmentTile();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  'referensi-visual.pdf',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 3),
                Text(
                  '2,4 MB · PDF',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.download_rounded, color: ZenosColors.secondaryInk),
        ],
      ),
    );
  }
}

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  String _from = 'hello@zenos.studio';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _SectionHeader(index: '02', title: 'Tulis email'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dari', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    initialValue: _from,
                    decoration: const InputDecoration(),
                    dropdownColor: ZenosColors.raised,
                    items: const [
                      DropdownMenuItem(
                        value: 'hello@zenos.studio',
                        child: Text('hello@zenos.studio'),
                      ),
                      DropdownMenuItem(
                        value: 'inbox@alte.codes',
                        child: Text('inbox@alte.codes'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _from = value ?? _from),
                  ),
                  const SizedBox(height: 22),
                  const TextField(
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'Kepada'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Subjek'),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    minLines: 10,
                    maxLines: 18,
                    decoration: InputDecoration(
                      hintText: 'Tulis pesan…',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const _SquareAction(
                        icon: Icons.attach_file_rounded,
                        semanticLabel: 'Lampirkan berkas',
                        size: 52,
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: ZenosColors.amber,
                          foregroundColor: ZenosColors.ground,
                          minimumSize: const Size(128, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_upward_rounded, size: 19),
                        label: const Text('Kirim'),
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

class SentScreen extends StatelessWidget {
  const SentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = demoInbox.reversed.take(3).toList();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _SectionHeader(index: '01', title: 'Terkirim'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              itemCount: messages.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      messages[index].subject,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ke ${messages[index].recipients.first}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _SectionHeader(index: '03', title: 'Pengaturan'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              children: const [
                _SettingsLabel('DOMAIN'),
                _SettingsRow(
                  title: 'zenos.studio',
                  subtitle: 'Kirim dan terima aktif',
                  statusColor: ZenosColors.tealBright,
                ),
                _SettingsRow(
                  title: 'alte.codes',
                  subtitle: 'Kirim dan terima aktif',
                  statusColor: ZenosColors.tealBright,
                ),
                SizedBox(height: 30),
                _SettingsLabel('NOTIFIKASI'),
                _SettingsRow(
                  title: 'Email baru',
                  subtitle: 'Tampilkan push di Android',
                  trailing: Switch(value: true, onChanged: null),
                ),
                SizedBox(height: 30),
                _SettingsLabel('AKUN'),
                _SettingsRow(
                  title: 'Keluar dari perangkat ini',
                  subtitle: 'Sesi aplikasi akan dihapus',
                  trailing: Icon(
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
  const _SectionHeader({required this.index, required this.title});

  final String index;
  final String title;

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
          Text(
            '/ $index',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: ZenosColors.amber),
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
  });

  final String title;
  final String subtitle;
  final Color? statusColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
