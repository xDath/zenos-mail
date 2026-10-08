# Zenos Mail Mobile Design System

## Product

Zenos Mail is a private Android mail client for a small set of owned domains, currently `zenos.studio` and `alte.codes`. It uses the existing Vercel backend and Resend account. The app should feel deliberate, personal, and operational: closer to a beautifully typeset desk tool than a generic consumer inbox.

Primary jobs:

1. Notice a new message immediately through native Android push.
2. Scan and search the complete retained mail archive across all owned domains or filter to one identity.
3. Read an email safely, inspect sender and recipient, then reply from the correct domain.
4. Compose mail quickly with an explicit From identity.
5. Review account, domain, notification, and security settings.

Initial screens:

- Inbox: unified list, domain filter, always-visible global search, unread emphasis, refresh state, compose action.
- Message detail: subject, sender, recipients, date, safe body view, attachment row, reply action.
- Compose: From identity selector, To, optional CC/BCC, subject, body, attachments, send action.
- Settings: account/security, domain status, sender identity defaults, notification state, sign out.
- Login: password entry for the existing Zenos session.

## Visual direction

Zenos Mail should feel like a complete, confident communication product: cool, branded, calm, and meticulously organized. It must look designed and operational at first glance, with a recognizable dark Zenos masthead, an obvious mailbox hierarchy, and a disciplined message list. Elegant here comes from structure, contrast, breathing room, and typography rather than extreme reduction or dense information.

Build a clear three zone composition: a dark branded header, a light mailbox workspace, and a persistent navigation dock. The inbox is one cohesive elevated panel with a simple toolbar and aligned rows, not loose text floating on a blank page. Use subtle borders, tonal surfaces, one status marker, and restrained elevation to communicate hierarchy. Remove secondary explanations and status labels when the same meaning is already visible. Avoid generic generated dashboard tropes: no decorative blobs, fake analytics, giant empty areas, motivational copy, sparkle icons, or arbitrary cards.

## Color

- App canvas: `#E9EDF1`
- Primary surface: `#FFFFFF`
- Raised surface: `#F7F9FA`
- Brand midnight: `#0B1116`
- Brand graphite: `#131C23`
- Primary ink: `#101820`
- Secondary ink: `#45525C`
- Muted ink: `#72808B`
- Hairline: `#D6DDE2`
- Brand mint: `#65F0B5`
- Brand teal: `#16A879`
- Teal wash: `#E7F8F1`
- Cool blue wash: `#EAF2FF`
- Danger: `#C44747`
- Danger wash: `#FFF0F0`

Use the dark masthead as the strongest branded surface. The mint accent is precise and sparse: unread indicators, selected domain, focus, and the compose action. Use restrained soft shadows under the inbox panel and navigation dock to establish depth. No gradients or glass effects.

## Typography

- Display and interface family: Instrument Sans.
- Functional metadata family: JetBrains Mono.
- Brand / screen title: 28px, weight 650, line height 36px, tracking -0.55px.
- Mailbox title: 23px, weight 650, line height 30px, tracking -0.25px.
- Message subject: 16px, weight 600, line height 22px.
- Sender: 15px, weight 600, line height 21px.
- Body preview: 14px, weight 400, line height 21px.
- Metadata: 12px, weight 500, line height 17px.
- Technical label: JetBrains Mono 9px, weight 600, uppercase, tracking 0.7px.

Use weight, alignment, and density to make scanning effortless. Keep subject, sender, destination, and time in fixed visual positions. Do not center mail content.

## Shape and spacing

- Base spacing unit: 4px.
- Screen horizontal padding: 20px; masthead content padding: 24px.
- Common vertical gaps: 8, 12, 16, 20, 24, 32px.
- Message row height: 120–132px; touch targets: at least 48px.
- Control radius: 14px.
- Inbox panel radius: 20px.
- Search field radius: 16px.
- Badge radius: 6px; use fully rounded pills only for mailbox identity filters.
- Separators: 1px hairlines with aligned insets.

The layout should feel composed and breathable while every field remains aligned. Show fewer messages at once instead of compressing rows. Use one main inbox panel rather than making every email a separate floating card.

## Mobile shell

- Edge-to-edge Android layout with safe-area padding.
- Dark brand masthead occupies roughly the top 210px. Its first row contains the supplied logo, `ZENOS MAIL` wordmark, and one refresh action. Never show a profile avatar or a verbose sync label.
- The masthead includes only `Kotak masuk`, a quiet unread count, and a substantial global search field. Remove explanatory text below search.
- The light workspace overlaps the dark masthead slightly and begins with a well-spaced identity switcher: `Semua`, `zenos.studio`, `alte.codes`.
- Below it, a single raised inbox panel contains a quiet toolbar with the result count and one filter/sort action, then a structured list with consistent columns and separators.
- Bottom navigation is a deliberate dock with Inbox, Terkirim, a visually dominant square compose action, and Pengaturan. Use brand midnight, mint, and white states rather than stock Material navigation styling.

### Global search

- Search is an always-visible, full-width field near the Inbox title, not an icon-only action.
- A single query searches sender name, sender address, recipient address, subject, plain text body, and normalized text extracted from HTML.
- Matching is case-insensitive substring search. The user never chooses a field before searching.
- Example: `Anda` matches `Anda Purnama` and body text containing `Andalusia`.
- The search result may highlight the matching fragment subtly, but should never recolor the entire row.
- History must be persisted by the Zenos backend when the Resend webhook arrives; do not imply that Resend itself is permanent storage.

## Components

### Inbox row

- A small unread dot occupies a stable left status column.
- Sender and time share the first aligned row.
- Subject uses the strongest text in the message block.
- One-line preview follows, then a quiet final line with the full destination address such as `hello@zenos.studio` or `inbox@alte.codes`. Avoid another uppercase label when the recipient can be phrased naturally as `ke hello@zenos.studio`.
- Optional paperclip state may sit beside the time. Remove decorative chevrons and redundant reply icons; do not fabricate contact avatars.
- Unread rows use a subtle cool blue or teal wash and stronger text. Read rows remain white.
- Search matching fragments can use a compact mint underline/highlight without turning the entire line bright.

### Buttons

- Primary: forest fill, warm-white label, 48px height.
- Secondary: transparent surface, one-pixel border, primary ink label.
- Text action: no container; forest label.
- Labels use clear sentence case except compact technical actions where uppercase mono is already established.

### Inputs

- Warm-white or transparent background with one-pixel border.
- Floating or top labels remain visible after entry.
- Focus border uses forest plus a subtle two-pixel focus ring.
- Compose body should feel like an open writing surface, not a form card stack.

### Status

- Use a small square or circular dot and a terse mono label.
- Green means active or verified; muted means neutral; red means failure.
- Never rely on color alone.

## Motion

- Navigation and selection: 160–200ms standard ease-out.
- Message open: subtle horizontal shared-axis transition, 220ms.
- Compose sheet/action: 240ms ease-out from bottom.
- Pull-to-refresh uses native Android behavior.
- Respect reduced motion. Avoid looping decorative animation.

## Flutter implementation constraints

- Dart and Flutter with Material 3 foundations, customized so the result does not resemble a stock template.
- Prefer native `NavigationBar`, `Scaffold`, text fields, sheets, and semantics, then theme them with these tokens.
- Use vector icons from Material Symbols; use the real Zenos logo asset where the product mark appears.
- Light theme first. Dark theme may follow after the initial flow works.
- Preserve Android back behavior, notification deep links, text scaling, TalkBack labels, and keyboard insets.
- Design at 390 × 844 logical pixels, while remaining responsive from compact phones through foldables.

## Content tone

Short, direct Indonesian UI copy. Examples: `Kotak masuk`, `Tulis`, `Dari`, `Kepada`, `Kirim`, `Balas`, `Semua domain`, `Belum ada email`. Avoid promotional phrases and filler prose inside the product.

## Non-negotiables

- Use only Instrument Sans and JetBrains Mono.
- Use only the defined palette.
- No gradients, glassmorphism, 3D effects, decorative blobs, fake analytics, or excessive shadows.
- Preserve the supplied Zenos logo exactly in every brand position. Do not replace it with initials, emoji, a generic mail icon, an invented SVG, or text alone.
- The revised Inbox draft should demonstrate an active global query `Anda` with results that prove matching across sender/subject/body, show complete destination addresses, remove the profile icon, and present the results as a cohesive, structured mailbox rather than loose rows on a blank page. Show at most three result rows and allow only two to two-and-a-half rows to be visible above the navigation dock.
